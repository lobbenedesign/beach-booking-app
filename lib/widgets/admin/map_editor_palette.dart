import 'package:flutter/material.dart';
import '../../models/beach_model.dart';
import '../map/map_element_catalog.dart';

class MapEditorPalette extends StatefulWidget {
  final Function(MapElementType) onElementDragged;

  const MapEditorPalette({
    super.key,
    required this.onElementDragged,
  });

  @override
  State<MapEditorPalette> createState() => _MapEditorPaletteState();
}

class _MapEditorPaletteState extends State<MapEditorPalette> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFFF4F6F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.widgets, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Elementi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca elemento…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final entry in MapElementCatalog.sections.entries)
                  _buildSection(entry.key, entry.value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<MapElementType> types) {
    final filtered = _query.isEmpty
        ? types
        : types
            .where((t) => MapElementCatalog.label(t).toLowerCase().contains(_query))
            .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map(_buildDraggablePaletteItem).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggablePaletteItem(MapElementType type) {
    final tile = _PaletteTile(type: type);
    return Draggable<MapElementType>(
      data: type,
      feedback: Opacity(
        opacity: 0.85,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: Colors.white,
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: Center(child: MapElementCatalog.preview(type, size: 40)),
          ),
        ),
      ),
      child: tile,
    );
  }
}

class _PaletteTile extends StatelessWidget {
  final MapElementType type;
  const _PaletteTile({required this.type});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MapElementCatalog.label(type),
      child: Container(
        width: 74,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Center(child: MapElementCatalog.preview(type, size: 38)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                MapElementCatalog.label(type),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
