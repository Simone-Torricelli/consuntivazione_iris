import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_model.dart';
import '../models/timesheet_entry.dart';
import '../models/user_model.dart';
import '../utils/work_calendar_utils.dart';
import 'firebase_sync_service.dart';

class DataService extends ChangeNotifier {
  List<User> _users = [];
  List<Project> _projects = [];
  List<TimesheetEntry> _timesheetEntries = [];
  bool _isLoading = false;
  StreamSubscription<List<User>>? _usersSubscription;
  StreamSubscription<List<Project>>? _projectsSubscription;
  StreamSubscription<List<TimesheetEntry>>? _timesheetSubscription;
  final StreamController<int> _realtimeTickController =
      StreamController<int>.broadcast();
  int _realtimeTick = 0;

  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  List<User> get users => _users;
  List<Project> get projects => _projects;
  List<TimesheetEntry> get timesheetEntries => _timesheetEntries;
  bool get isLoading => _isLoading;
  Stream<int> get realtimeTickStream => _realtimeTickController.stream;
  int get realtimeTick => _realtimeTick;

  static const String _usersKey = 'users';
  static const String _projectsKey = 'projects';
  static const String _timesheetKey = 'timesheet_entries';

  Future<void> initialize() async {
    _isLoading = true;
    _cancelRealtimeListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      var hasRemoteData = false;
      if (_firebaseSync.isEnabled) {
        hasRemoteData = await _loadFromFirebase();
        _startRealtimeListeners();
      }

      if (!hasRemoteData) {
        await _loadFromLocal(prefs);
      }

      if (!_firebaseSync.isEnabled && _projects.isEmpty) {
        await _createSampleProjects();
      }
      if (!_firebaseSync.isEnabled) {
        await _ensureSystemProjects();
        await _ensureDefaultAdminUser();
      }

      await _saveUsers(syncRemote: false);
      await _saveProjects(syncRemote: false);
      await _saveTimesheetEntries(syncRemote: false);
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromRemote() async {
    if (!_firebaseSync.isEnabled) {
      await initialize();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _loadFromFirebase();
      await _saveUsers(syncRemote: false);
      await _saveProjects(syncRemote: false);
      await _saveTimesheetEntries(syncRemote: false);
      _emitRealtimeTick();
    } catch (e) {
      debugPrint('Error refreshing Firebase data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeListeners() {
    if (!_firebaseSync.isEnabled) {
      return;
    }

    _usersSubscription = _firebaseSync.watchUsers().listen(
      (users) async {
        _users = users;
        _emitRealtimeTick();
        await _saveUsers(syncRemote: false);
      },
      onError: (error) {
        debugPrint('Realtime users error: $error');
      },
    );

    _projectsSubscription = _firebaseSync.watchProjects().listen(
      (projects) async {
        _projects = projects;
        _emitRealtimeTick();
        await _saveProjects(syncRemote: false);
      },
      onError: (error) {
        debugPrint('Realtime projects error: $error');
      },
    );

    _timesheetSubscription = _firebaseSync.watchTimesheetEntries().listen(
      (entries) async {
        _timesheetEntries = entries;
        _emitRealtimeTick();
        await _saveTimesheetEntries(syncRemote: false);
      },
      onError: (error) {
        debugPrint('Realtime timesheet error: $error');
      },
    );
  }

  void _cancelRealtimeListeners() {
    _usersSubscription?.cancel();
    _projectsSubscription?.cancel();
    _timesheetSubscription?.cancel();
    _usersSubscription = null;
    _projectsSubscription = null;
    _timesheetSubscription = null;
  }

  void _emitRealtimeTick() {
    _realtimeTick++;
    if (!_realtimeTickController.isClosed) {
      _realtimeTickController.add(_realtimeTick);
    }
  }

  Future<bool> _loadFromFirebase() async {
    try {
      final remoteUsers = await _firebaseSync.fetchUsers();
      final remoteProjects = await _firebaseSync.fetchProjects();
      final remoteEntries = await _firebaseSync.fetchTimesheetEntries();

      _users = remoteUsers;
      _projects = remoteProjects;
      _timesheetEntries = remoteEntries;

      return remoteUsers.isNotEmpty ||
          remoteProjects.isNotEmpty ||
          remoteEntries.isNotEmpty;
    } catch (e) {
      debugPrint('Error loading Firebase data: $e');
      return false;
    }
  }

  Future<void> _loadFromLocal(SharedPreferences prefs) async {
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final List<dynamic> usersList = json.decode(usersJson);
      _users = usersList.map((u) => User.fromJson(u)).toList();
    }

    final projectsJson = prefs.getString(_projectsKey);
    if (projectsJson != null) {
      final List<dynamic> projectsList = json.decode(projectsJson);
      _projects = projectsList.map((p) => Project.fromJson(p)).toList();
    }

    final timesheetJson = prefs.getString(_timesheetKey);
    if (timesheetJson != null) {
      final List<dynamic> timesheetList = json.decode(timesheetJson);
      _timesheetEntries = timesheetList
          .map((t) => TimesheetEntry.fromJson(t))
          .toList();
    }
  }

  Future<void> _createSampleProjects() async {
    _projects = [
      Project(
        id: 'proj_001',
        name: 'IRIS Mobile App',
        description: 'Sviluppo applicazione mobile',
        color: '#FF6B6B',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'proj_002',
        name: 'Dashboard Admin',
        description: 'Pannello di amministrazione',
        color: '#4ECDC4',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'proj_003',
        name: 'API Backend',
        description: 'Sviluppo API REST',
        color: '#FFE66D',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'proj_ferie',
        name: 'Ferie',
        description: 'Giornata di ferie o permesso',
        color: '#10B981',
        createdAt: DateTime.now(),
      ),
    ];
    await _saveProjects();
  }

  Future<void> _ensureSystemProjects() async {
    final hasVacationProject = _projects.any(
      (p) => p.name.toLowerCase().trim() == 'ferie',
    );

    if (!hasVacationProject) {
      _projects.add(
        Project(
          id: 'proj_ferie_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Ferie',
          description: 'Giornata di ferie o permesso',
          color: '#10B981',
          createdAt: DateTime.now(),
        ),
      );
      await _saveProjects();
    }
  }

  Future<void> _ensureDefaultAdminUser() async {
    if (_firebaseSync.isEnabled) {
      return;
    }

    final hasAdmin = _users.any((u) => u.role == UserRole.admin);
    if (hasAdmin) {
      return;
    }

    _users.add(
      User(
        id: 'admin_001',
        email: 'admin@iris.com',
        name: 'Admin',
        surname: 'IRIS',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      ),
    );
    await _saveUsers();
  }

  Future<void> addUser(User user) async {
    _users.add(user);
    await _saveUsers(syncRemote: false);

    if (_firebaseSync.isEnabled) {
      try {
        await _firebaseSync.upsertUser(user);
      } catch (e) {
        debugPrint('Firebase upsertUser error: $e');
      }
    }
  }

  Future<void> updateUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      await _saveUsers(syncRemote: false);

      if (_firebaseSync.isEnabled) {
        try {
          await _firebaseSync.upsertUser(user);
        } catch (e) {
          debugPrint('Firebase upsertUser error: $e');
        }
      }
    }
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    await _saveUsers(syncRemote: false);

    if (_firebaseSync.isEnabled) {
      try {
        await _firebaseSync.deleteUser(userId);
      } catch (e) {
        debugPrint('Firebase deleteUser error: $e');
      }
    }
  }

  Future<void> addProject(Project project) async {
    _projects.add(project);
    await _saveProjects(syncRemote: false);

    if (_firebaseSync.isEnabled) {
      try {
        await _firebaseSync.upsertProject(project);
      } catch (e) {
        debugPrint('Firebase upsertProject error: $e');
      }
    }
  }

  Future<void> updateProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      await _saveProjects(syncRemote: false);

      if (_firebaseSync.isEnabled) {
        try {
          await _firebaseSync.upsertProject(project);
        } catch (e) {
          debugPrint('Firebase upsertProject error: $e');
        }
      }
    }
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await _saveProjects(syncRemote: false);

    if (_firebaseSync.isEnabled) {
      try {
        await _firebaseSync.deleteProject(projectId);
      } catch (e) {
        debugPrint('Firebase deleteProject error: $e');
      }
    }
  }

  Future<bool> addTimesheetEntry(TimesheetEntry entry, {User? actor}) async {
    final dailyTotal = getDailyHours(entry.userId, entry.date);
    if (dailyTotal + entry.hours > 8.0) {
      return false;
    }

    if (actor != null) {
      if (actor.role == UserRole.employee && actor.id != entry.userId) {
        return false;
      }

      final project = getProjectById(entry.projectId);
      if (project == null || !canTrackProject(user: actor, project: project)) {
        return false;
      }
    }

    _timesheetEntries.add(entry);
    await _saveTimesheetEntries(syncRemote: false);

    if (_firebaseSync.isEnabled) {
      try {
        await _firebaseSync.upsertTimesheetEntry(entry);
      } catch (e) {
        debugPrint('Firebase upsertTimesheetEntry error: $e');
      }
    }
    return true;
  }

  Future<bool> updateTimesheetEntry(TimesheetEntry entry, {User? actor}) async {
    final index = _timesheetEntries.indexWhere((t) => t.id == entry.id);
    if (index != -1) {
      if (actor != null) {
        if (actor.role == UserRole.employee && actor.id != entry.userId) {
          return false;
        }

        final project = getProjectById(entry.projectId);
        if (project == null ||
            !canTrackProject(user: actor, project: project)) {
          return false;
        }
      }

      final otherEntries = _timesheetEntries.where(
        (t) =>
            t.userId == entry.userId &&
            t.date.year == entry.date.year &&
            t.date.month == entry.date.month &&
            t.date.day == entry.date.day &&
            t.id != entry.id,
      );

      final otherHours = otherEntries.fold<double>(
        0,
        (sum, t) => sum + t.hours,
      );
      if (otherHours + entry.hours > 8.0) {
        return false;
      }

      _timesheetEntries[index] = entry;
      await _saveTimesheetEntries(syncRemote: false);

      if (_firebaseSync.isEnabled) {
        try {
          await _firebaseSync.upsertTimesheetEntry(entry);
        } catch (e) {
          debugPrint('Firebase upsertTimesheetEntry error: $e');
        }
      }
      return true;
    }
    return false;
  }

  Future<void> deleteTimesheetEntry(String entryId) async {
    _timesheetEntries.removeWhere((t) => t.id == entryId);
    await _saveTimesheetEntries(syncRemote: false);

    if (_firebaseSync.isEnabled) {
      try {
        await _firebaseSync.deleteTimesheetEntry(entryId);
      } catch (e) {
        debugPrint('Firebase deleteTimesheetEntry error: $e');
      }
    }
  }

  double getDailyHours(String userId, DateTime date) {
    final entries = _timesheetEntries.where(
      (t) =>
          t.userId == userId &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day,
    );
    return entries.fold<double>(0, (sum, t) => sum + t.hours);
  }

  List<TimesheetEntry> getEntriesForUser(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _timesheetEntries
        .where(
          (t) =>
              t.userId == userId &&
              t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  List<TimesheetEntry> getEntriesForDate(String userId, DateTime date) {
    return _timesheetEntries
        .where(
          (t) =>
              t.userId == userId &&
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day,
        )
        .toList();
  }

  List<TimesheetEntry> getEntriesForProject(
    String projectId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final normalizedStart = startDate != null
        ? DateUtils.dateOnly(startDate)
        : null;
    final normalizedEnd = endDate != null ? DateUtils.dateOnly(endDate) : null;

    return _timesheetEntries.where((entry) {
      if (entry.projectId != projectId) {
        return false;
      }

      final entryDate = DateUtils.dateOnly(entry.date);
      final inStart =
          normalizedStart == null || !entryDate.isBefore(normalizedStart);
      final inEnd = normalizedEnd == null || !entryDate.isAfter(normalizedEnd);
      return inStart && inEnd;
    }).toList();
  }

  double getProjectTotalHours(
    String projectId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final entries = getEntriesForProject(
      projectId,
      startDate: startDate,
      endDate: endDate,
    );
    return entries.fold<double>(0, (sum, entry) => sum + entry.hours);
  }

  Map<String, double> getHoursByUserForProject(
    String projectId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final result = <String, double>{};
    final entries = getEntriesForProject(
      projectId,
      startDate: startDate,
      endDate: endDate,
    );

    for (final entry in entries) {
      result[entry.userId] = (result[entry.userId] ?? 0) + entry.hours;
    }
    return result;
  }

  Map<String, double> getHoursByProjectForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final result = <String, double>{};
    final normalizedStart = startDate != null
        ? DateUtils.dateOnly(startDate)
        : null;
    final normalizedEnd = endDate != null ? DateUtils.dateOnly(endDate) : null;

    for (final entry in _timesheetEntries) {
      if (entry.userId != userId) {
        continue;
      }

      final entryDate = DateUtils.dateOnly(entry.date);
      if (normalizedStart != null && entryDate.isBefore(normalizedStart)) {
        continue;
      }
      if (normalizedEnd != null && entryDate.isAfter(normalizedEnd)) {
        continue;
      }

      result[entry.projectId] = (result[entry.projectId] ?? 0) + entry.hours;
    }
    return result;
  }

  Future<void> _saveUsers({bool syncRemote = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      json.encode(_users.map((u) => u.toJson()).toList()),
    );

    if (syncRemote && _firebaseSync.isEnabled) {
      try {
        await _firebaseSync.syncUsers(_users);
      } catch (e) {
        debugPrint('Firebase syncUsers error: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _saveProjects({bool syncRemote = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _projectsKey,
      json.encode(_projects.map((p) => p.toJson()).toList()),
    );

    if (syncRemote && _firebaseSync.isEnabled) {
      try {
        await _firebaseSync.syncProjects(_projects);
      } catch (e) {
        debugPrint('Firebase syncProjects error: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _saveTimesheetEntries({bool syncRemote = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _timesheetKey,
      json.encode(_timesheetEntries.map((t) => t.toJson()).toList()),
    );

    if (syncRemote && _firebaseSync.isEnabled) {
      try {
        await _firebaseSync.syncTimesheetEntries(_timesheetEntries);
      } catch (e) {
        debugPrint('Firebase syncTimesheetEntries error: $e');
      }
    }

    notifyListeners();
  }

  Project? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  User? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  List<User> getUsersByRole(UserRole role) {
    return _users.where((u) => u.role == role && u.isActive).toList();
  }

  List<User> getTeamLeadsForManager(String managerId) {
    final manager = getUserById(managerId);
    return _users
        .where(
          (u) =>
              u.role == UserRole.teamLead &&
              _matchesUserReference(
                reference: u.managerId,
                userId: managerId,
                userEmail: manager?.email,
              ) &&
              u.isActive,
        )
        .toList();
  }

  List<User> getDevelopersForTeamLead(String teamLeadId) {
    final teamLead = getUserById(teamLeadId);
    return _users
        .where(
          (u) =>
              u.role == UserRole.employee &&
              _matchesUserReference(
                reference: u.teamLeadId,
                userId: teamLeadId,
                userEmail: teamLead?.email,
              ) &&
              u.isActive,
        )
        .toList();
  }

  List<User> getDevelopersForManager(String managerId) {
    final teamLeads = getTeamLeadsForManager(managerId);
    return _users
        .where(
          (u) =>
              u.role == UserRole.employee &&
              u.teamLeadId != null &&
              teamLeads.any(
                (tl) => _matchesUserReference(
                  reference: u.teamLeadId,
                  userId: tl.id,
                  userEmail: tl.email,
                ),
              ) &&
              u.isActive,
        )
        .toList();
  }

  List<User> getTeamMembersForUser(User user) {
    switch (user.role) {
      case UserRole.admin:
        return _users
            .where((u) => u.role != UserRole.admin && u.isActive)
            .toList();
      case UserRole.manager:
        return [
          ...getTeamLeadsForManager(user.id),
          ...getDevelopersForManager(user.id),
        ];
      case UserRole.teamLead:
        return getDevelopersForTeamLead(user.id);
      case UserRole.employee:
        return [user];
    }
  }

  List<Project> getProjectsVisibleForUser(User user) {
    final activeProjects = _projects.where((p) => p.isActive).toList();

    switch (user.role) {
      case UserRole.admin:
      case UserRole.manager:
        return activeProjects;
      case UserRole.teamLead:
        return activeProjects.where((p) => p.ownerUserId == user.id).toList();
      case UserRole.employee:
        return activeProjects
            .where((p) => p.assignedUserIds.contains(user.id))
            .toList();
    }
  }

  bool canAccessProject({required User viewer, required Project project}) {
    switch (viewer.role) {
      case UserRole.admin:
      case UserRole.manager:
        return true;
      case UserRole.teamLead:
        return project.ownerUserId == viewer.id || isVacationProject(project);
      case UserRole.employee:
        return project.assignedUserIds.contains(viewer.id) ||
            isVacationProject(project);
    }
  }

  bool canTrackProject({required User user, required Project project}) {
    switch (user.role) {
      case UserRole.admin:
      case UserRole.manager:
        return true;
      case UserRole.teamLead:
        return project.ownerUserId == user.id || isVacationProject(project);
      case UserRole.employee:
        return project.assignedUserIds.contains(user.id) ||
            isVacationProject(project);
    }
  }

  bool hasUserWorkedOnProject(String userId, String projectId) {
    return _timesheetEntries.any(
      (entry) => entry.userId == userId && entry.projectId == projectId,
    );
  }

  bool isVacationProject(Project project) {
    final normalized = project.name.toLowerCase().trim();
    return normalized.contains('ferie');
  }

  bool canViewUser({required User viewer, required User target}) {
    // Requirement: every authenticated user can open person details.
    return viewer.isActive && target.isActive;
  }

  bool _matchesUserReference({
    required String? reference,
    required String userId,
    String? userEmail,
  }) {
    if (reference == null || reference.trim().isEmpty) {
      return false;
    }

    final normalizedRef = reference.trim().toLowerCase();
    if (normalizedRef == userId.trim().toLowerCase()) {
      return true;
    }

    if (userEmail != null && userEmail.trim().isNotEmpty) {
      final normalizedEmail = userEmail.trim().toLowerCase();
      if (normalizedRef == normalizedEmail) {
        return true;
      }
    }

    return false;
  }

  bool isWorkingDay(DateTime date) {
    final day = DateUtils.dateOnly(date);
    final isWeekday =
        day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
    return isWeekday && !WorkCalendarUtils.isItalianPublicHoliday(day);
  }

  int getWorkingDaysInRange(DateTime startDate, DateTime endDate) {
    final start = DateUtils.dateOnly(startDate);
    final end = DateUtils.dateOnly(endDate);
    if (end.isBefore(start)) {
      return 0;
    }

    var current = start;
    var workingDays = 0;
    while (!current.isAfter(end)) {
      if (isWorkingDay(current)) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    return workingDays;
  }

  int getWorkingDaysInMonth(DateTime monthReference) {
    final start = DateTime(monthReference.year, monthReference.month, 1);
    final end = DateTime(monthReference.year, monthReference.month + 1, 0);
    return getWorkingDaysInRange(start, end);
  }

  DateTime getPenultimateWorkingDay(DateTime monthReference) {
    return _nthWorkingDayFromMonthEnd(monthReference, 2);
  }

  DateTime getLastWorkingDay(DateTime monthReference) {
    return _nthWorkingDayFromMonthEnd(monthReference, 1);
  }

  DateTime _nthWorkingDayFromMonthEnd(DateTime monthReference, int n) {
    var cursor = DateTime(monthReference.year, monthReference.month + 1, 0);
    var found = 0;
    while (true) {
      if (isWorkingDay(cursor)) {
        found++;
        if (found == n) {
          return DateUtils.dateOnly(cursor);
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  int getPerfectDaysCount({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    double perfectThreshold = 8.0,
  }) {
    final dailyHours = <DateTime, double>{};
    final entries = getEntriesForUser(userId, startDate, endDate);
    for (final entry in entries) {
      final day = DateUtils.dateOnly(entry.date);
      dailyHours[day] = (dailyHours[day] ?? 0) + entry.hours;
    }

    return dailyHours.entries
        .where(
          (entry) => isWorkingDay(entry.key) && entry.value >= perfectThreshold,
        )
        .length;
  }

  int getCurrentStreak(String userId, {DateTime? referenceDate}) {
    final today = DateUtils.dateOnly(referenceDate ?? DateTime.now());
    var cursor = today;

    if (isWorkingDay(cursor) && getDailyHours(userId, cursor) < 8.0) {
      cursor = _previousWorkingDay(cursor);
    }

    var streak = 0;
    while (isWorkingDay(cursor) && getDailyHours(userId, cursor) >= 8.0) {
      streak++;
      cursor = _previousWorkingDay(cursor);
    }
    return streak;
  }

  int getMonthlyExperience(String userId, DateTime monthReference) {
    final monthStart = DateTime(monthReference.year, monthReference.month, 1);
    final monthEnd = DateTime(monthReference.year, monthReference.month + 1, 0);
    final entries = getEntriesForUser(userId, monthStart, monthEnd);
    final totalHours = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
    final perfectDays = getPerfectDaysCount(
      userId: userId,
      startDate: monthStart,
      endDate: monthEnd,
    );
    return (totalHours * 10).round() + (perfectDays * 25);
  }

  DateTime _previousWorkingDay(DateTime date) {
    var cursor = date.subtract(const Duration(days: 1));
    while (!isWorkingDay(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return cursor;
  }

  @override
  void dispose() {
    _cancelRealtimeListeners();
    _realtimeTickController.close();
    super.dispose();
  }
}
