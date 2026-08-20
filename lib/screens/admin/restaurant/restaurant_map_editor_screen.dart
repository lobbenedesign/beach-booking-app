import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/restaurant_model.dart';
import '../../../services/mock_data_service.dart';
import '../../../utils/restaurant_undo_redo_manager.dart';
import '../../../widgets/admin/admin_scaffold.dart';
import '../../../widgets/admin/restaurant_wizard_dialog.dart';

/// Editor for the restaurant floor plan: add/drag/resize tables, set seats,
/// shape, zone and label — mirrors the beach map editor's own feature set:
/// zone management, a bulk-generation wizard, full add/remove/move/resize
/// undo-redo, an overlap guard when dragging one table onto another, and
/// multi-select with align/distribute tools.
class RestaurantMapEditorScreen extends StatefulWidget {
  const RestaurantMapEditorScreen({super.key});

  @override
  State<RestaurantMapEditorScreen> createState() => _RestaurantMapEditorScreenState();
}

class _RestaurantMapEditorScreenState extends State<RestaurantMapEditorScreen> {
  RestaurantTable? _selected;
  final Set<String> _selectedIds = {};
  final _undoRedoManager = RestaurantUndoRedoManager();

  RestaurantTable? _dragSnapshot;
  Offset? _selectionRectStart;
  Offset? _selectionRectCurrent;

  bool get _isMultiSelect => _selectedIds.length > 1;

  bool get _multiSelectModifierDown =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isShiftPressed;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final tables = data.restaurantTables;

    return AdminScaffold(
      title: 'Editor Mappa Tavoli',
      selectedIndex: 31,
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: 'Creazione guidata',
          onPressed: () => _showWizard(context, data),
        ),
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Annulla',
          onPressed: _undoRedoManager.canUndo ? () => _performUndo(data) : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Ripeti',
          onPressed: _undoRedoManager.canRedo ? () => _performRedo(data) : null,
        ),
        IconButton(
          icon: const Icon(Icons.grid_view),
          tooltip: 'Gestisci Zone',
          onPressed: () => _showZonesDialog(context, data),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Aggiungi tavolo',
          onPressed: () {
            final t = RestaurantTable(id: const Uuid().v4(), x: 0.45, y: 0.45, seats: 4);
            data.addRestaurantTable(t);
            _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.add, table: t.clone()));
            setState(() {
              _selected = t;
              _selectedIds
                ..clear()
                ..add(t.id);
            });
          },
        ),
      ],
      child: Column(
        children: [
          if (_isMultiSelect) _buildMultiSelectToolbar(data),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFFBF3E7),
                    // SizedBox.expand forces tight constraints on the
                    // LayoutBuilder: a Stack made up entirely of Positioned
                    // children collapses to zero size under loose
                    // constraints (Row's default CrossAxisAlignment.center
                    // only ever gives loose cross-axis bounds).
                    child: SizedBox.expand(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
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
                            onPanEnd: (details) => _finishRectSelect(constraints, tables),
                            child: Stack(
                              children: [
                                for (final t in tables) _buildTable(context, data, t, w, h),
                                if (_selectionRectStart != null && _selectionRectCurrent != null)
                                  _buildSelectionRectOverlay(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_selected != null && !_isMultiSelect)
                  Container(
                    width: 320,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildProperties(data, _selected!),
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

  void _finishRectSelect(BoxConstraints constraints, List<RestaurantTable> tables) {
    final start = _selectionRectStart;
    final current = _selectionRectCurrent;
    setState(() {
      _selectionRectStart = null;
      _selectionRectCurrent = null;
    });
    if (start == null || current == null) return;
    final pixelRect = Rect.fromPoints(start, current);
    if (pixelRect.width < 4 || pixelRect.height < 4) return;

    final relRect = Rect.fromLTRB(
      pixelRect.left / constraints.maxWidth,
      pixelRect.top / constraints.maxHeight,
      pixelRect.right / constraints.maxWidth,
      pixelRect.bottom / constraints.maxHeight,
    );

    final matched = tables
        .where((t) => Rect.fromLTWH(t.x, t.y, t.width, t.height).overlaps(relRect))
        .map((t) => t.id)
        .toSet();
    if (matched.isEmpty) return;
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(matched);
      _selected = _selectedIds.length == 1 ? tables.firstWhere((t) => t.id == _selectedIds.first) : null;
    });
  }

  Widget _buildTable(BuildContext context, MockDataService data, RestaurantTable t, double w, double h) {
    final isSelected = _selectedIds.contains(t.id);
    final size = t.width * w;
    return Positioned(
      left: t.x * w,
      top: t.y * h,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_multiSelectModifierDown) {
              if (_selectedIds.contains(t.id)) {
                _selectedIds.remove(t.id);
              } else {
                _selectedIds.add(t.id);
              }
              _selected = _selectedIds.length == 1
                  ? data.restaurantTables.firstWhere((e) => e.id == _selectedIds.first)
                  : null;
            } else {
              _selectedIds
                ..clear()
                ..add(t.id);
              _selected = t;
            }
          });
        },
        onPanStart: (_) => _dragSnapshot = t.clone(),
        onPanUpdate: (details) {
          setState(() {
            t.x = (t.x + details.delta.dx / w).clamp(0.0, 1.0 - t.width);
            t.y = (t.y + details.delta.dy / h).clamp(0.0, 1.0 - t.height);
          });
          data.updateRestaurantTable(t);
        },
        onPanEnd: (_) => _commitDrag(data, t),
        child: Container(
          width: size,
          height: t.height * h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.15),
            borderRadius: BorderRadius.circular(t.shape == TableShape.round ? 999 : 8),
            border: Border.all(color: isSelected ? Colors.blue : Colors.brown, width: isSelected ? 3 : 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_restaurant, color: Colors.brown.shade700, size: size * 0.35),
              Text(t.label ?? '', style: TextStyle(fontSize: 10, color: Colors.brown.shade700, fontWeight: FontWeight.bold)),
              Text('${t.seats}p', style: TextStyle(fontSize: 9, color: Colors.brown.shade400)),
            ],
          ),
        ),
      ),
    );
  }

  /// On drop, rejects the move if it now overlaps another table (reverting
  /// to the pre-drag position) and otherwise commits one undo step for the
  /// whole drag instead of one per pixel of movement.
  void _commitDrag(MockDataService data, RestaurantTable t) {
    final before = _dragSnapshot;
    _dragSnapshot = null;
    if (before == null) return;
    if (before.x == t.x && before.y == t.y) return;

    if (_wouldOverlap(t, t.x, t.y, data)) {
      setState(() {
        t.x = before.x;
        t.y = before.y;
        data.updateRestaurantTable(t);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione occupata: sposta il tavolo su uno spazio libero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _undoRedoManager.recordAction(
        RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
  }

  bool _wouldOverlap(RestaurantTable moving, double newX, double newY, MockDataService data) {
    final insetX = moving.width * 0.12;
    final insetY = moving.height * 0.12;
    final movingRect =
        Rect.fromLTWH(newX + insetX, newY + insetY, moving.width - insetX * 2, moving.height - insetY * 2);
    for (final other in data.restaurantTables) {
      if (other.id == moving.id) continue;
      final oInsetX = other.width * 0.12;
      final oInsetY = other.height * 0.12;
      final otherRect =
          Rect.fromLTWH(other.x + oInsetX, other.y + oInsetY, other.width - oInsetX * 2, other.height - oInsetY * 2);
      if (movingRect.overlaps(otherRect)) return true;
    }
    return false;
  }

  // --- Multi-select toolbar ---

  Widget _buildMultiSelectToolbar(MockDataService data) {
    return Container(
      color: Colors.brown.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('${_selectedIds.length} tavoli selezionati', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          _toolbarIcon(Icons.align_horizontal_left, 'Allinea a sinistra', () => _alignSelected('left', data)),
          _toolbarIcon(
              Icons.align_horizontal_center, 'Allinea al centro (orizz.)', () => _alignSelected('centerH', data)),
          _toolbarIcon(Icons.align_horizontal_right, 'Allinea a destra', () => _alignSelected('right', data)),
          const SizedBox(width: 8),
          _toolbarIcon(Icons.align_vertical_top, 'Allinea in alto', () => _alignSelected('top', data)),
          _toolbarIcon(
              Icons.align_vertical_center, 'Allinea al centro (vert.)', () => _alignSelected('centerV', data)),
          _toolbarIcon(Icons.align_vertical_bottom, 'Allinea in basso', () => _alignSelected('bottom', data)),
          const SizedBox(width: 8),
          _toolbarIcon(Icons.view_column_outlined, 'Distribuisci orizzontalmente',
              () => _distributeSelected(Axis.horizontal, data)),
          _toolbarIcon(Icons.table_rows_outlined, 'Distribuisci verticalmente',
              () => _distributeSelected(Axis.vertical, data)),
          const Spacer(),
          _toolbarIcon(Icons.copy, 'Duplica selezione', () => _duplicateSelectedBatch(data)),
          _toolbarIcon(Icons.delete_outline, 'Elimina selezione', () => _confirmDeleteBatch(data), color: Colors.red),
          _toolbarIcon(Icons.close, 'Deseleziona', () {
            setState(() {
              _selectedIds.clear();
              _selected = null;
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

  List<RestaurantTable> _selectedList(MockDataService data) =>
      data.restaurantTables.where((t) => _selectedIds.contains(t.id)).toList();

  void _alignSelected(String mode, MockDataService data) {
    final ts = _selectedList(data);
    if (ts.length < 2) return;
    double target;
    switch (mode) {
      case 'left':
        target = ts.map((t) => t.x).reduce(math.min);
        break;
      case 'right':
        target = ts.map((t) => t.x + t.width).reduce(math.max);
        break;
      case 'top':
        target = ts.map((t) => t.y).reduce(math.min);
        break;
      case 'bottom':
        target = ts.map((t) => t.y + t.height).reduce(math.max);
        break;
      case 'centerH':
        target = ts.map((t) => t.x + t.width / 2).reduce((a, b) => a + b) / ts.length;
        break;
      case 'centerV':
        target = ts.map((t) => t.y + t.height / 2).reduce((a, b) => a + b) / ts.length;
        break;
      default:
        return;
    }

    final subActions = <RestaurantMapAction>[];
    for (final t in ts) {
      final before = t.clone();
      switch (mode) {
        case 'left':
          t.x = target;
          break;
        case 'right':
          t.x = target - t.width;
          break;
        case 'top':
          t.y = target;
          break;
        case 'bottom':
          t.y = target - t.height;
          break;
        case 'centerH':
          t.x = target - t.width / 2;
          break;
        case 'centerV':
          t.y = target - t.height / 2;
          break;
      }
      t.x = t.x.clamp(0.0, 1.0);
      t.y = t.y.clamp(0.0, 1.0);
      data.updateRestaurantTable(t);
      subActions.add(RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
    }
    _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.batch, batch: subActions));
    setState(() {});
  }

  void _distributeSelected(Axis axis, MockDataService data) {
    final ts = _selectedList(data);
    if (ts.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno 3 tavoli per distribuire')),
      );
      return;
    }
    ts.sort((a, b) => axis == Axis.horizontal ? a.x.compareTo(b.x) : a.y.compareTo(b.y));

    double centerOf(RestaurantTable t) =>
        axis == Axis.horizontal ? t.x + t.width / 2 : t.y + t.height / 2;

    final startCenter = centerOf(ts.first);
    final endCenter = centerOf(ts.last);
    final step = (endCenter - startCenter) / (ts.length - 1);

    final subActions = <RestaurantMapAction>[];
    for (var i = 1; i < ts.length - 1; i++) {
      final t = ts[i];
      final before = t.clone();
      final center = startCenter + step * i;
      if (axis == Axis.horizontal) {
        t.x = (center - t.width / 2).clamp(0.0, 1.0);
      } else {
        t.y = (center - t.height / 2).clamp(0.0, 1.0);
      }
      data.updateRestaurantTable(t);
      subActions.add(RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
    }
    if (subActions.isNotEmpty) {
      _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.batch, batch: subActions));
    }
    setState(() {});
  }

  void _duplicateSelectedBatch(MockDataService data) {
    final ts = _selectedList(data);
    if (ts.isEmpty) return;
    final subActions = <RestaurantMapAction>[];
    final newIds = <String>{};
    for (final t in ts) {
      final copy = RestaurantTable(
        id: const Uuid().v4(),
        x: (t.x + 0.03).clamp(0.0, 1.0 - t.width),
        y: (t.y + 0.03).clamp(0.0, 1.0 - t.height),
        width: t.width,
        height: t.height,
        seats: t.seats,
        shape: t.shape,
        label: t.label,
        rotation: t.rotation,
        zoneId: t.zoneId,
      );
      data.addRestaurantTable(copy);
      subActions.add(RestaurantMapAction(type: RestaurantActionType.add, table: copy.clone()));
      newIds.add(copy.id);
    }
    _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.batch, batch: subActions));
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(newIds);
      _selected = newIds.length == 1 ? data.restaurantTables.firstWhere((t) => t.id == newIds.first) : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ts.length} tavoli duplicati')));
  }

  void _confirmDeleteBatch(MockDataService data) {
    final ts = _selectedList(data);
    if (ts.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Eliminare ${ts.length} tavoli selezionati?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final subActions = <RestaurantMapAction>[];
              for (final t in ts) {
                data.removeRestaurantTable(t.id);
                subActions.add(RestaurantMapAction(type: RestaurantActionType.remove, table: t.clone()));
              }
              _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.batch, batch: subActions));
              Navigator.pop(context);
              setState(() {
                _selectedIds.clear();
                _selected = null;
              });
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  // --- Single-selection properties panel ---

  Widget _buildProperties(MockDataService data, RestaurantTable t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proprietà Tavolo', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        TextFormField(
          key: ValueKey(t.id),
          initialValue: t.label,
          decoration: const InputDecoration(labelText: 'Etichetta'),
          onChanged: (v) {
            final before = t.clone();
            setState(() => t.label = v);
            data.updateRestaurantTable(t);
            _undoRedoManager
                .recordAction(RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: t.zoneId,
          decoration: const InputDecoration(labelText: 'Zona'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Senza zona')),
            ...data.restaurantZones.map((z) => DropdownMenuItem<String?>(value: z.id, child: Text(z.name))),
          ],
          onChanged: (v) {
            final before = t.clone();
            setState(() => t.zoneId = v);
            data.updateRestaurantTable(t);
            _undoRedoManager
                .recordAction(RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
          },
        ),
        const SizedBox(height: 16),
        Text('Posti: ${t.seats}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: t.seats.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          label: '${t.seats}',
          onChangeStart: (_) => _dragSnapshot = t.clone(),
          onChanged: (v) {
            setState(() => t.seats = v.toInt());
            data.updateRestaurantTable(t);
          },
          onChangeEnd: (_) => _commitSliderInteraction(t),
        ),
        const SizedBox(height: 8),
        const Text('Forma', style: TextStyle(fontWeight: FontWeight.bold)),
        SegmentedButton<TableShape>(
          segments: const [
            ButtonSegment(value: TableShape.round, label: Text('Rotondo')),
            ButtonSegment(value: TableShape.square, label: Text('Quadrato')),
            ButtonSegment(value: TableShape.rectangle, label: Text('Rettangolo')),
          ],
          selected: {t.shape},
          onSelectionChanged: (s) {
            final before = t.clone();
            setState(() => t.shape = s.first);
            data.updateRestaurantTable(t);
            _undoRedoManager
                .recordAction(RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
          },
        ),
        const SizedBox(height: 16),
        Text('Larghezza: ${(t.width * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: t.width.clamp(0.03, 0.25),
          min: 0.03,
          max: 0.25,
          onChangeStart: (_) => _dragSnapshot = t.clone(),
          onChanged: (v) {
            setState(() => t.width = v);
            data.updateRestaurantTable(t);
          },
          onChangeEnd: (_) => _commitSliderInteraction(t),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelete(data, t),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Elimina'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  void _commitSliderInteraction(RestaurantTable t) {
    final before = _dragSnapshot;
    _dragSnapshot = null;
    if (before == null) return;
    _undoRedoManager
        .recordAction(RestaurantMapAction(type: RestaurantActionType.update, table: t.clone(), previousState: before));
  }

  void _confirmDelete(MockDataService data, RestaurantTable t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Eliminare il tavolo ${t.label ?? t.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              data.removeRestaurantTable(t.id);
              _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.remove, table: t.clone()));
              Navigator.pop(context);
              setState(() {
                _selected = null;
                _selectedIds.remove(t.id);
              });
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _applyUndoAction(RestaurantMapAction action, MockDataService data) {
    switch (action.type) {
      case RestaurantActionType.add:
        if (action.table != null) data.removeRestaurantTable(action.table!.id);
        break;
      case RestaurantActionType.remove:
        if (action.table != null) data.addRestaurantTable(action.table!.clone());
        break;
      case RestaurantActionType.update:
        if (action.previousState != null) data.updateRestaurantTable(action.previousState!.clone());
        break;
      case RestaurantActionType.batch:
        for (final sub in (action.batch ?? const <RestaurantMapAction>[]).reversed) {
          _applyUndoAction(sub, data);
        }
        break;
    }
  }

  void _applyRedoAction(RestaurantMapAction action, MockDataService data) {
    switch (action.type) {
      case RestaurantActionType.add:
        if (action.table != null) data.addRestaurantTable(action.table!.clone());
        break;
      case RestaurantActionType.remove:
        if (action.table != null) data.removeRestaurantTable(action.table!.id);
        break;
      case RestaurantActionType.update:
        if (action.table != null) data.updateRestaurantTable(action.table!.clone());
        break;
      case RestaurantActionType.batch:
        for (final sub in action.batch ?? const <RestaurantMapAction>[]) {
          _applyRedoAction(sub, data);
        }
        break;
    }
  }

  void _performUndo(MockDataService data) {
    final action = _undoRedoManager.undo();
    if (action == null) return;
    setState(() {
      _applyUndoAction(action, data);
      _selected = null;
      _selectedIds.clear();
    });
  }

  void _performRedo(MockDataService data) {
    final action = _undoRedoManager.redo();
    if (action == null) return;
    setState(() {
      _applyRedoAction(action, data);
      _selected = null;
      _selectedIds.clear();
    });
  }

  void _showWizard(BuildContext context, MockDataService data) async {
    final result = await showDialog<List<RestaurantTable>>(
      context: context,
      builder: (context) => RestaurantWizardDialog(zones: data.restaurantZones),
    );
    if (result == null || result.isEmpty) return;
    final subActions = <RestaurantMapAction>[];
    for (final t in result) {
      data.addRestaurantTable(t);
      subActions.add(RestaurantMapAction(type: RestaurantActionType.add, table: t.clone()));
    }
    _undoRedoManager.recordAction(RestaurantMapAction(type: RestaurantActionType.batch, batch: subActions));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sala generata con ${result.length} tavoli!')),
      );
    }
  }

  void _showZonesDialog(BuildContext context, MockDataService data) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Gestisci Zone'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...data.restaurantZones.map((z) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Color(z.colorValue), radius: 10),
                      title: Text(z.name),
                      subtitle: Text('${data.restaurantTables.where((t) => t.zoneId == z.id).length} tavoli'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          data.deleteRestaurantZone(z.id);
                          setLocal(() {});
                        },
                      ),
                    )),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nuova zona (es. Terrazza)'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.brown),
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        data.addRestaurantZone(RestaurantZone(
                          id: const Uuid().v4(),
                          name: name,
                          colorValue:
                              Colors.primaries[data.restaurantZones.length % Colors.primaries.length].shade200.toARGB32(),
                        ));
                        nameController.clear();
                        setLocal(() {});
                      },
                    ),
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
}
