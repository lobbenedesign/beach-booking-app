import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/beach_model.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/map/map_element_catalog.dart';

/// Superadmin-facing library that lets a specific SVG file be assigned to each
/// map element type, overriding the built-in painter across the whole app
/// (palette, editor and operator map). Overrides are held in
/// [MapElementCatalog.svgOverrides]; a production build would persist them.
class SvgLibraryScreen extends StatefulWidget {
  const SvgLibraryScreen({super.key});

  @override
  State<SvgLibraryScreen> createState() => _SvgLibraryScreenState();
}

class _SvgLibraryScreenState extends State<SvgLibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Libreria Grafica (SVG)',
      selectedIndex: -1,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Area superadmin · Assegna un file SVG a ciascun oggetto per '
                    'sostituire la grafica predefinita nell\'intera app.',
                    style: TextStyle(color: Colors.brown.shade700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final section in MapElementCatalog.sections.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(section.key.toUpperCase(),
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  ...section.value.map(_buildRow),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(MapElementType type) {
    final hasSvg = MapElementCatalog.hasSvg(type);
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: MapElementCatalog.preview(type, size: 40)),
        ),
        title: Text(MapElementCatalog.label(type)),
        subtitle: Text(hasSvg ? 'SVG personalizzato attivo' : 'Grafica predefinita',
            style: TextStyle(
                color: hasSvg ? Colors.green : Colors.grey,
                fontWeight: hasSvg ? FontWeight.w600 : FontWeight.normal)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _editSvg(type),
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(hasSvg ? 'Cambia' : 'Carica SVG'),
            ),
            if (hasSvg)
              IconButton(
                icon: const Icon(Icons.restart_alt, color: Colors.red),
                tooltip: 'Ripristina predefinito',
                onPressed: () {
                  setState(() => MapElementCatalog.clearSvg(type));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _editSvg(MapElementType type) {
    final controller =
        TextEditingController(text: MapElementCatalog.svgOverrides[type] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('SVG · ${MapElementCatalog.label(type)}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Carica un file .svg oppure incolla direttamente il markup (es. <svg ...>...</svg>). Verrà usato al posto della grafica predefinita.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '<svg xmlns="http://www.w3.org/2000/svg" ...>',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['svg'],
                        withData: true,
                      );
                      final bytes = result?.files.single.bytes;
                      if (bytes == null) return;
                      controller.text = utf8.decode(bytes);
                    },
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Carica file .svg'),
                  ),
                  TextButton.icon(
                    onPressed: () => controller.text = _sampleSvg,
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Inserisci SVG di esempio'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final svg = controller.text.trim();
              if (svg.isNotEmpty && !svg.contains('<svg')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Il testo non sembra un SVG valido')));
                return;
              }
              setState(() => MapElementCatalog.setSvg(type, svg));
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  static const _sampleSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<circle cx="12" cy="12" r="10" fill="#1565C0"/>'
      '<path d="M12 6 L14 12 L12 18 L10 12 Z" fill="#FFFFFF"/></svg>';
}
