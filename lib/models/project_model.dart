import 'package:json_annotation/json_annotation.dart';

part 'project_model.g.dart';

@JsonSerializable()
class Project {
  final String id;
  final String name;
  final String description;
  final String color; // Hex color
  final bool isActive;
  final DateTime createdAt;
  final List<String> assignedUserIds;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.isActive = true,
    required this.createdAt,
    this.assignedUserIds = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    List<String>? assignedUserIds,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
    );
  }
}
