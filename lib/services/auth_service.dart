import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'firebase_sync_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get canManageProjects => _currentUser?.role.canManageProjects ?? false;
  bool get canViewTeamDashboard =>
      _currentUser?.role.canViewTeamDashboard ?? false;

  static const String _currentUserKey = 'current_user';
  static const String _usersKey = 'users';

  Future<void> initialize() async {
    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_firebaseSync.isEnabled) {
        await _hydrateUsersFromFirebase(prefs);
      }

      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
      }

      await _createDefaultAdminIfNeeded(prefs);
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      var users = await _loadUsersFromPrefs(prefs);

      if (users.isEmpty && _firebaseSync.isEnabled) {
        await _hydrateUsersFromFirebase(prefs);
        users = await _loadUsersFromPrefs(prefs);
      }

      final user = users.firstWhere(
        (u) => u.email == email && u.isActive,
        orElse: () => throw Exception('User not found'),
      );

      _currentUser = user;
      await prefs.setString(_currentUserKey, json.encode(user.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String name,
    required String surname,
    required String password,
    DeveloperType? developerType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final users = await _loadUsersFromPrefs(prefs);

      if (users.any((u) => u.email == email)) {
        throw Exception('Email already exists');
      }

      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        surname: surname,
        role: UserRole.employee,
        developerType: developerType,
        createdAt: DateTime.now(),
      );

      users.add(newUser);
      await prefs.setString(
        _usersKey,
        json.encode(users.map((u) => u.toJson()).toList()),
      );

      if (_firebaseSync.isEnabled) {
        await _firebaseSync.upsertUser(newUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    notifyListeners();
  }

  Future<void> _hydrateUsersFromFirebase(SharedPreferences prefs) async {
    try {
      final remoteUsers = await _firebaseSync.fetchUsers();
      if (remoteUsers.isNotEmpty) {
        await prefs.setString(
          _usersKey,
          json.encode(remoteUsers.map((u) => u.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('Firebase users hydration error: $e');
    }
  }

  Future<void> _createDefaultAdminIfNeeded(SharedPreferences prefs) async {
    final users = await _loadUsersFromPrefs(prefs);
    if (users.isNotEmpty) {
      return;
    }

    final admin = User(
      id: 'admin_001',
      email: 'admin@iris.com',
      name: 'Admin',
      surname: 'IRIS',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );

    final updatedUsers = [admin];
    await prefs.setString(
      _usersKey,
      json.encode(updatedUsers.map((u) => u.toJson()).toList()),
    );

    if (_firebaseSync.isEnabled) {
      await _firebaseSync.upsertUser(admin);
    }
  }

  Future<List<User>> _loadUsersFromPrefs(SharedPreferences prefs) async {
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = json.decode(usersJson);
    return usersList.map((u) => User.fromJson(u)).toList();
  }
}
