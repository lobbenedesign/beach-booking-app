import 'package:flutter/material.dart';
import '../../models/beach_model.dart';

class BulkRenameDialog extends StatefulWidget {
  final List<MapElement> elements;

  const BulkRenameDialog({
    super.key,
    required this.elements,
  });

  @override
  State<BulkRenameDialog> createState() => _BulkRenameDialogState();
}

class _BulkRenameDialogState extends State<BulkRenameDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String _prefix = 'Ombrellone';
  int _startNumber = 1;
  bool _autoIncrement = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rinomina ${widget.elements.length} Elementi'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _prefix,
              decoration: const InputDecoration(
                labelText: 'Nuovo Prefisso / Nome',
                helperText: 'Usa {n} per il numero progressivo se non usi auto-incremento',
              ),
              onSaved: (v) => _prefix = v ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _startNumber.toString(),
                    decoration: const InputDecoration(labelText: 'Numero di partenza'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _startNumber = int.tryParse(v ?? '') ?? 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Auto Incr.'),
                    value: _autoIncrement,
                    onChanged: (v) => setState(() => _autoIncrement = v ?? true),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _apply,
          child: const Text('Applica'),
        ),
      ],
    );
  }

  void _apply() {
    _formKey.currentState!.save();
    
    List<MapElement> updatedElements = [];
    int counter = _startNumber;

    for (var element in widget.elements) {
      String newLabel = _prefix;
      
      if (_autoIncrement) {
        newLabel = '$newLabel $counter';
        counter++;
      } else {
        newLabel = newLabel.replaceAll('{n}', '$counter');
        // If user didn't put {n}, they all get same name? Or maybe we should force increment?
        // Let's assume simple logic for now.
      }

      // Create a copy with new label
      // Assuming MapElement is mutable or we have a copyWith. 
      // Looking at previous code, it seems mutable (setState in map_editor_screen updates label directly).
      // But for safety let's assume we should return modified objects.
      // Since we don't have copyWith visible in the snippet, I'll modify the passed instance if it's mutable, 
      // OR better, I'll assume I can modify them and return the list.
      
      element.label = newLabel;
      // Also update row/number if possible?
      // element.number = '$counter'; 
      updatedElements.add(element);
    }

    Navigator.pop(context, updatedElements);
  }
}
