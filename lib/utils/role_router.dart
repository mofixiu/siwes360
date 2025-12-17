import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/studentDashboard.dart';
import 'package:siwes360/screens/supervisor/supervisorDashboard.dart';
import 'package:siwes360/utils/custom_page_route.dart'; // Add this import

class RoleRouter {
  static Widget getHomeScreen(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return const StudentDashboard();
      case 'supervisor':
        return const SupervisorDashboard();
      case 'admin':
        // TODO: Create admin dashboard
        return const Placeholder(); // Replace with AdminDashboard()
      case 'itf':
        // TODO: Create ITF dashboard
        return const Placeholder(); // Replace with ITFDashboard()
      default:
        return const StudentDashboard(); // Default fallback
    }
  }

  static void navigateToRoleBasedHome(BuildContext context, String role) {
    // Use fade transition for smooth navigation to dashboard
    context.pushReplacementFade(getHomeScreen(role));
  }
}
