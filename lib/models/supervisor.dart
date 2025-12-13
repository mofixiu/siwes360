import 'package:json_annotation/json_annotation.dart';

part 'supervisor.g.dart';
@JsonSerializable()
class Supervisor {
  @JsonKey(name: 'user_id')
  int userId;
  String organization;
  String position;

  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  Supervisor({
    required this.userId,
    required this.organization,
    required this.position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Supervisor.fromJson(Map<String, dynamic> json) => _$SupervisorFromJson(json);
  Map<String, dynamic> toJson() => _$SupervisorToJson(this);
}