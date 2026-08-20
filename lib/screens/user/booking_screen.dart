import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Added for Timer
import 'dart:convert';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
import '../../widgets/custom_painters.dart';
import '../../widgets/map/beach_background_layer.dart';
import 'dart:math' as math;
import '../../widgets/user/booking_recap_dialog.dart';
import '../../widgets/user/booking_success_dialog.dart';
import '../../services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  Timer? _statusCheckTimer;

  // Date selection
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  
  // Steps: 0 = Date, 1 = Package, 2 = Map
  int _currentStep = 0;
  ServicePackage? _selectedPackage;
  
  // Selected umbrellas (Multi-selection)
  final Set<MapElement> _selectedUmbrellas = {};

  @override
  void initState() {
    super.initState();
    debugPrint('[BookingScreen] Initializing...');
    _waveAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
    )..repeat();

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _checkLockStatus();
    });
  }

  void _checkLockStatus() {
    if (_currentStep != 2 || _selectedUmbrellas.isEmpty) return;

    final dataService = Provider.of<MockDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id ?? 'guest';

    bool lostLock = false;
    // Check if we still hold the lock for ALL selected umbrellas
    // Since we handle multi-select, even one loss is critical or we just deselect it?
    // User requested "Receive IMMEDIATELY an error screen".
    // So if any is forced unlocked, we fail.
    
    for (var u in _selectedUmbrellas) {
      if (!dataService.isHeldBy(u.id, currentUserId)) {
         lostLock = true;
         break;
      }
    }

    if (lostLock) {
       _handleForcedUnlock();
    }
  }

  void _handleForcedUnlock() {
    // Stop timer temporarily or just reset
    // _statusCheckTimer?.cancel(); // Maybe don't cancel, just handle state
    
    // Reset state
    setState(() {
      _selectedUmbrellas.clear();
      // Optional: Go back to prev step? Or stay on map?
      // "receive immediately an ERROR SCREEN".
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Attenzione', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'La sessione di prenotazione per uno o più ombrelloni selezionati è scaduta o è stata interrotta dall\'amministrazione.\n\nPer favore, riprova.'
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               // Ideally refresh map
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('[BookingScreen] Disposing...');
    _statusCheckTimer?.cancel();
    _waveAnimationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final hasCustomBg = dataService.beachBackgroundImage != null;
    final elements = dataService.mapElements
        .where((e) => !hasCustomBg || (e.type != MapElementType.sand && e.type != MapElementType.sea))
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Seleziona Date' : (_currentStep == 1 ? 'Scegli Pacchetto' : 'Scegli Ombrellone'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _currentStep--;
              if (_currentStep == 0) {
                 _selectedUmbrellas.clear();
                 _selectedPackage = null;
              } else if (_currentStep == 1) {
                 _selectedUmbrellas.clear();
              }
            });
          },
        ) : null,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_currentStep == 2)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showLegendDialog(context),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
           child: _buildCurrentStepView(elements, dataService),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(List<MapElement> elements, MockDataService dataService) {
    switch (_currentStep) {
      case 0:
        return _buildDateSelectionView();
      case 1:
        return _buildPackageSelectionView(dataService);
      case 2:
        return _buildMapView(elements, dataService);
      default:
        return _buildDateSelectionView();
    }
  }

  Widget _buildPackageSelectionView(MockDataService dataService) {
    var packages = dataService.packages;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: packages.map((pkg) => _buildPackageCard(pkg)).toList(),
      ),
    );
  }

  Widget _buildPackageCard(ServicePackage pkg) {
    // Inferred info for demo
    String paxInfo = '2 Persone';
    String rowInfo = 'Fila 3+';
    if (pkg.name.toLowerCase().contains('relax') || pkg.name.toLowerCase().contains('vip')) {
       rowInfo = 'Fila 1-2';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackage = pkg;
            _currentStep = 2; // Go to Map
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Uploaded package photo, falls back to a generic beach placeholder.
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: pkg.iconImage != null
                      ? MemoryImage(base64Decode(pkg.iconImage!.split(',').last))
                      : const NetworkImage('https://images.unsplash.com/photo-1544078851-5f780494052f?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.black54,
                  child: Text(
                     pkg.name,
                     style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Description
                  Text(pkg.description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 12),
                  
                  // Info Row: Pax & Position
                  Row(
                    children: [
                      _buildInfoBadge(Icons.people, paxInfo, Colors.orange),
                      const SizedBox(width: 8),
                      _buildInfoBadge(Icons.location_on, rowInfo, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Included Items
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: pkg.items.map((item) => Chip(
                      label: Text(item, style: const TextStyle(fontSize: 10)), 
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade900),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prezzo a partire da', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('€${pkg.defaultBasePrice.toStringAsFixed(0)}', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDateSelectionView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Glass-like card
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Seleziona le Date',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scegli quando vuoi prenotare il tuo ombrellone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Start Date
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.event, color: Colors.blue.shade700)
                ),
                title: const Text('Data Inizio', style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  _selectedStartDate != null
                      ? _formatDate(_selectedStartDate!)
                      : 'Seleziona data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectStartDate(context),
              ),
            ),
            const SizedBox(height: 12),
            
            // End Date
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.event_available, color: Colors.orange.shade700)
                ),
                title: const Text('Data Fine', style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  _selectedEndDate != null
                      ? _formatDate(_selectedEndDate!)
                      : 'Seleziona data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectedStartDate != null
                    ? () => _selectEndDate(context)
                    : null,
              ),
            ),
            
            if (_selectedStartDate != null && _selectedEndDate != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Periodo: ${_calculateDays()} ${_calculateDays() == 1 ? "giorno" : "giorni"}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  debugPrint('[BookingScreen] Dates confirmed: ${_formatDate(_selectedStartDate!)} - ${_formatDate(_selectedEndDate!)}');
                  setState(() {
                    _currentStep = 1; // Proceed to Package Selection
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Procedi (Scegli Pacchetto)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<MapElement> elements, MockDataService dataService) {
    // Filter available umbrellas based on selected dates
    final availableUmbrellas = _getAvailableUmbrellas(dataService);
    
    return Column(
      children: [
        // Date summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Periodo selezionato:', style: TextStyle(fontSize: 12)),
                    Text(
                      '${_formatDate(_selectedStartDate!)} - ${_formatDate(_selectedEndDate!)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${availableUmbrellas.length} disp.',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        // Legend
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.green, 'Disponibile'),
              _buildLegendItem(Colors.red, 'Occupato'),
              _buildLegendItem(Colors.blue, 'Selezionato'),
            ],
          ),
        ),
        
        // Map
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                debugPrint('[BookingScreen] Map size: ${constraints.maxWidth}x${constraints.maxHeight}');
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        BeachBackgroundLayer(backgroundImageDataUrl: dataService.beachBackgroundImage),
                        ...elements.map((e) => _buildMapElementWidget(e, constraints, availableUmbrellas)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Booking button
        if (_selectedUmbrellas.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: () => _confirmBooking(context, dataService),
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Prenota ${_selectedUmbrellas.length} ${_selectedUmbrellas.length == 1 ? "Ombrellone" : "Ombrelloni"}',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  List<MapElement> _getAvailableUmbrellas(MockDataService dataService) {
    // For now, simulate availability check
    // In a real app, this would check bookings for the selected date range
    final umbrellas = dataService.umbrellas;
    
    // Simulate: first 3 umbrellas are occupied, rest are available
    return umbrellas.where((u) => u.status == UmbrellaStatus.available).toList();
  }

  Widget _buildMapElementWidget(
    MapElement element,
    BoxConstraints constraints,
    List<MapElement> availableUmbrellas,
  ) {
    if (element.type != MapElementType.umbrella) {
      return _buildPositionedElement(element, constraints, true, false, false);
    }
  
    final dataService = Provider.of<MockDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id ?? 'guest';

    // Check Status
    final isSelected = _selectedUmbrellas.any((u) => u.id == element.id);
    final isLockedByOther = dataService.isUmbrellaLocked(element.id, currentUserId);
    final isAvailable = !isLockedByOther && 
                        availableUmbrellas.any((u) => u.id == element.id);
    
    return _buildPositionedElement(
      element, 
      constraints, 
      isAvailable, 
      isSelected, 
      isLockedByOther
    );
  }

  Widget _buildPositionedElement(
    MapElement element, 
    BoxConstraints constraints, 
    bool isAvailable, 
    bool isSelected,
    bool isLockedByOther,
  ) {
    return Positioned(
      left: element.x * constraints.maxWidth,
      top: element.y * constraints.maxHeight,
      width: element.width * constraints.maxWidth,
      height: element.height * constraints.maxHeight,
      child: GestureDetector(
        onTap: () {
          if (element.type == MapElementType.umbrella) {
            _handleUmbrellaTap(element, isAvailable, isLockedByOther);
          }
        },
        child: Container(
          decoration: (isSelected && element.type != MapElementType.umbrella)
              ? BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10)
                  ],
                )
              : null,
          child: _buildElementVisualWithTransform(element, isAvailable, isSelected, isLockedByOther),
        ),
      ),
    );
  }

  Widget _buildElementVisualWithTransform(MapElement element, bool isAvailable, bool isSelected, bool isLockedByOther) {
    final matrix = Matrix4.identity();
    
    if (element.rotation != 0) {
      matrix.translate(0.5, 0.5, 0.0);
      matrix.rotateZ(element.rotation * math.pi / 180);
      matrix.translate(-0.5, -0.5, 0.0);
    }
    
    if (element.scaleX != 1.0 || element.scaleY != 1.0) {
      matrix.translate(0.5, 0.5, 0.0);
      matrix.scale(element.scaleX, element.scaleY, 1.0);
      matrix.translate(-0.5, -0.5, 0.0);
    }

    if (element.flipHorizontal || element.flipVertical) {
      matrix.translate(0.5, 0.5, 0.0);
      matrix.scale(
        element.flipHorizontal ? -1.0 : 1.0,
        element.flipVertical ? -1.0 : 1.0,
        1.0,
      );
      matrix.translate(-0.5, -0.5, 0.0);
    }
    
    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: _buildElementVisual(element, isAvailable, isSelected, isLockedByOther),
    );
  }

  Widget _buildElementVisual(MapElement element, bool isAvailable, bool isSelected, bool isLockedByOther) {
    if (element.type == MapElementType.sand) {
      return Container(color: element.color ?? const Color(0xFFE6C288));
    }
    
    if (element.type == MapElementType.sea) {
      return AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) {
          return CustomPaint(
            painter: WavePainter(
              color: element.color ?? const Color(0xFF90CAF9),
              animationValue: _waveAnimationController.value,
            ),
            size: Size.infinite,
          );
        },
      );
    }
    
    if (element.type == MapElementType.umbrella) {
      Color umbrellaColor;
      
      if (isLockedByOther) {
        umbrellaColor = Colors.grey; // LOCKED
      } else if (isSelected) {
        umbrellaColor = Colors.blue;
      } else if (isAvailable) {
        umbrellaColor = Colors.green;
      } else {
        umbrellaColor = Colors.red;
      }

      return Transform.scale(
        scale: 2.0,
        child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2), // Slightly thinner as it gets scaled
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                           BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 4)
                        ],
                      )
                    : null,
                 padding: const EdgeInsets.all(2), // Add padding for the border
                 child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Icon(
                            Icons.beach_access,
                            color: umbrellaColor,
                          ),
                        ),
                      ),
                      if (element.label != null || element.row != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            element.label ?? '${element.row}-${element.number}',
                            style: const TextStyle(
                              fontSize: 5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                    ],
                 ),
              ),
      );
    }
    
    if (element.type == MapElementType.sunbed) {
      return CustomPaint(painter: SunbedPainter(color: element.color ?? Colors.orange));
    }
    
    if (element.type == MapElementType.walkway) {
      return CustomPaint(painter: WalkwayPainter(color: element.color ?? const Color(0xFF8D6E63)));
    }

    if (element.type == MapElementType.zone) {
      return CustomPaint(
        painter: ZonePainter(
          borderColor: element.borderColor,
          borderWidth: element.borderWidth,
          fillColor: element.fillColor,
          fillOpacity: element.fillOpacity,
          title: element.zoneTitle,
          customPath: element.customPath,
        ),
      );
    }
    
    // Default icon for other types
    IconData iconData = Icons.circle;
    switch (element.type) {
      case MapElementType.bar:
        iconData = Icons.local_bar;
        break;
      case MapElementType.restaurant:
        iconData = Icons.restaurant;
        break;
      case MapElementType.wc:
        iconData = Icons.wc;
        break;
      case MapElementType.shower:
        iconData = Icons.shower;
        break;
      case MapElementType.cabin:
        iconData = Icons.door_sliding;
        break;
      case MapElementType.palm:
        iconData = Icons.nature;
        break;
      case MapElementType.bench:
        iconData = Icons.chair;
        break;
      default:
        iconData = Icons.circle;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 20, color: element.color ?? Colors.black),
    );
  }

  void _handleUmbrellaTap(MapElement umbrella, bool isAvailable, bool isLockedByOther) {
    debugPrint('[BookingScreen] Umbrella tapped: ${umbrella.id}, available: $isAvailable, locked: $isLockedByOther');
    
    if (isLockedByOther) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questo ombrellone è momentaneamente bloccato da un altro utente.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questo ombrellone non è disponibile per le date selezionate.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dataService = Provider.of<MockDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? 'guest';

    if (_selectedUmbrellas.any((u) => u.id == umbrella.id)) {
      dataService.unlockUmbrella(umbrella.id);
      setState(() => _selectedUmbrellas.removeWhere((u) => u.id == umbrella.id));
      return;
    }

    // Hold the spot for the duration of browsing/checkout — the periodic
    // _checkLockStatus() below assumes every selected umbrella is actually
    // locked by this user, so selection and locking must happen together
    // (previously selection didn't lock at all, so the 2-second status
    // check always found no lock and force-cleared the selection).
    if (!dataService.lockUmbrella(umbrella.id, userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questo ombrellone è appena stato bloccato da un altro utente.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() => _selectedUmbrellas.add(umbrella));
  }


  void _confirmBooking(BuildContext context, MockDataService dataService) async {
    debugPrint('[BookingScreen] Confirming booking for ${_selectedUmbrellas.length} umbrellas');

    // 1. Attempt to LOCK all selected umbrellas
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? 'guest';
    final List<String> lockedIds = [];
    bool allLocked = true;

    for (final umbrella in _selectedUmbrellas) {
      final success = dataService.lockUmbrella(umbrella.id, userId);
      if (success) {
        lockedIds.add(umbrella.id);
      } else {
        allLocked = false;
        break;
      }
    }

    if (!allLocked) {
      // Rollback locks
      dataService.unlockMultipleUmbrellas(lockedIds);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uno o più ombrelloni selezionati non sono più disponibili.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        // Refresh or clear selection?
        // Maybe keeping it allows user to deselect the bad one?
        // But we don't know which one failed easily here without better return.
        // For now, clear selection to force refresh
        _selectedUmbrellas.clear(); 
      });
      return;
    }

    // 2. Proceed to Recap Dialog
    final nameController = TextEditingController();

    // First ask for customer name
    await showDialog(
      context: context,
      barrierDismissible: false, // Force decision
      builder: (context) => AlertDialog(
        title: const Text('Nome Cliente'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Il tuo nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context); // Close name dialog
               // Cleanup locks if user cancels here
               dataService.unlockMultipleUmbrellas(lockedIds);
            },
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                // Show detailed recap dialog
                _showRecapDialog(context, nameController.text, _selectedPackage?.id ?? '', lockedIds);
              }
            },
            child: const Text('Continua'),
          ),
        ],
      ),
    );
  }

  void _showRecapDialog(BuildContext context, String customerName, String packageId, List<String> lockedIds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingRecapDialog(
        umbrellas: _selectedUmbrellas.toList(),
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
        selectedPackageId: packageId,
        customerName: customerName,
      ),
    ).then((result) {
      if (result != null && result is Map) {
        // Success
        _showSuccessDialog(context, result);
      } else {
        // Cancelled or Timeout or Error without booking
        // Unlock (Safe to call even if already unlocked by timeout)
        Provider.of<MockDataService>(context, listen: false).unlockMultipleUmbrellas(lockedIds);
      }
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    debugPrint('[BookingScreen] Opening start date picker');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      debugPrint('[BookingScreen] Start date selected: ${_formatDate(picked)}');
      setState(() {
        _selectedStartDate = picked;
        // Reset end date if it's before start date
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
          _selectedEndDate = null;
        }
      });
    }
  }

  void _showSuccessDialog(BuildContext context, Map result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingSuccessDialog(
        bookingIds: (result['bookingIds'] as List?)?.cast<String>(),
      ),
    ).then((_) {
       setState(() {
         _selectedUmbrellas.clear();
         _selectedStartDate = null;
         _selectedEndDate = null;
         _selectedPackage = null;
         _currentStep = 0; // Go back to start
       });
    });
  }

  Future<void> _selectEndDate(BuildContext context) async {
    debugPrint('[BookingScreen] Opening end date picker');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate!.add(const Duration(days: 1)),
      firstDate: _selectedStartDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      debugPrint('[BookingScreen] End date selected: ${_formatDate(picked)}');
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    // Helper to format date consistent with locale
    // We already moved intl initialization to main, but here we can just do simple format
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateDays() {
    if (_selectedStartDate == null || _selectedEndDate == null) return 0;
    return _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
  }


  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 20, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legenda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.green, 'Disponibile'),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.red, 'Occupato'),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.blue, 'Selezionato'),
          ],
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
