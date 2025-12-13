// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itf.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Itf _$ItfFromJson(Map<String, dynamic> json) => Itf(
  userId: (json['user_id'] as num).toInt(),
  region: json['region'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ItfToJson(Itf instance) => <String, dynamic>{
  'user_id': instance.userId,
  'region': instance.region,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
