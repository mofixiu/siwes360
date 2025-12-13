import 'package:json_annotation/json_annotation.dart';

part 'school.g.dart';
@JsonSerializable()
class School {
  final int id;
  String name;
  String address;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  School({
    required this.id,
    required this.name,
    required this.address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory School.fromJson(Map<String, dynamic> json) => _$SchoolFromJson(json);
  Map<String, dynamic> toJson() => _$SchoolToJson(this);
}