import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/beach_model.dart';

class MapEditorToolbar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final MapElement? selectedElement;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onGridGenerator;
  final VoidCallback onBulkRename;
  final VoidCallback onBeachWizard;
  final VoidCallback onManageZones;
  final VoidCallback onDuplicateSelected;
  final VoidCallback onBackgroundImage;
  final VoidCallback onSave;
  final VoidCallback onHelp;

  const MapEditorToolbar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.selectedElement,
    required this.onUndo,
    required this.onRedo,
    required this.onGridGenerator,
    required this.onBulkRename,
    required this.onBeachWizard,
    required this.onManageZones,
    required this.onDuplicateSelected,
    required this.onBackgroundImage,
    required this.onSave,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[MapEditorToolbar] Building toolbar');
    
    return AppBar(
      title: const Text('Editor Spiaggia 2.0'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate),
          tooltip: 'Nuova Spiaggia (Wizard)',
          onPressed: () {
            debugPrint('[MapEditorToolbar] Beach Wizard button pressed');
            onBeachWizard();
          },
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Annulla (Ctrl+Z)',
          onPressed: canUndo ? () {
            debugPrint('[MapEditorToolbar] Undo button pressed');
            onUndo();
          } : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Ripristina (Ctrl+Y)',
          onPressed: canRedo ? () {
            debugPrint('[MapEditorToolbar] Redo button pressed');
            onRedo();
          } : null,
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.grid_on),
          tooltip: 'Genera Griglia',
          onPressed: () {
            debugPrint('[MapEditorToolbar] Grid Generator button pressed');
            onGridGenerator();
          },
        ),
        IconButton(
          icon: const Icon(Icons.drive_file_rename_outline),
          tooltip: 'Rinomina in Blocco',
          onPressed: () {
            debugPrint('[MapEditorToolbar] Bulk Rename button pressed');
            onBulkRename();
          },
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.grid_view),
          tooltip: 'Gestisci Zone',
          onPressed: onManageZones,
        ),
        IconButton(
          icon: const Icon(Icons.copy_all),
          tooltip: 'Duplica elemento selezionato',
          onPressed: selectedElement == null ? null : onDuplicateSelected,
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.image_outlined),
          tooltip: 'Sfondo spiaggia personalizzato',
          onPressed: onBackgroundImage,
        ),
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Libreria grafica (SVG) · Superadmin',
          onPressed: () => context.push('/admin/svg-library'),
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            debugPrint('[MapEditorToolbar] Save button pressed');
            onSave();
          },
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Aiuto',
          onPressed: () {
            debugPrint('[MapEditorToolbar] Help button pressed');
            onHelp();
          },
        ),
      ],
    );
  }
}
