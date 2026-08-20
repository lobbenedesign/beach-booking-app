import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/beach_model.dart';

class GridGeneratorDialog extends StatefulWidget {
  const GridGeneratorDialog({super.key});

  @override
  State<GridGeneratorDialog> createState() => _GridGeneratorDialogState();
}

class _GridGeneratorDialogState extends State<GridGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  int _rows = 5;
  int _cols = 10;
  
  // Positioning (0.0 - 1.0)
  double _startX = 0.1;
  double _startY = 0.1;
  double _gapX = 0.06; // Horizontal spacing
  double _gapY = 0.08; // Vertical spacing
  
  // Naming
  String _rowPrefix = 'Fila';
  bool _useLettersForRows = false;
  final int _startNumber = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generatore Griglia Ombrelloni'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dimensioni Griglia', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _rows.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Righe',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Min 1',
                        onSaved: (v) => _rows = int.parse(v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _cols.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Colonne',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Min 1',
                        onSaved: (v) => _cols = int.parse(v!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Text('Posizione e Spaziatura', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _startX.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Start X (0-1)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSaved: (v) => _startX = double.parse(v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _startY.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Start Y (0-1)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSaved: (v) => _startY = double.parse(v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _gapX.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Gap X',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSaved: (v) => _gapX = double.parse(v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _gapY.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Gap Y',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSaved: (v) => _gapY = double.parse(v!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('Numerazione', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _rowPrefix,
                  decoration: const InputDecoration(
                    labelText: 'Prefisso Riga (es. "Fila")',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSaved: (v) => _rowPrefix = v ?? '',
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Usa lettere per le righe (A, B, C...)'),
                  value: _useLettersForRows,
                  onChanged: (v) => setState(() => _useLettersForRows = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _generate,
          child: const Text('Genera'),
        ),
      ],
    );
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    List<MapElement> elements = [];
    
    for (int r = 0; r < _rows; r++) {
      String rowLabel;
      if (_useLettersForRows) {
        rowLabel = String.fromCharCode('A'.codeUnitAt(0) + r);
      } else {
        rowLabel = '$_rowPrefix ${r + 1}'.trim();
      }

      for (int c = 0; c < _cols; c++) {
        final numberVal = c + _startNumber;
        final numberStr = '$numberVal';
        
        elements.add(MapElement(
          id: const Uuid().v4(),
          type: MapElementType.umbrella,
          x: _startX + (c * _gapX),
          y: _startY + (r * _gapY),
          width: 0.05,
          height: 0.05,
          label: '$rowLabel-$numberStr',
          row: r + 1,
          number: numberVal,
          color: Colors.red, // Default umbrella color
        ));
      }
    }
    
    Navigator.pop(context, elements);
  }
}
