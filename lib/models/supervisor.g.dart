// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supervisor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Supervisor _$SupervisorFromJson(Map<String, dynamic> json) => Supervisor(
  userId: (json['user_id'] as num).toInt(),
  organization: json['organization'] as String,
  position: json['position'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SupervisorToJson(Supervisor instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'organization': instance.organization,
      'position': instance.position,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
