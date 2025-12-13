import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';
@JsonSerializable()
class User{
  int id;
  String email;
  String password;
  @JsonKey(name: 'full_name')
  String fullName;
  String phone;
  String role;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  User({
    required this.id,
    required this.email, 
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }): createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}