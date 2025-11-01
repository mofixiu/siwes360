import 'package:flutter/material.dart';
import 'package:siwes360/widgets/bottomNavBar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: BottomNavBar(currentIndex: 0));
  }
}
