import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/project_model.dart';
import '../models/timesheet_entry.dart';
import '../models/user_model.dart';
import 'firebase_bootstrap_service.dart';

class FirebaseSyncService {
  bool get isEnabled => FirebaseBootstrapService.instance.isReady;

  FirebaseFirestore? _safeFirestore() {
    if (!isEnabled) {
      return null;
    }

    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore non disponibile (fallback locale): $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _usersRef(FirebaseFirestore db) =>
      db.collection('users');
  CollectionReference<Map<String, dynamic>>? _projectsRef(
    FirebaseFirestore db,
  ) => db.collection('projects');
  CollectionReference<Map<String, dynamic>>? _entriesRef(
    FirebaseFirestore db,
  ) => db.collection('timesheet_entries');

  Future<List<User>> fetchUsers() async {
    final db = _safeFirestore();
    if (db == null) {
      return [];
    }

    try {
      final snapshot = await _usersRef(db)!.get();
      return snapshot.docs
          .map((doc) => User.fromJson(Map<String, dynamic>.from(doc.data())))
          .toList();
    } catch (e) {
      debugPrint('Errore fetchUsers Firebase: $e');
      return [];
    }
  }

  Future<User?> fetchUserById(String userId) async {
    final db = _safeFirestore();
    if (db == null) {
      return null;
    }

    try {
      final doc = await _usersRef(db)!.doc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return User.fromJson(Map<String, dynamic>.from(doc.data()!));
    } catch (e) {
      debugPrint('Errore fetchUserById Firebase: $e');
      return null;
    }
  }

  Future<User?> fetchUserByEmail(String email) async {
    final db = _safeFirestore();
    if (db == null) {
      return null;
    }

    try {
      final normalized = email.trim().toLowerCase();

      final normalizedSnapshot = await _usersRef(
        db,
      )!.where('email', isEqualTo: normalized).limit(1).get();
      if (normalizedSnapshot.docs.isNotEmpty) {
        return User.fromJson(
          Map<String, dynamic>.from(normalizedSnapshot.docs.first.data()),
        );
      }

      final rawSnapshot = await _usersRef(
        db,
      )!.where('email', isEqualTo: email.trim()).limit(1).get();
      if (rawSnapshot.docs.isEmpty) {
        return null;
      }
      return User.fromJson(
        Map<String, dynamic>.from(rawSnapshot.docs.first.data()),
      );
    } catch (e) {
      debugPrint('Errore fetchUserByEmail Firebase: $e');
      return null;
    }
  }

  Future<List<Project>> fetchProjects() async {
    final db = _safeFirestore();
    if (db == null) {
      return [];
    }

    try {
      final snapshot = await _projectsRef(db)!.get();
      return snapshot.docs
          .map((doc) => Project.fromJson(Map<String, dynamic>.from(doc.data())))
          .toList();
    } catch (e) {
      debugPrint('Errore fetchProjects Firebase: $e');
      return [];
    }
  }

  Future<List<TimesheetEntry>> fetchTimesheetEntries() async {
    final db = _safeFirestore();
    if (db == null) {
      return [];
    }

    try {
      final snapshot = await _entriesRef(db)!.get();
      return snapshot.docs
          .map(
            (doc) =>
                TimesheetEntry.fromJson(Map<String, dynamic>.from(doc.data())),
          )
          .toList();
    } catch (e) {
      debugPrint('Errore fetchTimesheetEntries Firebase: $e');
      return [];
    }
  }

  Future<void> upsertUser(User user) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    await _usersRef(
      db,
    )!.doc(user.id).set(user.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteUser(String userId) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    await _usersRef(db)!.doc(userId).delete();
  }

  Future<void> upsertProject(Project project) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    await _projectsRef(
      db,
    )!.doc(project.id).set(project.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteProject(String projectId) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    await _projectsRef(db)!.doc(projectId).delete();
  }

  Future<void> upsertTimesheetEntry(TimesheetEntry entry) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    await _entriesRef(
      db,
    )!.doc(entry.id).set(entry.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteTimesheetEntry(String entryId) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    await _entriesRef(db)!.doc(entryId).delete();
  }

  Future<void> syncUsers(List<User> users) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    final batch = db.batch();
    final usersRef = _usersRef(db)!;
    for (final user in users) {
      batch.set(usersRef.doc(user.id), user.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> syncProjects(List<Project> projects) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    final batch = db.batch();
    final projectsRef = _projectsRef(db)!;
    for (final project in projects) {
      batch.set(
        projectsRef.doc(project.id),
        project.toJson(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> syncTimesheetEntries(List<TimesheetEntry> entries) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    final batch = db.batch();
    final entriesRef = _entriesRef(db)!;
    for (final entry in entries) {
      batch.set(
        entriesRef.doc(entry.id),
        entry.toJson(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
