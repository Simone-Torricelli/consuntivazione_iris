import 'package:json_annotation/json_annotation.dart';

part 'commessa_model.g.dart';

enum CommessaStatus { active, paused, closed }

@JsonSerializable()
class Commessa {
  final String id;
  final String codice;
  final String descrizione;
  final String cliente;
  final CommessaStatus status;
  final bool isActive;
  final DateTime createdAt;

  Commessa({
    required this.id,
    required this.codice,
    required this.descrizione,
    required this.cliente,
    this.status = CommessaStatus.active,
    this.isActive = true,
    required this.createdAt,
  });

  factory Commessa.fromJson(Map<String, dynamic> json) =>
      _$CommessaFromJson(json);
  Map<String, dynamic> toJson() => _$CommessaToJson(this);

  Commessa copyWith({
    String? id,
    String? codice,
    String? descrizione,
    String? cliente,
    CommessaStatus? status,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Commessa(
      id: id ?? this.id,
      codice: codice ?? this.codice,
      descrizione: descrizione ?? this.descrizione,
      cliente: cliente ?? this.cliente,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension CommessaStatusExtension on CommessaStatus {
  String get displayName {
    switch (this) {
      case CommessaStatus.active:
        return 'Attiva';
      case CommessaStatus.paused:
        return 'In pausa';
      case CommessaStatus.closed:
        return 'Chiusa';
    }
  }
}
