import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';
@JsonSerializable()
class Student{
  @JsonKey(name: 'user_id')
  int userId;
  @JsonKey(name: 'matric_no')
  String matricNo;
  String department;
  String level;
  @JsonKey(name: 'supervisor_id')
  int supervisorId;
  @JsonKey(name: 'school_id')
  int schoolId;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  Student({
    required this.userId,
    required this.matricNo, 
    required this.department,
    required this.level,
    required this.supervisorId,
    required this.schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}