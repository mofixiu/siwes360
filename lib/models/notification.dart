import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';
@JsonSerializable()
class Notification {
  final int id;
  @JsonKey(name: 'user_id')
  int userId;
  String message;
  String isread;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.isread,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}