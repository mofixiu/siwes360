import 'package:flutter/material.dart';
import 'package:siwes360/screens/supervisor/supervisorDashboard.dart';
import 'package:siwes360/screens/supervisor/supervisorProfile.dart';
import 'package:siwes360/screens/supervisor/supervisorStudentsPage.dart';
import 'package:siwes360/widgets/paper_nav_bar.dart';

class SupervisorNavBar extends StatelessWidget {
  const SupervisorNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static final items = [
    NavItem('Review', Icons.fact_check_outlined, Icons.fact_check, (_) => const SupervisorDashboard()),
    NavItem('Students', Icons.people_outline, Icons.people, (_) => const SupervisorStudentsPage()),
    NavItem('Profile', Icons.person_outline, Icons.person, (_) => const SupervisorProfile()),
  ];

  @override
  Widget build(BuildContext context) => PaperNavBar(items: items, currentIndex: currentIndex);
}
