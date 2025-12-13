import 'package:json_annotation/json_annotation.dart';

part 'itf.g.dart';
@JsonSerializable()
class Itf {
  @JsonKey(name: 'user_id')
  int userId;
  String region;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  Itf({
    required this.userId,
    required this.region,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Itf.fromJson(Map<String, dynamic> json) => _$ItfFromJson(json);
  Map<String, dynamic> toJson() => _$ItfToJson(this);
}