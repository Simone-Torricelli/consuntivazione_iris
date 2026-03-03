// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimesheetEntry _$TimesheetEntryFromJson(Map<String, dynamic> json) =>
    TimesheetEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String,
      commessaId: json['commessaId'] as String?,
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TimesheetEntryToJson(TimesheetEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'projectId': instance.projectId,
      'commessaId': instance.commessaId,
      'date': instance.date.toIso8601String(),
      'hours': instance.hours,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
