import '../models/restaurant_model.dart';

enum RestaurantActionType { add, remove, update, batch }

class RestaurantMapAction {
  final RestaurantActionType type;
  final RestaurantTable? table; // add/remove: the table; update: the AFTER-state
  final RestaurantTable? previousState; // update: the BEFORE-state
  final List<RestaurantMapAction>? batch; // batch: an ordered list of sub-actions

  RestaurantMapAction({required this.type, this.table, this.previousState, this.batch});
}

/// Mirrors [UndoRedoManager] (beach editor): add/remove/update (move, resize,
/// shape, seats, zone) plus batch actions for multi-select operations.
class RestaurantUndoRedoManager {
  final List<RestaurantMapAction> _undoStack = [];
  final List<RestaurantMapAction> _redoStack = [];
  final int maxStackSize;

  RestaurantUndoRedoManager({this.maxStackSize = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void recordAction(RestaurantMapAction action) {
    _undoStack.add(action);
    if (_undoStack.length > maxStackSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  RestaurantMapAction? undo() {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    return action;
  }

  RestaurantMapAction? redo() {
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
