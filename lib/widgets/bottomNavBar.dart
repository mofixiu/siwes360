import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:siwes360/screens/student/studentDashboard.dart';
import 'package:siwes360/screens/student/studentLogbook.dart';
import 'package:siwes360/screens/student/studentProfile.dart';
import 'package:siwes360/screens/student/supervisorsScreenStudent.dart';
import 'package:siwes360/themes/theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const StudentDashboard();
        break;
      case 1:
        nextPage = const StudentLogbook();
        break;
      case 2:
        nextPage = const StudentSupervisorsScreen();
        break;
      case 3:
        nextPage = const StudentProfile();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? SIWES360.darkCardBackground
        : SIWES360.lightCardBackground;
    final selectedItemColor = SIWES360.lightButtonBackground;
    final unselectedItemColor = Colors.grey[600];

    return SizedBox(
      height: 95,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _navigate(context, index),
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.bookBookmark),
            label: "Logbook",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.peopleGroup),
            label: "Supervisors",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
