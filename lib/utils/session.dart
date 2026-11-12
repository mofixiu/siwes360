import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:siwes360/auth/login.dart';
import 'package:siwes360/utils/request.dart';

/// The signed-in account, as saved at login: the user row plus `role_data`.
class Session {
  Session._(this.data);

  final Map<String, dynamic> data;

  int get id => (data['id'] as num).toInt();
  String get role => '${data['role']}';
  String get fullName => '${data['full_name'] ?? ''}';
  String get email => '${data['email'] ?? ''}';
  Map<String, dynamic> get roleData => Map<String, dynamic>.from(data['role_data'] ?? {});

  static Future<Session?> load() async {
    final data = await RequestService.loadUserData();
    if (data == null || data['id'] == null) return null;
    return Session._(Map<String, dynamic>.from(data));
  }

  /// Photo the user picked on this device, if any (photos are not uploaded).
  static Future<String?> photoPath(String role, int id) async {
    final box = await Hive.openBox(role == 'supervisor' ? 'supervisorProfile' : 'studentProfile');
    final path = box.get('profile_image_$id');
    if (path is String && await File(path).exists()) return path;
    return null;
  }

  /// Clears the stored token and user, then returns to the login screen.
  static Future<void> signOut(BuildContext context) async {
    await RequestService.clearUserData();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (_) => false,
    );
  }
}
