import '../models/beach_model.dart';

enum ActionType { add, remove, update, batch }

class MapAction {
  final ActionType type;
  final MapElement? element; // add/remove: the element; update: the AFTER-state
  final MapElement? previousState; // update: the BEFORE-state
  final List<MapAction>? batch; // batch: an ordered list of sub-actions

  MapAction({
    required this.type,
    this.element,
    this.previousState,
    this.batch,
  });
}

class UndoRedoManager {
  final List<MapAction> _undoStack = [];
  final List<MapAction> _redoStack = [];
  final int maxStackSize;

  UndoRedoManager({this.maxStackSize = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void recordAction(MapAction action) {
    _undoStack.add(action);
    if (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }
    // Clear redo stack when new action is performed
    _redoStack.clear();
  }

  MapAction? undo() {
    if (_undoStack.isEmpty) return null;
    
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    return action;
  }

  MapAction? redo() {
    if (_redoStack.isEmpty) return null;
    
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    return action;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
