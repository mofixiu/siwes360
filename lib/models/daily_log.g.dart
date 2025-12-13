// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Daily_log _$Daily_logFromJson(Map<String, dynamic> json) => Daily_log(
  id: (json['id'] as num).toInt(),
  studentId: (json['student_id'] as num).toInt(),
  logDate: DateTime.parse(json['log_date'] as String),
  description: json['description'] as String,
  supervisorComment: json['supervisorComment'] as String,
  status: json['status'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$Daily_logToJson(Daily_log instance) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'log_date': instance.logDate.toIso8601String(),
  'description': instance.description,
  'supervisorComment': instance.supervisorComment,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
