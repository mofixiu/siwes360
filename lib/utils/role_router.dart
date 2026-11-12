import 'package:flutter/material.dart';
import 'package:siwes360/screens/admin/admin_overview.dart';
import 'package:siwes360/screens/itf/itf_overview.dart';
import 'package:siwes360/screens/student/studentDashboard.dart';
import 'package:siwes360/screens/supervisor/supervisorDashboard.dart';
import 'package:siwes360/theme/tokens.dart';

class RoleRouter {
  static Widget getHomeScreen(String role) {
    switch (role.toLowerCase()) {
      case 'supervisor':
        return const SupervisorDashboard();
      case 'admin':
        return const AdminOverview();
      case 'itf':
        return const ItfOverview();
      case 'student':
      default:
        return const StudentDashboard();
    }
  }

  static void navigateToRoleBasedHome(BuildContext context, String role) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, _, _) => OnPaper(child: getHomeScreen(role)),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
      (_) => false,
    );
  }
}
