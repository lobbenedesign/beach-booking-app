import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/beach_model.dart';
import '../../services/mock_data_service.dart';
import '../custom_painters.dart';
import 'dart:math' as math;

class ZoneEditorDialog extends StatefulWidget {
  final BeachZone? zone;

  const ZoneEditorDialog({super.key, this.zone});

  @override
  State<ZoneEditorDialog> createState() => _ZoneEditorDialogState();
}

class _ZoneEditorDialogState extends State<ZoneEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late Color _selectedColor;
  PricingType _pricingType = PricingType.percentage;
  
  // Selection state
  final Set<String> _selectedUmbrellaIds = {};
  
  // Map state
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone?.name ?? '');
    _valueController = TextEditingController(text: widget.zone?.value.toString() ?? '0.0');
    _selectedColor = widget.zone?.color ?? Colors.blue.shade100;
    _pricingType = widget.zone?.pricingType ?? PricingType.percentage;
    _transformationController = TransformationController();
    
    // Initialize selection if editing existing zone
    if (widget.zone != null) {
      // We need to find umbrellas that belong to this zone
      // This will be done in build/didChangeDependencies as we need context/provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dataService = Provider.of<MockDataService>(context, listen: false);
        final umbrellasInZone = dataService.umbrellas.where((u) => u.zoneId == widget.zone!.id).map((u) => u.id);
        setState(() {
          _selectedUmbrellaIds.addAll(umbrellasInZone);
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final elements = dataService.mapElements;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 1000,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.zone == null ? 'Nuova Zona' : 'Modifica Zona',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel: Form
                  SizedBox(
                    width: 300,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nome Zona'),
                            validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Pricing Type Selector
                          DropdownButtonFormField<PricingType>(
                            initialValue: _pricingType,
                            decoration: const InputDecoration(labelText: 'Tipo di Prezzo'),
                            items: const [
                              DropdownMenuItem(value: PricingType.fixed, child: Text('Fisso (€)')),
                              DropdownMenuItem(value: PricingType.percentage, child: Text('Percentuale (%)')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _pricingType = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _valueController,
                            decoration: InputDecoration(
                              labelText: _pricingType == PricingType.fixed ? 'Importo Extra (€)' : 'Percentuale Extra (%)',
                              helperText: _pricingType == PricingType.fixed 
                                  ? 'Es. 10.00 per aggiungere 10€' 
                                  : 'Es. 20.0 per aggiungere il 20%',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Campo obbligatorio';
                              if (double.tryParse(value) == null) return 'Inserire un numero valido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text('Colore Zona'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Colors.blue.shade100,
                              Colors.green.shade100,
                              Colors.red.shade100,
                              Colors.orange.shade100,
                              Colors.purple.shade100,
                              Colors.teal.shade100,
                              Colors.pink.shade100,
                              Colors.amber.shade100,
                            ].map((color) => GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: _selectedColor == color
                                      ? Border.all(color: Colors.black, width: 2)
                                      : null,
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 32),
                          const Text('Selezione Rapida'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _selectRow(elements, 1),
                                child: const Text('Fila 1'),
                              ),
                              OutlinedButton(
                                onPressed: () => _selectRow(elements, 2),
                                child: const Text('Fila 2'),
                              ),
                              OutlinedButton(
                                onPressed: () => _selectRow(elements, 3),
                                child: const Text('Fila 3'),
                              ),
                              OutlinedButton(
                                onPressed: () => setState(() => _selectedUmbrellaIds.clear()),
                                child: const Text('Deseleziona Tutto'),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text('${_selectedUmbrellaIds.length} ombrelloni selezionati',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  
                  const VerticalDivider(width: 48),
                  
                  // Right Panel: Map Selection
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade200,
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 16),
                              SizedBox(width: 8),
                              Text('Clicca sugli ombrelloni per aggiungerli alla zona'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: ClipRect(
                              child: InteractiveViewer(
                                transformationController: _transformationController,
                                minScale: 0.5,
                                maxScale: 4.0,
                                boundaryMargin: const EdgeInsets.all(double.infinity),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SizedBox(
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      child: Stack(
                                        children: elements.map((e) => _buildMapElement(e, constraints)).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _saveZone(context, dataService),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Salva Zona'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapElement(MapElement element, BoxConstraints constraints) {
    final isSelected = _selectedUmbrellaIds.contains(element.id);
    final isUmbrella = element.type == MapElementType.umbrella;
    
    return Positioned(
      left: element.x * constraints.maxWidth,
      top: element.y * constraints.maxHeight,
      width: element.width * constraints.maxWidth,
      height: element.height * constraints.maxHeight,
      child: GestureDetector(
        onTap: isUmbrella ? () {
          setState(() {
            if (isSelected) {
              _selectedUmbrellaIds.remove(element.id);
            } else {
              _selectedUmbrellaIds.add(element.id);
            }
          });
        } : null,
        child: Opacity(
          opacity: isUmbrella ? 1.0 : 0.3, // Dim non-umbrella elements
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: _selectedColor, width: 3),
                    boxShadow: [
                      BoxShadow(color: _selectedColor.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                    ],
                    shape: BoxShape.circle, // Assuming umbrellas are circular-ish
                  )
                : null,
            child: _buildElementVisualWithTransform(element, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildElementVisualWithTransform(MapElement element, bool isSelected) {
    final matrix = Matrix4.identity();
    
    if (element.rotation != 0) {
      matrix.translate(0.5, 0.5, 0.0);
      matrix.rotateZ(element.rotation * math.pi / 180);
      matrix.translate(-0.5, -0.5, 0.0);
    }
    
    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: _buildElementVisual(element, isSelected),
    );
  }

  Widget _buildElementVisual(MapElement element, bool isSelected) {
    // Terrain
    if (element.type == MapElementType.sand) {
      return Container(color: element.color ?? const Color(0xFFE6C288));
    }
    
    if (element.type == MapElementType.sea) {
      return CustomPaint(
        painter: WavePainter(
          color: element.color ?? const Color(0xFF90CAF9),
          animationValue: 0.5, // Static wave for dialog
        ),
        size: Size.infinite,
      );
    }
    
    if (element.type == MapElementType.rock) {
      return CustomPaint(
        painter: RockPainter(color: element.color ?? Colors.grey),
      );
    }
    
    if (element.type == MapElementType.walkway) {
      return CustomPaint(
        painter: WalkwayPainter(color: element.color ?? const Color(0xFF8D6E63)),
      );
    }
    
    if (element.type == MapElementType.grass) {
      return CustomPaint(
        painter: GrassPainter(color: element.color ?? Colors.green),
      );
    }
    
    // Rentals
    if (element.type == MapElementType.umbrella) {
      return Stack(
        children: [
          CustomPaint(
            painter: UmbrellaPainter(
              color: isSelected ? _selectedColor : (element.color ?? Colors.red),
            ),
            size: Size.infinite,
          ),
          if (element.label != null || element.row != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(2),
                color: Colors.white.withOpacity(0.8),
                child: Text(
                  element.label ?? '${element.row}-${element.number}',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      );
    }
    
    if (element.type == MapElementType.sunbed) {
      return CustomPaint(
        painter: SunbedPainter(color: element.color ?? Colors.orange),
      );
    }
    
    if (element.type == MapElementType.deckchair) {
      return CustomPaint(
        painter: DeckchairPainter(color: element.color ?? Colors.orange),
      );
    }
    
    if (element.type == MapElementType.pedalo) {
      return CustomPaint(
        painter: PedaloPainter(color: element.color ?? Colors.cyan),
      );
    }
    
    if (element.type == MapElementType.canoe) {
      return CustomPaint(
        painter: CanoePainter(color: element.color ?? Colors.teal),
      );
    }
    
    if (element.type == MapElementType.boat) {
      return CustomPaint(
        painter: BoatPainter(color: element.color ?? Colors.blue),
      );
    }
    
    if (element.type == MapElementType.surf) {
      return CustomPaint(
        painter: SurfPainter(color: element.color ?? Colors.lightBlue),
      );
    }
    
    if (element.type == MapElementType.windsurf) {
      return CustomPaint(
        painter: WindsurfPainter(color: element.color ?? Colors.cyan),
      );
    }
    
    // Facilities
    if (element.type == MapElementType.bar) {
      return CustomPaint(
        painter: BarPainter(color: element.color ?? Colors.brown),
      );
    }
    
    if (element.type == MapElementType.restaurant) {
      return CustomPaint(
        painter: RestaurantPainter(color: element.color ?? Colors.red),
      );
    }
    
    if (element.type == MapElementType.lounge) {
      return CustomPaint(
        painter: LoungePainter(color: element.color ?? Colors.indigo),
      );
    }
    
    if (element.type == MapElementType.wc || element.type == MapElementType.wcDisabled) {
      return Icon(
        element.type == MapElementType.wcDisabled ? Icons.accessible : Icons.wc,
        color: element.color ?? Colors.blue,
        size: 20,
      );
    }
    
    if (element.type == MapElementType.playground) {
      return CustomPaint(
        painter: PlaygroundPainter(color: element.color ?? Colors.orange),
      );
    }
    
    if (element.type == MapElementType.lifeguardTower) {
      return CustomPaint(
        painter: LifeguardTowerPainter(color: element.color ?? Colors.red),
      );
    }
    
    if (element.type == MapElementType.lighthouse) {
      return CustomPaint(
        painter: LighthousePainter(color: element.color ?? Colors.yellow),
      );
    }
    
    if (element.type == MapElementType.ticketOffice) {
      return CustomPaint(
        painter: TicketOfficePainter(color: element.color ?? Colors.purple),
      );
    }
    
    if (element.type == MapElementType.kiosk) {
      return CustomPaint(
        painter: KioskPainter(color: element.color ?? Colors.brown),
      );
    }
    
    if (element.type == MapElementType.firstAid) {
      return CustomPaint(
        painter: FirstAidPainter(color: element.color ?? Colors.white),
      );
    }
    
    // Infrastructure
    if (element.type == MapElementType.dock) {
      return CustomPaint(
        painter: DockPainter(color: element.color ?? Colors.blueGrey),
      );
    }
    
    if (element.type == MapElementType.wall) {
      return CustomPaint(
        painter: WallPainter(color: element.color ?? Colors.grey),
      );
    }
    
    if (element.type == MapElementType.parking) {
      return CustomPaint(
        painter: ParkingPainter(color: element.color ?? Colors.blue),
      );
    }
    
    if (element.type == MapElementType.entrance) {
      return CustomPaint(
        painter: EntrancePainter(color: element.color ?? Colors.green),
      );
    }
    
    // Decorations
    if (element.type == MapElementType.palm) {
      return CustomPaint(
        painter: PalmPainter(color: element.color ?? Colors.green),
      );
    }
    
    if (element.type == MapElementType.plant) {
      return CustomPaint(
        painter: PlantPainter(color: element.color ?? Colors.green),
      );
    }
    
    if (element.type == MapElementType.flower) {
      return CustomPaint(
        painter: FlowerPainter(color: element.color ?? Colors.pink),
      );
    }
    
    if (element.type == MapElementType.bench) {
      return CustomPaint(
        painter: BenchPainter(color: element.color ?? Colors.brown),
      );
    }
    
    // Structures
    if (element.type == MapElementType.shower) {
      return CustomPaint(
        painter: ShowerPainter(color: element.color ?? Colors.blueGrey),
      );
    }
    
    if (element.type == MapElementType.cabin) {
      return CustomPaint(
        painter: CabinPainter(color: element.color ?? Colors.blue),
      );
    }
    
    if (element.type == MapElementType.gazebo) {
      return CustomPaint(
        painter: GazeboPainter(color: element.color ?? Colors.brown),
      );
    }
    
    if (element.type == MapElementType.umbrellaStand) {
      return CustomPaint(
        painter: UmbrellaStandPainter(color: element.color ?? Colors.deepOrange),
      );
    }
    
    if (element.type == MapElementType.fence) {
      return CustomPaint(
        painter: FencePainter(color: element.color ?? Colors.brown),
      );
    }
    
    // Zones
    if (element.type == MapElementType.zone) {
      return CustomPaint(
        painter: ZonePainter(
          borderColor: element.borderColor ?? Colors.purple,
          borderWidth: element.borderWidth,
          fillColor: element.fillColor ?? Colors.purple.withOpacity(0.2),
          fillOpacity: element.fillOpacity,
          title: element.zoneTitle ?? element.label,
          customPath: element.customPath,
        ),
      );
    }

    // Default fallback
    return Icon(Icons.circle, color: element.color ?? Colors.grey);
  }

  void _selectRow(List<MapElement> elements, int row) {
    final umbrellasInRow = elements
        .where((e) => e.type == MapElementType.umbrella && e.row == row)
        .map((e) => e.id)
        .toList();
        
    setState(() {
      _selectedUmbrellaIds.addAll(umbrellasInRow);
    });
  }

  void _saveZone(BuildContext context, MockDataService dataService) {
    if (_formKey.currentState?.validate() ?? false) {
      final zone = BeachZone(
        id: widget.zone?.id ?? const Uuid().v4(),
        name: _nameController.text,
        color: _selectedColor,
        pricingType: _pricingType,
        value: double.parse(_valueController.text),
      );

      if (widget.zone == null) {
        dataService.addZone(zone);
      } else {
        dataService.updateZone(zone);
      }
      
      // Assign selected umbrellas to this zone
      dataService.assignUmbrellasToZone(_selectedUmbrellaIds.toList(), zone.id);

      Navigator.pop(context);
    }
  }
}
