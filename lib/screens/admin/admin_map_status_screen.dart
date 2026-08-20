import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
// Ensure this matches User screen imports

class AdminMapStatusMonitorScreen extends StatefulWidget {
  const AdminMapStatusMonitorScreen({super.key});

  @override
  State<AdminMapStatusMonitorScreen> createState() => _AdminMapStatusMonitorScreenState();
}

class _AdminMapStatusMonitorScreenState extends State<AdminMapStatusMonitorScreen> {
  // Use a transformation controller for the InteractiveViewer
  final TransformationController _transformationController = TransformationController();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final elements = dataService.mapElements;
    final allLocks = dataService.allLocks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoraggio Mappa'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: () {
               setState(() {});
             },
           )
        ],
      ),
      body: Column(
        children: [
          // Legend / Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                 const Icon(Icons.info_outline, color: Colors.blue),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     'Tocca un ombrellone GRIGIO (Bloccato) per sbloccarlo forzatamente.',
                     style: TextStyle(color: Colors.grey.shade800),
                   ),
                 ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              color: Colors.blue.shade50.withOpacity(0.3), // Light background
              child: LayoutBuilder(
                builder: (context, constraints) {
                   return InteractiveViewer(
                     transformationController: _transformationController,
                     minScale: 0.5,
                     maxScale: 4.0,
                     boundaryMargin: const EdgeInsets.all(double.infinity),
                     child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: Stack(
                          children: elements.map((e) => _buildAdminMapElement(e, constraints, dataService)).toList(),
                        ),
                     ),
                   );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMapElement(MapElement element, BoxConstraints constraints, MockDataService dataService) {
    if (element.type != MapElementType.umbrella) {
       // Render static elements same as user view (simplified)
       return _buildPositionedElement(element, constraints, false, false, false, Colors.transparent, () {});
    }

    final locks = dataService.allLocks;
    final bookings = dataService.bookings;
    
    // Check status
    bool isLocked = locks.any((l) => l.umbrellaId == element.id);
    bool isBooked = bookings.any((b) => b.umbrellaId == element.id && 
                      // Simple check: is booked today or future?
                      // For monitor purposes, let's assume we look at "Now"
                      b.startDate.isBefore(DateTime.now().add(const Duration(days: 1))) && 
                      b.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))
                    );
    
    // Determine Color
    Color color = Colors.green; // Available
    if (isBooked) {
      color = Colors.red; // Booked
    } else if (isLocked) {
      color = Colors.grey; // Locked (Pending)
    }

    return _buildPositionedElement(
      element, 
      constraints, 
      true, // Interactive
      isLocked, // specialized styling?
      false, // isSelected (not relevant for admin)
      color,
      () => _handleAdminTap(element, isLocked, isBooked, dataService),
    );
  }

  Widget _buildPositionedElement(
    MapElement element, 
    BoxConstraints constraints, 
    bool interactive,
    bool isLocked,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return Positioned(
      left: element.x * constraints.maxWidth,
      top: element.y * constraints.maxHeight,
      width: element.width * constraints.maxWidth,
      height: element.height * constraints.maxHeight,
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        child: _buildElementVisual(element, color, isLocked),
      ),
    );
  }

  Widget _buildElementVisual(MapElement element, Color color, bool isLocked) {
    if (element.type == MapElementType.umbrella) {
       return Container(
         decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.8),
           shape: BoxShape.circle,
           border: Border.all(
             color: color, 
             width: isLocked ? 4 : 2 // Thick border for locked
           ), 
           boxShadow: isLocked ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
         ),
         child: Icon(Icons.beach_access, color: color, size: 20),
       );
    }
    // Simple fallback for other elements
    if (element.type == MapElementType.sea) return Container(color: Colors.blue.withOpacity(0.3));
    if (element.type == MapElementType.sand) return Container(color: const Color(0xFFE6C288));
    
    return Container(); // Invisible for others
  }

  void _handleAdminTap(MapElement element, bool isLocked, bool isBooked, MockDataService dataService) {
    if (isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postazione già prenotata e pagata.')));
      return;
    }

    if (isLocked) {
      // Find who locked it
      final lock = dataService.allLocks.firstWhere((l) => l.umbrellaId == element.id);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sblocco Forzato'),
          content: Text('L\'ombrellone ${element.label ?? "${element.row}-${element.number}"} è bloccato dall\'utente ID: ${lock.userId}.\n\nVuoi sbloccarlo forzatamente?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                dataService.unlockUmbrella(element.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ombrellone sbloccato!')));
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('SBLOCCA'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postazione libera.')));
    }
  }
}
