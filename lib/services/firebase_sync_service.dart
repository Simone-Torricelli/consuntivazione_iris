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
      return snapshot.docs.map(_parseUserDoc).whereType<User>().toList();
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
      return _parseUserDoc(doc);
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
        return _parseUserDoc(normalizedSnapshot.docs.first);
      }

      final rawSnapshot = await _usersRef(
        db,
      )!.where('email', isEqualTo: email.trim()).limit(1).get();
      if (rawSnapshot.docs.isEmpty) {
        return null;
      }
      return _parseUserDoc(rawSnapshot.docs.first);
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
      return snapshot.docs.map(_parseProjectDoc).whereType<Project>().toList();
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
          .map(_parseTimesheetDoc)
          .whereType<TimesheetEntry>()
          .toList();
    } catch (e) {
      debugPrint('Errore fetchTimesheetEntries Firebase: $e');
      return [];
    }
  }

  Stream<List<User>> watchUsers() {
    final db = _safeFirestore();
    if (db == null) {
      return const Stream<List<User>>.empty();
    }

    return _usersRef(db)!.snapshots().map(
      (snapshot) => snapshot.docs.map(_parseUserDoc).whereType<User>().toList(),
    );
  }

  Stream<List<Project>> watchProjects() {
    final db = _safeFirestore();
    if (db == null) {
      return const Stream<List<Project>>.empty();
    }

    return _projectsRef(db)!.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(_parseProjectDoc).whereType<Project>().toList(),
    );
  }

  Stream<User?> watchUserById(String userId) {
    final db = _safeFirestore();
    if (db == null) {
      return const Stream<User?>.empty();
    }

    return _usersRef(db)!.doc(userId).snapshots().map(_parseUserDoc);
  }

  Stream<List<TimesheetEntry>> watchTimesheetEntries() {
    final db = _safeFirestore();
    if (db == null) {
      return const Stream<List<TimesheetEntry>>.empty();
    }

    return _entriesRef(db)!.snapshots().map(
      (snapshot) => snapshot.docs
          .map(_parseTimesheetDoc)
          .whereType<TimesheetEntry>()
          .toList(),
    );
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

  Future<void> migrateUserReferences({
    required String oldUserId,
    required String newUserId,
    String? oldEmail,
    String? newEmail,
  }) async {
    final db = _safeFirestore();
    if (db == null) {
      return;
    }

    if (oldUserId == newUserId) {
      return;
    }

    final oldValues = <String>{
      oldUserId.trim(),
      if (oldEmail != null && oldEmail.trim().isNotEmpty) oldEmail.trim(),
    };
    final normalizedOldValues = oldValues.map((v) => v.toLowerCase()).toSet();
    final normalizedNewEmail = newEmail?.trim().toLowerCase();

    Future<void> updateUsersField(String field) async {
      for (final rawValue in oldValues) {
        final value = rawValue.trim();
        if (value.isEmpty) {
          continue;
        }
        final snap = await _usersRef(db)!.where(field, isEqualTo: value).get();
        for (final doc in snap.docs) {
          await doc.reference.set({field: newUserId}, SetOptions(merge: true));
        }
      }
    }

    Future<void> updateProjectsOwner() async {
      for (final rawValue in oldValues) {
        final value = rawValue.trim();
        if (value.isEmpty) {
          continue;
        }
        final snap = await _projectsRef(
          db,
        )!.where('ownerUserId', isEqualTo: value).get();
        for (final doc in snap.docs) {
          await doc.reference.set({
            'ownerUserId': newUserId,
          }, SetOptions(merge: true));
        }
      }
    }

    Future<void> updateProjectsAssigned() async {
      final processedIds = <String>{};
      for (final rawValue in oldValues) {
        final value = rawValue.trim();
        if (value.isEmpty) {
          continue;
        }
        final snap = await _projectsRef(
          db,
        )!.where('assignedUserIds', arrayContains: value).get();
        for (final doc in snap.docs) {
          if (!processedIds.add(doc.id)) {
            continue;
          }
          final map = Map<String, dynamic>.from(doc.data());
          final list = (map['assignedUserIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
          final updated = <String>[];
          var inserted = false;
          for (final item in list) {
            final normalized = item.trim().toLowerCase();
            if (normalizedOldValues.contains(normalized)) {
              if (!inserted) {
                updated.add(newUserId);
                inserted = true;
              }
            } else {
              updated.add(item);
            }
          }
          if (!inserted) {
            updated.add(newUserId);
          }
          await doc.reference.set({
            'assignedUserIds': updated.toSet().toList(),
          }, SetOptions(merge: true));
        }
      }
    }

    Future<void> updateTimesheetsUser() async {
      for (final rawValue in oldValues) {
        final value = rawValue.trim();
        if (value.isEmpty) {
          continue;
        }
        final snap = await _entriesRef(
          db,
        )!.where('userId', isEqualTo: value).get();
        for (final doc in snap.docs) {
          await doc.reference.set({
            'userId': newUserId,
          }, SetOptions(merge: true));
        }
      }
    }

    await updateUsersField('teamLeadId');
    await updateUsersField('managerId');
    await updateProjectsOwner();
    await updateProjectsAssigned();
    await updateTimesheetsUser();

    // Normalize email references on users if they still point to old email.
    if (normalizedNewEmail != null && normalizedNewEmail.isNotEmpty) {
      for (final field in const ['teamLeadId', 'managerId']) {
        final snap = await _usersRef(
          db,
        )!.where(field, isEqualTo: normalizedNewEmail).get();
        for (final doc in snap.docs) {
          await doc.reference.set({field: newUserId}, SetOptions(merge: true));
        }
      }
    }
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

  User? _parseUserDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(data);
      map['id'] = (map['id'] ?? doc.id).toString();
      map['email'] =
          _pickFirstString(map, const [
            'email',
            'mail',
            'userEmail',
          ])?.trim().toLowerCase() ??
          '';
      map['name'] = (map['name'] ?? '').toString();
      map['surname'] = (map['surname'] ?? '').toString();
      map['role'] = _normalizeUserRole(
        map['role'] ?? map['ruolo'] ?? map['userRole'],
      );
      map['developerType'] = _normalizeDeveloperType(map['developerType']);
      map['managerId'] = _pickFirstString(map, const [
        'managerId',
        'managerID',
        'manager_id',
      ]);
      map['teamLeadId'] = _pickFirstString(map, const [
        'teamLeadId',
        'teamLeadID',
        'team_lead_id',
        'teamLeaderId',
        'teamleaderid',
        'tlId',
        'tl_id',
      ]);
      map['isActive'] = map['isActive'] is bool ? map['isActive'] : true;
      map['createdAt'] = _toIsoString(map['createdAt']) ?? _nowIso();
      return User.fromJson(map);
    } catch (e) {
      debugPrint('Skip user doc non valido (${doc.id}): $e');
      return null;
    }
  }

  Project? _parseProjectDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(data);
      map['id'] = (map['id'] ?? doc.id).toString();
      map['name'] = (map['name'] ?? '').toString();
      map['description'] = (map['description'] ?? '').toString();
      map['color'] = (map['color'] ?? '#1D4ED8').toString();
      map['ownerUserId'] = map['ownerUserId']?.toString();
      map['isActive'] = map['isActive'] is bool ? map['isActive'] : true;
      map['createdAt'] = _toIsoString(map['createdAt']) ?? _nowIso();
      final assigned = map['assignedUserIds'];
      if (assigned is List) {
        map['assignedUserIds'] = assigned.map((e) => e.toString()).toList();
      } else {
        map['assignedUserIds'] = <String>[];
      }
      return Project.fromJson(map);
    } catch (e) {
      debugPrint('Skip project doc non valido (${doc.id}): $e');
      return null;
    }
  }

  TimesheetEntry? _parseTimesheetDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(data);
      map['id'] = (map['id'] ?? doc.id).toString();
      map['userId'] = (map['userId'] ?? map['uid'] ?? '').toString();
      map['projectId'] = (map['projectId'] ?? '').toString();
      map['date'] = _toIsoString(map['date']) ?? _nowIso();
      final rawHours = map['hours'];
      map['hours'] = rawHours is num
          ? rawHours.toDouble()
          : double.tryParse(rawHours?.toString() ?? '') ?? 0.0;
      map['notes'] = map['notes']?.toString();
      map['createdAt'] = _toIsoString(map['createdAt']) ?? _nowIso();
      map['updatedAt'] = _toIsoString(map['updatedAt']);

      if ((map['userId'] as String).isEmpty ||
          (map['projectId'] as String).isEmpty) {
        return null;
      }

      return TimesheetEntry.fromJson(map);
    } catch (e) {
      debugPrint('Skip timesheet doc non valido (${doc.id}): $e');
      return null;
    }
  }

  String _normalizeUserRole(dynamic raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    if (value == 'admin') return 'admin';
    if (value == 'manager') return 'manager';
    if (value == 'teamlead' ||
        value == 'team_lead' ||
        value == 'team-lead' ||
        value == 'tl') {
      return 'teamLead';
    }
    if (value == 'employee' ||
        value == 'developer' ||
        value == 'dev' ||
        value == 'viewer' ||
        value == 'visualizzatore') {
      return 'employee';
    }
    return 'employee';
  }

  String? _pickFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);
        final nestedId =
            nested['id'] ??
            nested['uid'] ??
            nested['userId'] ??
            nested['email'];
        if (nestedId != null) {
          final nestedText = nestedId.toString().trim();
          if (nestedText.isNotEmpty) {
            return nestedText;
          }
        }
      }
      final asString = value.toString().trim();
      if (asString.isNotEmpty) {
        return asString;
      }
    }
    return null;
  }

  String? _normalizeDeveloperType(dynamic raw) {
    if (raw == null) {
      return null;
    }

    final value = raw.toString().trim().toLowerCase();
    switch (value) {
      case 'android':
        return 'android';
      case 'ios':
        return 'ios';
      case 'fullstack':
      case 'full_stack':
      case 'full-stack':
        return 'fullStack';
      case 'backend':
        return 'backend';
      case 'frontend':
      case 'front_end':
      case 'front-end':
        return 'frontend';
      case 'designer':
        return 'designer';
      case 'qa':
        return 'qa';
      default:
        return null;
    }
  }

  String? _toIsoString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    final asString = value.toString();
    final parsed = DateTime.tryParse(asString);
    return parsed?.toIso8601String();
  }

  String _nowIso() => DateTime.now().toIso8601String();
}
