import 'package:json_annotation/json_annotation.dart';

part 'daily_log.g.dart';
@JsonSerializable()
class Daily_log {
  final int id;
  @JsonKey(name: 'student_id')
  int studentId;
  @JsonKey(name: 'log_date')
  DateTime logDate;
  String description;
  String supervisorComment;
  String? status;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  Daily_log({
    required this.id,
    required this.studentId,
    required this.logDate,
    required this.description,
    required this.supervisorComment,
    this.status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Daily_log.fromJson(Map<String, dynamic> json) => _$Daily_logFromJson(json);
  Map<String, dynamic> toJson() => _$Daily_logToJson(this);
}