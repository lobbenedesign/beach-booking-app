import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
import '../../widgets/map/map_element_renderer.dart';
import '../../widgets/map/beach_background_layer.dart';
import '../../utils/undo_redo_manager.dart';
import '../../widgets/admin/beach_wizard_dialog.dart';
import '../../widgets/admin/map_editor_toolbar.dart';
import '../../widgets/admin/map_editor_palette.dart';
import '../../widgets/admin/grid_generator_dialog.dart';
import '../../widgets/admin/bulk_rename_dialog.dart';
import '../../widgets/admin/zone_editor_dialog.dart';
import '../../widgets/admin/admin_scaffold.dart';

// Terrain/area elements are background layers: they're expected to sit under
// (and overlap) everything else, so they're excluded from both the overlap
// check on drag and the align/distribute selection math.
const Set<MapElementType> _kBackgroundLayerTypes = {
  MapElementType.sand,
  MapElementType.sea,
  MapElementType.rock,
  MapElementType.walkway,
  MapElementType.grass,
  MapElementType.zone,
};

class MapEditorScreen extends StatefulWidget {
  const MapEditorScreen({super.key});

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> with TickerProviderStateMixin {
  MapElement? _selectedElement;
  final Set<String> _selectedElementIds = {};
  late UndoRedoManager _undoRedoManager;
  late AnimationController _waveAnimationController;

  // Rectangle drag-select (in canvas-local pixel coordinates).
  Offset? _selectionRectStart;
  Offset? _selectionRectCurrent;

  // Snapshot of the element's state taken at the start of a continuous
  // interaction (slider drag, label edit) so the whole interaction becomes
  // one undoable step instead of one step per intermediate value.
  MapElement? _interactionSnapshot;
  final FocusNode _labelFocusNode = FocusNode();
  String? _labelSnapshotValue;

  @override
  void initState() {
    super.initState();
    _undoRedoManager = UndoRedoManager();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _labelFocusNode.addListener(_onLabelFocusChange);
  }

  @override
  void dispose() {
    _labelFocusNode.removeListener(_onLabelFocusChange);
    _labelFocusNode.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  bool get _isMultiSelect => _selectedElementIds.length > 1;

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final elements = dataService.mapElements;

    return AdminScaffold(
      title: 'Editor Mappa',
      selectedIndex: 2,
      child: Column(
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: MapEditorToolbar(
              canUndo: _undoRedoManager.canUndo,
              canRedo: _undoRedoManager.canRedo,
              selectedElement: _selectedElement,
              onUndo: _performUndo,
              onRedo: _performRedo,
              onGridGenerator: () => _showGridGeneratorDialog(context),
              onBulkRename: () => _showBulkRenameDialog(context),
              onBeachWizard: () => _showBeachWizard(context),
              onManageZones: () => _showZoneEditor(context),
              onDuplicateSelected: _duplicateSelected,
              onBackgroundImage: () => _showBackgroundImageDialog(context),
              onSave: _saveMap,
              onHelp: () => _showHelpDialog(context),
            ),
          ),
          if (_isMultiSelect) _buildMultiSelectToolbar(dataService),
          Expanded(
            child: Row(
              children: [
                MapEditorPalette(
                  onElementDragged: (type) {},
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    // SizedBox.expand forces tight constraints on the
                    // LayoutBuilder below: Row's default CrossAxisAlignment
                    // (center) only ever gives its children LOOSE
                    // cross-axis (height) constraints, and a Stack made up
                    // entirely of Positioned children collapses to zero
                    // size under loose constraints — without this, the
                    // whole canvas silently renders at zero height.
                    child: SizedBox.expand(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return DragTarget<Object>(
                            onAcceptWithDetails: (details) {
                              final canvasBox = context.findRenderObject() as RenderBox;
                              final localOffset = canvasBox.globalToLocal(details.offset);

                              double relativeX = localOffset.dx / constraints.maxWidth;
                              double relativeY = localOffset.dy / constraints.maxHeight;

                              relativeX = relativeX.clamp(0.0, 1.0);
                              relativeY = relativeY.clamp(0.0, 1.0);

                              if (details.data is MapElementType) {
                                _addNewElement(details.data as MapElementType, relativeX, relativeY);
                              } else if (details.data is MapElement) {
                                _moveElement(
                                    details.data as MapElement, relativeX, relativeY, dataService);
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              final hasCustomBg = dataService.beachBackgroundImage != null;
                              final visibleElements = elements
                                  .where((e) => !hasCustomBg ||
                                      (e.type != MapElementType.sand && e.type != MapElementType.sea))
                                  .toList();
                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onPanStart: (details) {
                                  setState(() {
                                    _selectionRectStart = details.localPosition;
                                    _selectionRectCurrent = details.localPosition;
                                  });
                                },
                                onPanUpdate: (details) {
                                  if (_selectionRectStart == null) return;
                                  setState(() => _selectionRectCurrent = details.localPosition);
                                },
                                onPanEnd: (details) => _finishRectSelect(constraints, elements),
                                child: Stack(
                                  children: [
                                    BeachBackgroundLayer(
                                        backgroundImageDataUrl: dataService.beachBackgroundImage),
                                    ...visibleElements
                                        .map((e) => _buildMapElementWidget(e, constraints, dataService)),
                                    if (_selectionRectStart != null && _selectionRectCurrent != null)
                                      _buildSelectionRectOverlay(),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_selectedElement != null && !_isMultiSelect)
                  Container(
                    width: 320,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildPropertiesPanel(dataService),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRectOverlay() {
    final rect = Rect.fromPoints(_selectionRectStart!, _selectionRectCurrent!);
    return Positioned.fromRect(
      rect: rect,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.12),
          border: Border.all(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }

  void _finishRectSelect(BoxConstraints constraints, List<MapElement> elements) {
    final start = _selectionRectStart;
    final current = _selectionRectCurrent;
    setState(() {
      _selectionRectStart = null;
      _selectionRectCurrent = null;
    });
    if (start == null || current == null) return;
    final pixelRect = Rect.fromPoints(start, current);
    if (pixelRect.width < 4 || pixelRect.height < 4) return; // treat as a click, not a drag

    final relRect = Rect.fromLTRB(
      pixelRect.left / constraints.maxWidth,
      pixelRect.top / constraints.maxHeight,
      pixelRect.right / constraints.maxWidth,
      pixelRect.bottom / constraints.maxHeight,
    );

    final matched = elements
        .where((e) => !_kBackgroundLayerTypes.contains(e.type))
        .where((e) => Rect.fromLTWH(e.x, e.y, e.width * e.scaleX, e.height * e.scaleY).overlaps(relRect))
        .map((e) => e.id)
        .toSet();

    if (matched.isEmpty) return;
    setState(() {
      _selectedElementIds
        ..clear()
        ..addAll(matched);
      _selectedElement =
          _selectedElementIds.length == 1 ? elements.firstWhere((e) => e.id == _selectedElementIds.first) : null;
    });
  }

  bool get _multiSelectModifierDown =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isShiftPressed;

  void _onLabelFocusChange() {
    if (_labelFocusNode.hasFocus) {
      _labelSnapshotValue = _selectedElement?.label;
    } else {
      final el = _selectedElement;
      if (el != null && _labelSnapshotValue != null && _labelSnapshotValue != el.label) {
        final before = el.clone()..label = _labelSnapshotValue;
        _undoRedoManager.recordAction(MapAction(type: ActionType.update, element: el.clone(), previousState: before));
      }
      _labelSnapshotValue = null;
    }
  }

  // --- Multi-select toolbar (align / distribute / batch actions) ---

  Widget _buildMultiSelectToolbar(MockDataService dataService) {
    return Container(
      color: Colors.blueGrey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('${_selectedElementIds.length} elementi selezionati',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          _toolbarIcon(Icons.align_horizontal_left, 'Allinea a sinistra', () => _alignSelected('left', dataService)),
          _toolbarIcon(Icons.align_horizontal_center, 'Allinea al centro (orizz.)',
              () => _alignSelected('centerH', dataService)),
          _toolbarIcon(Icons.align_horizontal_right, 'Allinea a destra', () => _alignSelected('right', dataService)),
          const SizedBox(width: 8),
          _toolbarIcon(Icons.align_vertical_top, 'Allinea in alto', () => _alignSelected('top', dataService)),
          _toolbarIcon(Icons.align_vertical_center, 'Allinea al centro (vert.)',
              () => _alignSelected('centerV', dataService)),
          _toolbarIcon(Icons.align_vertical_bottom, 'Allinea in basso', () => _alignSelected('bottom', dataService)),
          const SizedBox(width: 8),
          _toolbarIcon(Icons.view_column_outlined, 'Distribuisci orizzontalmente',
              () => _distributeSelected(Axis.horizontal, dataService)),
          _toolbarIcon(Icons.table_rows_outlined, 'Distribuisci verticalmente',
              () => _distributeSelected(Axis.vertical, dataService)),
          const Spacer(),
          _toolbarIcon(Icons.copy, 'Duplica selezione', () => _duplicateSelectedBatch(dataService)),
          _toolbarIcon(Icons.delete_outline, 'Elimina selezione', () => _confirmDeleteBatch(dataService),
              color: Colors.red),
          _toolbarIcon(Icons.close, 'Deseleziona', () {
            setState(() {
              _selectedElementIds.clear();
              _selectedElement = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String tooltip, VoidCallback onPressed, {Color? color}) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }

  List<MapElement> _selectedElementsList(MockDataService dataService) => dataService.mapElements
      .where((e) => _selectedElementIds.contains(e.id))
      .toList();

  void _alignSelected(String mode, MockDataService dataService) {
    final els = _selectedElementsList(dataService);
    if (els.length < 2) return;
    double target;
    switch (mode) {
      case 'left':
        target = els.map((e) => e.x).reduce(math.min);
        break;
      case 'right':
        target = els.map((e) => e.x + e.width * e.scaleX).reduce(math.max);
        break;
      case 'top':
        target = els.map((e) => e.y).reduce(math.min);
        break;
      case 'bottom':
        target = els.map((e) => e.y + e.height * e.scaleY).reduce(math.max);
        break;
      case 'centerH':
        target = els.map((e) => e.x + e.width * e.scaleX / 2).reduce((a, b) => a + b) / els.length;
        break;
      case 'centerV':
        target = els.map((e) => e.y + e.height * e.scaleY / 2).reduce((a, b) => a + b) / els.length;
        break;
      default:
        return;
    }

    final subActions = <MapAction>[];
    for (final e in els) {
      final before = e.clone();
      switch (mode) {
        case 'left':
          e.x = target;
          break;
        case 'right':
          e.x = target - e.width * e.scaleX;
          break;
        case 'top':
          e.y = target;
          break;
        case 'bottom':
          e.y = target - e.height * e.scaleY;
          break;
        case 'centerH':
          e.x = target - e.width * e.scaleX / 2;
          break;
        case 'centerV':
          e.y = target - e.height * e.scaleY / 2;
          break;
      }
      e.x = e.x.clamp(0.0, 1.0);
      e.y = e.y.clamp(0.0, 1.0);
      dataService.updateMapElement(e);
      subActions.add(MapAction(type: ActionType.update, element: e.clone(), previousState: before));
    }
    _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
    setState(() {});
  }

  void _distributeSelected(Axis axis, MockDataService dataService) {
    final els = _selectedElementsList(dataService);
    if (els.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno 3 elementi per distribuire')),
      );
      return;
    }
    els.sort((a, b) => axis == Axis.horizontal ? a.x.compareTo(b.x) : a.y.compareTo(b.y));

    double centerOf(MapElement e) => axis == Axis.horizontal
        ? e.x + e.width * e.scaleX / 2
        : e.y + e.height * e.scaleY / 2;

    final startCenter = centerOf(els.first);
    final endCenter = centerOf(els.last);
    final step = (endCenter - startCenter) / (els.length - 1);

    final subActions = <MapAction>[];
    for (var i = 1; i < els.length - 1; i++) {
      final e = els[i];
      final before = e.clone();
      final center = startCenter + step * i;
      if (axis == Axis.horizontal) {
        e.x = (center - e.width * e.scaleX / 2).clamp(0.0, 1.0);
      } else {
        e.y = (center - e.height * e.scaleY / 2).clamp(0.0, 1.0);
      }
      dataService.updateMapElement(e);
      subActions.add(MapAction(type: ActionType.update, element: e.clone(), previousState: before));
    }
    if (subActions.isNotEmpty) {
      _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
    }
    setState(() {});
  }

  void _duplicateSelectedBatch(MockDataService dataService) {
    final els = _selectedElementsList(dataService);
    if (els.isEmpty) return;
    final subActions = <MapAction>[];
    final newIds = <String>{};
    for (final e in els) {
      final copy = MapElement(
        id: const Uuid().v4(),
        type: e.type,
        x: (e.x + 0.03).clamp(0.0, 1.0 - e.width),
        y: (e.y + 0.03).clamp(0.0, 1.0 - e.height),
        width: e.width,
        height: e.height,
        color: e.color,
        label: e.label,
        rotation: e.rotation,
        scaleX: e.scaleX,
        scaleY: e.scaleY,
        flipHorizontal: e.flipHorizontal,
        flipVertical: e.flipVertical,
        row: e.row,
        number: e.number == null ? null : e.number! + 1,
        zoneId: e.zoneId,
        iconImage: e.iconImage,
      );
      dataService.addMapElement(copy);
      subActions.add(MapAction(type: ActionType.add, element: copy.clone()));
      newIds.add(copy.id);
    }
    _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
    setState(() {
      _selectedElementIds
        ..clear()
        ..addAll(newIds);
      _selectedElement =
          newIds.length == 1 ? dataService.mapElements.firstWhere((e) => e.id == newIds.first) : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${els.length} elementi duplicati')),
    );
  }

  void _confirmDeleteBatch(MockDataService dataService) {
    final els = _selectedElementsList(dataService);
    if (els.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Eliminare ${els.length} elementi selezionati? L\'azione non è reversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final subActions = <MapAction>[];
              for (final e in els) {
                dataService.removeMapElement(e.id);
                subActions.add(MapAction(type: ActionType.remove, element: e.clone()));
              }
              _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
              Navigator.pop(context);
              setState(() {
                _selectedElementIds.clear();
                _selectedElement = null;
              });
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  // --- Properties panel (single selection) ---

  Widget _buildPropertiesPanel(MockDataService dataService) {
    final element = _selectedElement!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proprietà: ${element.type.name}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Divider(),

        // Custom photo override
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: element.iconImage != null
                  ? Image.memory(base64Decode(element.iconImage!.split(',').last), fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _uploadElementIcon(dataService, element),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Foto elemento', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                  ),
                  if (element.iconImage != null)
                    TextButton.icon(
                      onPressed: () => _removeElementIcon(dataService, element),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red, padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Rimuovi', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        TextFormField(
          key: ValueKey(element.id),
          focusNode: _labelFocusNode,
          initialValue: element.label,
          decoration: const InputDecoration(labelText: 'Etichetta'),
          onChanged: (val) {
            setState(() {
              element.label = val;
              dataService.updateMapElement(element);
            });
          },
        ),
        const SizedBox(height: 24),

        Text('Rotazione: ${element.rotation}°', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: element.rotation.toDouble(),
          min: 0,
          max: 360,
          divisions: 72,
          label: '${element.rotation}°',
          onChangeStart: (_) => _interactionSnapshot = element.clone(),
          onChanged: (val) {
            setState(() {
              element.rotation = val.toInt();
              dataService.updateMapElement(element);
            });
          },
          onChangeEnd: (_) => _commitInteraction(element),
        ),
        const SizedBox(height: 16),

        Text('Scala X: ${element.scaleX.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: element.scaleX,
          min: 0.5,
          max: 3.0,
          divisions: 50,
          label: '${element.scaleX.toStringAsFixed(2)}x',
          onChangeStart: (_) => _interactionSnapshot = element.clone(),
          onChanged: (val) {
            setState(() {
              element.scaleX = val;
              dataService.updateMapElement(element);
            });
          },
          onChangeEnd: (_) => _commitInteraction(element),
        ),
        const SizedBox(height: 16),

        Text('Scala Y: ${element.scaleY.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: element.scaleY,
          min: 0.5,
          max: 3.0,
          divisions: 50,
          label: '${element.scaleY.toStringAsFixed(2)}x',
          onChangeStart: (_) => _interactionSnapshot = element.clone(),
          onChanged: (val) {
            setState(() {
              element.scaleY = val;
              dataService.updateMapElement(element);
            });
          },
          onChangeEnd: (_) => _commitInteraction(element),
        ),
        const SizedBox(height: 16),

        Text('Larghezza: ${(element.width * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: element.width.clamp(0.01, 0.5),
          min: 0.01,
          max: 0.5,
          divisions: 98,
          label: '${(element.width * 100).toStringAsFixed(1)}%',
          onChangeStart: (_) => _interactionSnapshot = element.clone(),
          onChanged: (val) {
            setState(() {
              element.width = val;
              dataService.updateMapElement(element);
            });
          },
          onChangeEnd: (_) => _commitInteraction(element),
        ),
        const SizedBox(height: 16),

        Text('Altezza: ${(element.height * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: element.height.clamp(0.01, 0.5),
          min: 0.01,
          max: 0.5,
          divisions: 98,
          label: '${(element.height * 100).toStringAsFixed(1)}%',
          onChangeStart: (_) => _interactionSnapshot = element.clone(),
          onChanged: (val) {
            setState(() {
              element.height = val;
              dataService.updateMapElement(element);
            });
          },
          onChangeEnd: (_) => _commitInteraction(element),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Flip H', style: TextStyle(fontSize: 12)),
                value: element.flipHorizontal,
                onChanged: (val) {
                  final before = element.clone();
                  setState(() {
                    element.flipHorizontal = val ?? false;
                    dataService.updateMapElement(element);
                  });
                  _undoRedoManager.recordAction(
                      MapAction(type: ActionType.update, element: element.clone(), previousState: before));
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Flip V', style: TextStyle(fontSize: 12)),
                value: element.flipVertical,
                onChanged: (val) {
                  final before = element.clone();
                  setState(() {
                    element.flipVertical = val ?? false;
                    dataService.updateMapElement(element);
                  });
                  _undoRedoManager.recordAction(
                      MapAction(type: ActionType.update, element: element.clone(), previousState: before));
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final before = element.clone();
              setState(() {
                element.rotation = 0;
                element.scaleX = 1.0;
                element.scaleY = 1.0;
                element.flipHorizontal = false;
                element.flipVertical = false;
                dataService.updateMapElement(element);
              });
              _undoRedoManager.recordAction(
                  MapAction(type: ActionType.update, element: element.clone(), previousState: before));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Trasformazioni'),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmDeleteSelected(dataService),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Elimina'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  /// Commits the diff between [_interactionSnapshot] (captured at
  /// onChangeStart) and the element's current state as one undo step,
  /// so dragging a slider records a single action instead of dozens.
  void _commitInteraction(MapElement element) {
    final before = _interactionSnapshot;
    _interactionSnapshot = null;
    if (before == null) return;
    _undoRedoManager
        .recordAction(MapAction(type: ActionType.update, element: element.clone(), previousState: before));
  }

  Future<void> _uploadElementIcon(MockDataService dataService, MapElement element) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    final name = result?.files.single.name ?? '';
    if (bytes == null) return;
    final ext = name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    final before = element.clone();
    setState(() {
      element.iconImage = 'data:image/$ext;base64,${base64Encode(bytes)}';
      dataService.updateMapElement(element);
    });
    _undoRedoManager
        .recordAction(MapAction(type: ActionType.update, element: element.clone(), previousState: before));
  }

  void _removeElementIcon(MockDataService dataService, MapElement element) {
    final before = element.clone();
    setState(() {
      element.iconImage = null;
      dataService.updateMapElement(element);
    });
    _undoRedoManager
        .recordAction(MapAction(type: ActionType.update, element: element.clone(), previousState: before));
  }

  Widget _buildMapElementWidget(MapElement element, BoxConstraints constraints, MockDataService dataService) {
    final isSelected = _selectedElementIds.contains(element.id);

    final scaledWidth = element.width * constraints.maxWidth * element.scaleX;
    final scaledHeight = element.height * constraints.maxHeight * element.scaleY;

    return Positioned(
      left: element.x * constraints.maxWidth,
      top: element.y * constraints.maxHeight,
      child: SizedBox(
        width: element.width * constraints.maxWidth,
        height: element.height * constraints.maxHeight,
        child: Draggable<MapElement>(
          data: element,
          feedback: Opacity(
            opacity: 0.7,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: scaledWidth,
                height: scaledHeight,
                child: _buildTransformedElement(element),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildTransformedElement(element),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_multiSelectModifierDown) {
                  if (_selectedElementIds.contains(element.id)) {
                    _selectedElementIds.remove(element.id);
                  } else {
                    _selectedElementIds.add(element.id);
                  }
                  _selectedElement = _selectedElementIds.length == 1
                      ? dataService.mapElements.firstWhere((e) => e.id == _selectedElementIds.first)
                      : null;
                } else {
                  _selectedElementIds
                    ..clear()
                    ..add(element.id);
                  _selectedElement = element;
                }
              });
            },
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)
                      ],
                    )
                  : null,
              child: _buildTransformedElement(element),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransformedElement(MapElement element) {
    Widget visual = _buildElementVisual(element);

    if (element.scaleX != 1.0 || element.scaleY != 1.0) {
      visual = Transform.scale(
        scaleX: element.scaleX,
        scaleY: element.scaleY,
        child: visual,
      );
    }

    if (element.flipHorizontal || element.flipVertical) {
      visual = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(
            element.flipHorizontal ? -1.0 : 1.0,
            element.flipVertical ? -1.0 : 1.0,
          ),
        child: visual,
      );
    }

    if (element.rotation != 0) {
      visual = Transform.rotate(
        angle: element.rotation * (3.14159 / 180),
        child: visual,
      );
    }

    return visual;
  }

  Widget _buildElementVisual(MapElement element) {
    if (element.type == MapElementType.sea) {
      return AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) => mapElementVisual(
          element,
          waveAnimationValue: _waveAnimationController.value,
        ),
      );
    }
    return mapElementVisual(element);
  }

  void _addNewElement(MapElementType type, double x, double y) {
    final dataService = Provider.of<MockDataService>(context, listen: false);

    final newElement = MapElement(
      id: const Uuid().v4(),
      type: type,
      x: x,
      y: y,
      width: 0.05,
      height: 0.05,
    );

    dataService.addMapElement(newElement);
    _undoRedoManager.recordAction(MapAction(
      type: ActionType.add,
      element: newElement.clone(),
    ));
  }

  /// Bounding-box overlap test against every other non-background-layer
  /// element, using a small inset so adjacent (touching but not overlapping)
  /// placements from the grid/wizard generators aren't rejected by rounding.
  bool _wouldOverlap(MapElement moving, double newX, double newY, MockDataService dataService) {
    if (_kBackgroundLayerTypes.contains(moving.type)) return false;

    final movingW = moving.width * moving.scaleX;
    final movingH = moving.height * moving.scaleY;
    final insetX = movingW * 0.12;
    final insetY = movingH * 0.12;
    final movingRect =
        Rect.fromLTWH(newX + insetX, newY + insetY, movingW - insetX * 2, movingH - insetY * 2);

    for (final other in dataService.mapElements) {
      if (other.id == moving.id) continue;
      if (_kBackgroundLayerTypes.contains(other.type)) continue;
      final otherW = other.width * other.scaleX;
      final otherH = other.height * other.scaleY;
      final oInsetX = otherW * 0.12;
      final oInsetY = otherH * 0.12;
      final otherRect =
          Rect.fromLTWH(other.x + oInsetX, other.y + oInsetY, otherW - oInsetX * 2, otherH - oInsetY * 2);
      if (movingRect.overlaps(otherRect)) return true;
    }
    return false;
  }

  void _moveElement(MapElement element, double centerX, double centerY, MockDataService dataService) {
    final effectiveWidth = element.width * element.scaleX;
    final effectiveHeight = element.height * element.scaleY;

    double newX = centerX - (element.width / 2);
    double newY = centerY - (element.height / 2);
    newX = newX.clamp(0.0, (1.0 - effectiveWidth).clamp(0.0, 1.0));
    newY = newY.clamp(0.0, (1.0 - effectiveHeight).clamp(0.0, 1.0));

    if (_wouldOverlap(element, newX, newY, dataService)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione occupata: sposta l\'elemento su uno spazio libero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final before = element.clone();
    element.x = newX;
    element.y = newY;
    dataService.updateMapElement(element);
    _undoRedoManager
        .recordAction(MapAction(type: ActionType.update, element: element.clone(), previousState: before));
  }

  void _confirmDeleteSelected(MockDataService dataService) {
    final element = _selectedElement;
    if (element == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text(
            'Eliminare questo ${element.label ?? element.type.name}? L\'azione non è reversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              dataService.removeMapElement(element.id);
              _undoRedoManager.recordAction(MapAction(type: ActionType.remove, element: element.clone()));
              Navigator.pop(context);
              setState(() {
                _selectedElement = null;
                _selectedElementIds.remove(element.id);
              });
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _showZoneEditor(BuildContext context) {
    showDialog(context: context, builder: (context) => const ZoneEditorDialog());
  }

  void _duplicateSelected() {
    final el = _selectedElement;
    if (el == null) return;
    final dataService = Provider.of<MockDataService>(context, listen: false);

    final copy = MapElement(
      id: const Uuid().v4(),
      type: el.type,
      x: (el.x + 0.03).clamp(0.0, 1.0 - el.width),
      y: (el.y + 0.03).clamp(0.0, 1.0 - el.height),
      width: el.width,
      height: el.height,
      color: el.color,
      label: el.label,
      rotation: el.rotation,
      scaleX: el.scaleX,
      scaleY: el.scaleY,
      flipHorizontal: el.flipHorizontal,
      flipVertical: el.flipVertical,
      row: el.row,
      number: el.number == null ? null : el.number! + 1,
      zoneId: el.zoneId,
      iconImage: el.iconImage,
    );

    dataService.addMapElement(copy);
    _undoRedoManager.recordAction(MapAction(type: ActionType.add, element: copy.clone()));
    setState(() {
      _selectedElement = copy;
      _selectedElementIds
        ..clear()
        ..add(copy.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Elemento duplicato')),
    );
  }

  void _showBackgroundImageDialog(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Sfondo Spiaggia Personalizzato'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Carica una foto/planimetria (PNG o JPG) da usare come sfondo al posto di sabbia/mare disegnati. Verrà mostrata nell\'editor, nella dashboard gestore e nella mappa prenotazione cliente.'),
                const SizedBox(height: 16),
                if (dataService.beachBackgroundImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(dataService.beachBackgroundImage!.split(',').last),
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['png', 'jpg', 'jpeg'],
                          withData: true,
                        );
                        final bytes = result?.files.single.bytes;
                        final name = result?.files.single.name ?? '';
                        if (bytes == null) return;
                        final ext = name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
                        final dataUrl = 'data:image/$ext;base64,${base64Encode(bytes)}';
                        dataService.setBeachBackgroundImage(dataUrl);
                        setLocal(() {});
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Carica immagine'),
                    ),
                    if (dataService.beachBackgroundImage != null) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          dataService.setBeachBackgroundImage(null);
                          setLocal(() {});
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Rimuovi'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
          ],
        ),
      ),
    );
  }

  void _saveMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mappa salvata!')),
    );
  }

  void _applyUndoAction(MapAction action, MockDataService dataService) {
    switch (action.type) {
      case ActionType.add:
        if (action.element != null) dataService.removeMapElement(action.element!.id);
        break;
      case ActionType.remove:
        if (action.element != null) dataService.addMapElement(action.element!.clone());
        break;
      case ActionType.update:
        if (action.previousState != null) dataService.updateMapElement(action.previousState!.clone());
        break;
      case ActionType.batch:
        for (final sub in (action.batch ?? const <MapAction>[]).reversed) {
          _applyUndoAction(sub, dataService);
        }
        break;
    }
  }

  void _applyRedoAction(MapAction action, MockDataService dataService) {
    switch (action.type) {
      case ActionType.add:
        if (action.element != null) dataService.addMapElement(action.element!.clone());
        break;
      case ActionType.remove:
        if (action.element != null) dataService.removeMapElement(action.element!.id);
        break;
      case ActionType.update:
        if (action.element != null) dataService.updateMapElement(action.element!.clone());
        break;
      case ActionType.batch:
        for (final sub in action.batch ?? const <MapAction>[]) {
          _applyRedoAction(sub, dataService);
        }
        break;
    }
  }

  void _performUndo() {
    final action = _undoRedoManager.undo();
    if (action == null) return;
    final dataService = Provider.of<MockDataService>(context, listen: false);
    setState(() {
      _applyUndoAction(action, dataService);
      _selectedElement = null;
      _selectedElementIds.clear();
    });
  }

  void _performRedo() {
    final action = _undoRedoManager.redo();
    if (action == null) return;
    final dataService = Provider.of<MockDataService>(context, listen: false);
    setState(() {
      _applyRedoAction(action, dataService);
      _selectedElement = null;
      _selectedElementIds.clear();
    });
  }

  void _showBeachWizard(BuildContext context) async {
    final result = await showDialog<List<MapElement>>(
      context: context,
      builder: (context) => const BeachWizardDialog(),
    );

    if (result != null && context.mounted) {
      final dataService = Provider.of<MockDataService>(context, listen: false);
      final subActions = <MapAction>[];
      for (final element in result) {
        dataService.addMapElement(element);
        subActions.add(MapAction(type: ActionType.add, element: element.clone()));
      }
      if (subActions.isNotEmpty) {
        _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
      }
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Spiaggia creata con ${result.length} elementi!')),
        );
      }
    }
  }

  void _showGridGeneratorDialog(BuildContext context) async {
    final result = await showDialog<List<MapElement>>(
      context: context,
      builder: (context) => const GridGeneratorDialog(),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final dataService = Provider.of<MockDataService>(context, listen: false);
      final subActions = <MapAction>[];
      for (final element in result) {
        dataService.addMapElement(element);
        subActions.add(MapAction(type: ActionType.add, element: element.clone()));
      }
      _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Griglia creata con ${result.length} elementi!')),
        );
      }
    }
  }

  void _showBulkRenameDialog(BuildContext context) async {
    if (_selectedElementIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un elemento da rinominare!')),
      );
      return;
    }

    final dataService = Provider.of<MockDataService>(context, listen: false);
    final selectedElements =
        dataService.mapElements.where((e) => _selectedElementIds.contains(e.id)).toList();
    // BulkRenameDialog mutates these live objects in place, so the "before"
    // snapshot must be taken before opening it, not after it returns.
    final beforeSnapshots = {for (final e in selectedElements) e.id: e.clone()};

    final result = await showDialog<List<MapElement>>(
      context: context,
      builder: (context) => BulkRenameDialog(elements: selectedElements),
    );

    if (result != null) {
      final subActions = <MapAction>[];
      for (final element in result) {
        dataService.updateMapElement(element);
        final before = beforeSnapshots[element.id];
        if (before != null) {
          subActions.add(MapAction(type: ActionType.update, element: element.clone(), previousState: before));
        }
      }
      if (subActions.isNotEmpty) {
        _undoRedoManager.recordAction(MapAction(type: ActionType.batch, batch: subActions));
      }
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.length} elementi rinominati!')),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aiuto'),
        content: const Text(
          'Map Editor\n\n'
          '• Trascina elementi dalla palette sulla mappa per aggiungerli.\n'
          '• Clic su un elemento per selezionarlo; Ctrl/Cmd/Shift+clic per selezionarne più di uno.\n'
          '• Trascina un rettangolo su un\'area vuota per selezionare tutti gli elementi al suo interno.\n'
          '• Con più elementi selezionati appare una barra per allinearli o distribuirli.\n'
          '• Annulla/Ripeti coprono aggiunta, rimozione, spostamento, ridimensionamento e rotazione.\n'
          '• Non è possibile trascinare un elemento sopra un altro già occupato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}
