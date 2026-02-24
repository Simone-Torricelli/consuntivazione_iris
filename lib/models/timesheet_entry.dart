import 'package:json_annotation/json_annotation.dart';

part 'timesheet_entry.g.dart';

@JsonSerializable()
class TimesheetEntry {
  final String id;
  final String userId;
  final String projectId;
  final DateTime date;
  final double hours; // In 0.5 increments
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TimesheetEntry({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.date,
    required this.hours,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) =>
      _$TimesheetEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TimesheetEntryToJson(this);

  TimesheetEntry copyWith({
    String? id,
    String? userId,
    String? projectId,
    DateTime? date,
    double? hours,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Utility methods
  bool get isValid => hours >= 0.5 && hours <= 8.0 && hours % 0.5 == 0;
}
