import 'package:json_annotation/json_annotation.dart';

part 'grade.g.dart';
@JsonSerializable()
class Grade {
  final int id;
  @JsonKey(name: 'student_id')
  int studentId;
  String gradedBy;
  String score;
  String? remarks;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  Grade({
    required this.id,
    required this.studentId,
    required this.gradedBy,
    required this.score,
    this.remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Grade.fromJson(Map<String, dynamic> json) => _$GradeFromJson(json);
  Map<String, dynamic> toJson() => _$GradeToJson(this);
}