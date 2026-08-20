import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';

class BeachMapEditor extends StatefulWidget {
  const BeachMapEditor({super.key});

  @override
  State<BeachMapEditor> createState() => _BeachMapEditorState();
}

class _BeachMapEditorState extends State<BeachMapEditor> {
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final umbrellas = dataService.umbrellas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Mappa Spiaggia (Legacy)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mappa salvata!')),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(color: Colors.yellow.shade50),
              
              ...umbrellas.map((umbrella) {
                return Positioned(
                  left: umbrella.x * constraints.maxWidth,
                  top: umbrella.y * constraints.maxHeight,
                  child: Draggable<MapElement>(
                    data: umbrella,
                    feedback: _buildUmbrellaIcon(umbrella, 1.2),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: _buildUmbrellaIcon(umbrella, 1.0),
                    ),
                    onDragEnd: (details) {},
                    child: _buildUmbrellaIcon(umbrella, 1.0),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usa il nuovo Editor Mappa 2.0 per aggiungere elementi!'),
              duration: Duration(seconds: 3),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUmbrellaIcon(MapElement umbrella, double scale) {
    return Transform.scale(
      scale: scale,
      child: Column(
        children: [
          const Icon(Icons.beach_access, size: 40, color: Colors.blue),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              '${umbrella.row}-${umbrella.number}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
