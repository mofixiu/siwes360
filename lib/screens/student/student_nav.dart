import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/studentDashboard.dart';
import 'package:siwes360/screens/student/studentLogbook.dart';
import 'package:siwes360/screens/student/studentProfile.dart';
import 'package:siwes360/widgets/paper_nav_bar.dart';

class StudentNavBar extends StatelessWidget {
  const StudentNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static final items = [
    NavItem('Today', Icons.today_outlined, Icons.today, (_) => const StudentDashboard()),
    NavItem('Logbook', Icons.menu_book_outlined, Icons.menu_book, (_) => const StudentLogbook()),
    NavItem('Profile', Icons.person_outline, Icons.person, (_) => const StudentProfile()),
  ];

  @override
  Widget build(BuildContext context) => PaperNavBar(items: items, currentIndex: currentIndex);
}
