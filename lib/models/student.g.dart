// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
  userId: (json['user_id'] as num).toInt(),
  matricNo: json['matric_no'] as String,
  department: json['department'] as String,
  level: json['level'] as String,
  supervisorId: (json['supervisor_id'] as num).toInt(),
  schoolId: (json['school_id'] as num).toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
  'user_id': instance.userId,
  'matric_no': instance.matricNo,
  'department': instance.department,
  'level': instance.level,
  'supervisor_id': instance.supervisorId,
  'school_id': instance.schoolId,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
