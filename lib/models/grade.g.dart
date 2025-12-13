// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Grade _$GradeFromJson(Map<String, dynamic> json) => Grade(
  id: (json['id'] as num).toInt(),
  studentId: (json['student_id'] as num).toInt(),
  gradedBy: json['gradedBy'] as String,
  score: json['score'] as String,
  remarks: json['remarks'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$GradeToJson(Grade instance) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'gradedBy': instance.gradedBy,
  'score': instance.score,
  'remarks': instance.remarks,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
