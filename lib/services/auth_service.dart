import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'firebase_sync_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _lastError;
  StreamSubscription<User?>? _profileSubscription;

  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isFirebaseMode => _firebaseSync.isEnabled;
  bool get canManageProjects => _currentUser?.role.canManageProjects ?? false;
  bool get canViewTeamDashboard =>
      _currentUser?.role.canViewTeamDashboard ?? false;
  String? get lastError => _lastError;

  static const String _currentUserKey = 'current_user';
  static const String _usersKey = 'users';

  Future<void> initialize() async {
    _isLoading = true;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_firebaseSync.isEnabled) {
        await _hydrateUsersFromFirebase(prefs);
        final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;

        if (firebaseUser != null) {
          final profile = await _resolveOrCreateFirebaseProfile(firebaseUser);
          _currentUser = profile;
          _startCurrentUserProfileSync(firebaseUser.uid);

          if (profile != null) {
            await prefs.setString(
              _currentUserKey,
              json.encode(profile.toJson()),
            );
          } else {
            await prefs.remove(_currentUserKey);
          }
        } else {
          _cancelCurrentUserProfileSync();
          _currentUser = null;
          await prefs.remove(_currentUserKey);
        }
      } else {
        _cancelCurrentUserProfileSync();
        final userJson = prefs.getString(_currentUserKey);
        if (userJson != null) {
          _currentUser = User.fromJson(json.decode(userJson));
        }
        await _createDefaultAdminIfNeeded(prefs);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      if (_firebaseSync.isEnabled) {
        final credential = await fb_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw Exception('Firebase user non disponibile');
        }

        final profile = await _resolveOrCreateFirebaseProfile(firebaseUser);
        if (profile == null || !profile.isActive) {
          await fb_auth.FirebaseAuth.instance.signOut();
          _lastError = 'Account non attivo o profilo non configurato.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = profile;
        _startCurrentUserProfileSync(firebaseUser.uid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentUserKey, json.encode(profile.toJson()));
        await _hydrateUsersFromFirebase(prefs);
      } else {
        final prefs = await SharedPreferences.getInstance();
        var users = await _loadUsersFromPrefs(prefs);

        if (users.isEmpty && _firebaseSync.isEnabled) {
          await _hydrateUsersFromFirebase(prefs);
          users = await _loadUsersFromPrefs(prefs);
        }

        final matchingUsers = users
            .where(
              (u) => u.email.toLowerCase() == normalizedEmail && u.isActive,
            )
            .toList();
        if (matchingUsers.isEmpty) {
          _lastError =
              'Utente non trovato in locale. Se sei su web, configura Firebase o registrati da questa app.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final user = matchingUsers.first;

        _currentUser = user;
        await prefs.setString(_currentUserKey, json.encode(user.toJson()));
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _lastError = _friendlyAuthError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Firebase login error: $e');
      return false;
    } catch (e) {
      _lastError = 'Email o password non corretti';
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
    _lastError = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      if (_firebaseSync.isEnabled) {
        final credential = await fb_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw Exception('Firebase user non disponibile in registrazione');
        }

        final profile = await _resolveOrCreateFirebaseProfile(
          firebaseUser,
          suggestedName: name,
          suggestedSurname: surname,
          suggestedDeveloperType: developerType,
        );

        if (profile == null) {
          throw Exception('Profilo utente non creato');
        }

        if (!profile.isActive) {
          throw Exception('Account disattivato');
        }

        final prefs = await SharedPreferences.getInstance();
        await _hydrateUsersFromFirebase(prefs);

        // Manteniamo UX attuale: dopo registrazione, login esplicito.
        await fb_auth.FirebaseAuth.instance.signOut();
        _currentUser = null;
        await prefs.remove(_currentUserKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final users = await _loadUsersFromPrefs(prefs);

        if (users.any((u) => u.email.toLowerCase() == normalizedEmail)) {
          throw Exception('Email already exists');
        }

        final newUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: normalizedEmail,
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
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _lastError = _friendlyAuthError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Firebase register error: $e');
      return false;
    } catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _cancelCurrentUserProfileSync();
    _currentUser = null;

    try {
      if (_firebaseSync.isEnabled) {
        await fb_auth.FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('Logout Firebase error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    notifyListeners();
  }

  Future<void> refreshCurrentUserFromRemote() async {
    if (!_firebaseSync.isEnabled) {
      return;
    }

    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return;
    }

    final profile = await _resolveOrCreateFirebaseProfile(firebaseUser);
    if (profile == null) {
      return;
    }

    _currentUser = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(profile.toJson()));
    notifyListeners();
  }

  Future<User?> _resolveOrCreateFirebaseProfile(
    fb_auth.User firebaseUser, {
    String? suggestedName,
    String? suggestedSurname,
    DeveloperType? suggestedDeveloperType,
  }) async {
    final normalizedEmail = (firebaseUser.email ?? '').trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    var profile = await _firebaseSync.fetchUserById(firebaseUser.uid);

    if (profile == null) {
      final byEmail = await _firebaseSync.fetchUserByEmail(normalizedEmail);
      if (byEmail != null && byEmail.id != firebaseUser.uid) {
        final oldId = byEmail.id;
        final oldEmail = byEmail.email;
        profile = byEmail.copyWith(
          id: firebaseUser.uid,
          email: normalizedEmail,
          name: suggestedName?.trim().isNotEmpty == true
              ? suggestedName!.trim()
              : byEmail.name,
          surname: suggestedSurname?.trim().isNotEmpty == true
              ? suggestedSurname!.trim()
              : byEmail.surname,
          developerType: suggestedDeveloperType ?? byEmail.developerType,
        );
        await _firebaseSync.upsertUser(profile);
        await _firebaseSync.migrateUserReferences(
          oldUserId: oldId,
          newUserId: firebaseUser.uid,
          oldEmail: oldEmail,
          newEmail: normalizedEmail,
        );
        await _firebaseSync.deleteUser(oldId);
      }
    }

    if (profile == null) {
      final fallbackName =
          _firstNameFromDisplayName(firebaseUser.displayName) ??
          suggestedName?.trim() ??
          _nameFromEmail(normalizedEmail);
      final fallbackSurname =
          _lastNameFromDisplayName(firebaseUser.displayName) ??
          suggestedSurname?.trim() ??
          'User';

      profile = User(
        id: firebaseUser.uid,
        email: normalizedEmail,
        name: fallbackName,
        surname: fallbackSurname,
        role: UserRole.employee,
        developerType: suggestedDeveloperType,
        createdAt: DateTime.now(),
      );
      await _firebaseSync.upsertUser(profile);
    } else if (profile.email.toLowerCase() != normalizedEmail) {
      profile = profile.copyWith(email: normalizedEmail);
      await _firebaseSync.upsertUser(profile);
    }

    return profile;
  }

  void _startCurrentUserProfileSync(String uid) {
    _cancelCurrentUserProfileSync();
    _profileSubscription = _firebaseSync
        .watchUserById(uid)
        .listen(
          (user) async {
            if (user == null) {
              return;
            }
            _currentUser = user;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_currentUserKey, json.encode(user.toJson()));
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Current user realtime sync error: $error');
          },
        );
  }

  void _cancelCurrentUserProfileSync() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
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

  String _friendlyAuthError(fb_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o password non corretti';
      case 'email-already-in-use':
        return 'Questa email è già registrata';
      case 'weak-password':
        return 'La password è troppo debole';
      case 'invalid-email':
        return 'Email non valida';
      case 'network-request-failed':
        return 'Connessione assente. Riprova.';
      default:
        return error.message ?? 'Errore autenticazione';
    }
  }

  String _nameFromEmail(String email) {
    final prefix = email.split('@').first;
    if (prefix.isEmpty) {
      return 'User';
    }
    return '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  }

  String? _firstNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return null;
    }
    return displayName.trim().split(' ').first;
  }

  String? _lastNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return null;
    }
    final parts = displayName.trim().split(' ');
    if (parts.length < 2) {
      return null;
    }
    return parts.sublist(1).join(' ');
  }

  @override
  void dispose() {
    _cancelCurrentUserProfileSync();
    super.dispose();
  }
}
