import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/restaurant_model.dart';

/// Bulk floor-plan generator for the restaurant — mirrors [BeachWizardDialog]
/// (grid + spacing + shape), scoped to tables instead of umbrellas/sea/sand.
class RestaurantWizardDialog extends StatefulWidget {
  final List<RestaurantZone> zones;

  const RestaurantWizardDialog({super.key, required this.zones});

  @override
  State<RestaurantWizardDialog> createState() => _RestaurantWizardDialogState();
}

class _RestaurantWizardDialogState extends State<RestaurantWizardDialog> {
  int _currentStep = 0;

  int _rows = 3;
  int _cols = 4;
  double _spacingRatio = 0.25;

  int _seats = 4;
  TableShape _shape = TableShape.round;
  String? _zoneId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Creazione Guidata Sala'),
      content: SizedBox(
        width: 600,
        height: 380,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 1) {
              setState(() => _currentStep++);
            } else {
              _generateTables();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          steps: [
            Step(
              title: const Text('Griglia'),
              content: Column(
                children: [
                  const Text('Configura la griglia di tavoli da generare.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _rows.toString(),
                          decoration: const InputDecoration(labelText: 'Righe'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _rows = int.tryParse(val) ?? 3,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _cols.toString(),
                          decoration: const InputDecoration(labelText: 'Colonne'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _cols = int.tryParse(val) ?? 4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Totale tavoli: ${_rows * _cols}'),
                  const SizedBox(height: 16),
                  Text('Spaziatura tra tavoli: ${(_spacingRatio * 100).toInt()}%'),
                  Slider(
                    value: _spacingRatio,
                    min: 0.05,
                    max: 0.5,
                    divisions: 9,
                    label: '${(_spacingRatio * 100).toInt()}%',
                    onChanged: (val) => setState(() => _spacingRatio = val),
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Tavoli'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Imposta le proprietà comuni dei tavoli generati.'),
                  const SizedBox(height: 16),
                  Text('Posti per tavolo: $_seats', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _seats.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '$_seats',
                    onChanged: (val) => setState(() => _seats = val.toInt()),
                  ),
                  const SizedBox(height: 8),
                  const Text('Forma', style: TextStyle(fontWeight: FontWeight.bold)),
                  SegmentedButton<TableShape>(
                    segments: const [
                      ButtonSegment(value: TableShape.round, label: Text('Rotondo')),
                      ButtonSegment(value: TableShape.square, label: Text('Quadrato')),
                      ButtonSegment(value: TableShape.rectangle, label: Text('Rettangolo')),
                    ],
                    selected: {_shape},
                    onSelectionChanged: (s) => setState(() => _shape = s.first),
                  ),
                  if (widget.zones.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: _zoneId,
                      decoration: const InputDecoration(labelText: 'Zona'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Senza zona')),
                        ...widget.zones.map((z) => DropdownMenuItem<String?>(value: z.id, child: Text(z.name))),
                      ],
                      onChanged: (v) => setState(() => _zoneId = v),
                    ),
                  ],
                ],
              ),
              isActive: _currentStep >= 1,
            ),
          ],
        ),
      ),
    );
  }

  void _generateTables() {
    final tables = <RestaurantTable>[];
    const uuid = Uuid();

    const startX = 0.05, endX = 0.95, startY = 0.08, endY = 0.95;
    final availableW = endX - startX;
    final availableH = endY - startY;

    var w = availableW / _cols * (1 - _spacingRatio);
    var h = availableH / _rows * (1 - _spacingRatio);
    final spacingX = availableW / _cols * _spacingRatio;
    final spacingY = availableH / _rows * _spacingRatio;

    if (w > 0.12) w = 0.12;
    if (h > 0.12) h = 0.12;

    var n = 1;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final x = startX + c * (availableW / _cols) + spacingX / 2;
        final y = startY + r * (availableH / _rows) + spacingY / 2;

        tables.add(RestaurantTable(
          id: uuid.v4(),
          x: x,
          y: y,
          width: w,
          height: h,
          seats: _seats,
          shape: _shape,
          label: '${n++}',
          zoneId: _zoneId,
        ));
      }
    }

    Navigator.pop(context, tables);
  }
}
