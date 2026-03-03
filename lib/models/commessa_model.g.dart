// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commessa_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commessa _$CommessaFromJson(Map<String, dynamic> json) => Commessa(
  id: json['id'] as String,
  codice: json['codice'] as String,
  descrizione: json['descrizione'] as String,
  cliente: json['cliente'] as String,
  status:
      $enumDecodeNullable(_$CommessaStatusEnumMap, json['status']) ??
      CommessaStatus.active,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$CommessaToJson(Commessa instance) => <String, dynamic>{
  'id': instance.id,
  'codice': instance.codice,
  'descrizione': instance.descrizione,
  'cliente': instance.cliente,
  'status': _$CommessaStatusEnumMap[instance.status]!,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$CommessaStatusEnumMap = {
  CommessaStatus.active: 'active',
  CommessaStatus.paused: 'paused',
  CommessaStatus.closed: 'closed',
};
