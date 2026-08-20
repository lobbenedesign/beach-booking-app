import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/beach_model.dart';

class BeachWizardDialog extends StatefulWidget {
  const BeachWizardDialog({super.key});

  @override
  State<BeachWizardDialog> createState() => _BeachWizardDialogState();
}

class _BeachWizardDialogState extends State<BeachWizardDialog> {
  int _currentStep = 0;
  
  // Step 1: Dimensions (Conceptual)
  double _widthMeters = 50;
  double _heightMeters = 30;
  
  // Step 2: Grid
  int _rows = 5;
  int _cols = 10;
  // Spacing between umbrellas as a fraction of each grid cell (0.05 = tight, 0.5 = loose).
  double _spacingRatio = 0.2;
  
  // Step 3: Background
  String _bgType = 'rectangle'; // rectangle, square, custom
  
  // Step 4: Sea
  String _seaPosition = 'top'; // top, bottom, left, right
  double _seaSize = 0.2; // 20% of screen

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Creazione Guidata Spiaggia'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _generateBeach();
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
              title: const Text('Dimensioni'),
              content: Column(
                children: [
                  const Text('Imposta le dimensioni approssimative della spiaggia in metri.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _widthMeters.toString(),
                    decoration: const InputDecoration(labelText: 'Larghezza (m)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _widthMeters = double.tryParse(val) ?? 50,
                  ),
                  TextFormField(
                    initialValue: _heightMeters.toString(),
                    decoration: const InputDecoration(labelText: 'Profondità (m)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _heightMeters = double.tryParse(val) ?? 30,
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Ombrelloni'),
              content: Column(
                children: [
                  const Text('Configura la griglia degli ombrelloni.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _rows.toString(),
                          decoration: const InputDecoration(labelText: 'Righe'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _rows = int.tryParse(val) ?? 5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _cols.toString(),
                          decoration: const InputDecoration(labelText: 'Colonne'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _cols = int.tryParse(val) ?? 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Totale ombrelloni: ${_rows * _cols}'),
                  const SizedBox(height: 16),
                  Text('Spaziatura tra ombrelloni: ${(_spacingRatio * 100).toInt()}%'),
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
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Sfondo'),
              content: Column(
                children: [
                  const Text('Scegli la forma della spiaggia.'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _bgType,
                    items: const [
                      DropdownMenuItem(value: 'rectangle', child: Text('Rettangolare')),
                      DropdownMenuItem(value: 'square', child: Text('Quadrata')),
                      // Custom shape requires drawing, maybe just placeholder here
                      DropdownMenuItem(value: 'custom', child: Text('Personalizzata (Disegna dopo)')),
                    ],
                    onChanged: (val) => setState(() => _bgType = val!),
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Mare'),
              content: Column(
                children: [
                  const Text('Posiziona il mare.'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _seaPosition,
                    items: const [
                      DropdownMenuItem(value: 'top', child: Text('Alto')),
                      DropdownMenuItem(value: 'bottom', child: Text('Basso')),
                      DropdownMenuItem(value: 'left', child: Text('Sinistra')),
                      DropdownMenuItem(value: 'right', child: Text('Destra')),
                    ],
                    onChanged: (val) => setState(() => _seaPosition = val!),
                  ),
                  const SizedBox(height: 16),
                  Text('Dimensione Mare: ${(_seaSize * 100).toInt()}%'),
                  Slider(
                    value: _seaSize,
                    min: 0.1,
                    max: 0.5,
                    divisions: 8,
                    onChanged: (val) => setState(() => _seaSize = val),
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  void _generateBeach() {
    // Generate MapElements based on configuration
    List<MapElement> elements = [];
    
    const uuid = Uuid();

    // 1. Background (Sand)
    elements.add(MapElement(
      id: uuid.v4(),
      type: MapElementType.sand,
      x: 0,
      y: 0,
      width: 1.0,
      height: 1.0,
    ));
    
    // 2. Sea
    double seaX = 0, seaY = 0, seaW = 0, seaH = 0;
    int rotation = 0;
    
    switch (_seaPosition) {
      case 'top':
        seaX = 0; seaY = 0; seaW = 1.0; seaH = _seaSize;
        rotation = 0;
        break;
      case 'bottom':
        seaX = 0; seaY = 1.0 - _seaSize; seaW = 1.0; seaH = _seaSize;
        rotation = 180;
        break;
      case 'left':
        seaX = 0; seaY = 0; seaW = _seaSize; seaH = 1.0;
        rotation = 270;
        break;
      case 'right':
        seaX = 1.0 - _seaSize; seaY = 0; seaW = _seaSize; seaH = 1.0;
        rotation = 90;
        break;
    }
    
    elements.add(MapElement(
      id: uuid.v4(),
      type: MapElementType.sea,
      x: seaX,
      y: seaY,
      width: seaW,
      height: seaH,
      rotation: rotation,
    ));
    
    // 3. Umbrellas
    // Calculate available area for umbrellas
    double startY = _seaPosition == 'top' ? _seaSize + 0.05 : 0.05;
    double endY = _seaPosition == 'bottom' ? 1.0 - _seaSize - 0.05 : 0.95;
    double startX = _seaPosition == 'left' ? _seaSize + 0.05 : 0.05;
    double endX = _seaPosition == 'right' ? 1.0 - _seaSize - 0.05 : 0.95;
    
    double availableW = endX - startX;
    double availableH = endY - startY;
    
    double umbW = availableW / _cols * (1 - _spacingRatio);
    double umbH = availableH / _rows * (1 - _spacingRatio);
    double spacingX = availableW / _cols * _spacingRatio;
    double spacingY = availableH / _rows * _spacingRatio;
    
    // Clamp size to reasonable limits
    if (umbW > 0.1) umbW = 0.1;
    if (umbH > 0.1) umbH = 0.1;
    
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        double x = startX + c * (availableW / _cols) + spacingX / 2;
        double y = startY + r * (availableH / _rows) + spacingY / 2;
        
        elements.add(MapElement(
          id: uuid.v4(),
          type: MapElementType.umbrella,
          x: x,
          y: y,
          width: umbW,
          height: umbH,
          row: r + 1,
          number: c + 1,
        ));
      }
    }
    
    Navigator.pop(context, elements);
  }
}
