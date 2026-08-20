import 'package:flutter/material.dart';

/// A customer only ever browses/books; a beach or restaurant manager gets
/// routed straight into (and confined to) their own admin section — see the
/// role-based redirect in main.dart and the role-conditional sidebar in
/// AdminScaffold.
enum UserRole { customer, beachManager, restaurantManager }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.customer,
  });
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  final List<User> _users = [];

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Demo accounts: one per side of the app, so each manager only ever
    // sees their own admin section (see main.dart's role-based redirect).
    _users.add(User(
      id: 'demo_user',
      email: 'demo@beach.com',
      name: 'Demo User',
      role: UserRole.beachManager,
    ));
    _users.add(User(
      id: 'demo_restaurant_manager',
      email: 'ristorante@beach.com',
      name: 'Gestore Ristorante',
      role: UserRole.restaurantManager,
    ));
  }

  Future<bool> login(String email, String password) async {
    // Mock login - in production, this would call an API
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => User(id: '', email: '', name: ''),
    );

    if (user.id.isNotEmpty) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    // Mock registration - in production, this would call an API
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user already exists
    final existingUser = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => User(id: '', email: '', name: ''),
    );

    if (existingUser.id.isNotEmpty) {
      return false; // User already exists
    }

    // Create new user
    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
    );

    _users.add(newUser);
    _currentUser = newUser;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
