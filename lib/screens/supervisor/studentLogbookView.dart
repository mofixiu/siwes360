import 'package:flutter/material.dart';
import 'package:siwes360/screens/supervisor/supervisorStudentsPage.dart';
import 'package:siwes360/screens/supervisor/logbookEntryDetail.dart';

class StudentLogbookView extends StatefulWidget {
  final Student student;

  const StudentLogbookView({super.key, required this.student});

  @override
  State<StudentLogbookView> createState() => _StudentLogbookViewState();
}

class _StudentLogbookViewState extends State<StudentLogbookView> {
  // Sample logbook data grouped by weeks
  final Map<int, List<LogbookEntry>> _logbookEntries = {
    8: [
      LogbookEntry(
        date: DateTime(2024, 8, 10),
        dayOfWeek: 'Monday',
        tasksCompleted:
            'Implemented user authentication flow using Firebase Authentication.',
        status: EntryStatus.pending,
      ),
      LogbookEntry(
        date: DateTime(2024, 8, 11),
        dayOfWeek: 'Tuesday',
        tasksCompleted:
            'Set up email/password sign-up and login functionalities.',
        status: EntryStatus.pending,
      ),
      LogbookEntry(
        date: DateTime(2024, 8, 12),
        dayOfWeek: 'Wednesday',
        tasksCompleted: 'Integrated UI components for authentication screens.',
        status: EntryStatus.pending,
      ),
    ],
    7: [
      LogbookEntry(
        date: DateTime(2024, 8, 3),
        dayOfWeek: 'Monday',
        tasksCompleted:
            'Worked on creating the profile page where users can view their information.',
        status: EntryStatus.approved,
      ),
      LogbookEntry(
        date: DateTime(2024, 8, 4),
        dayOfWeek: 'Tuesday',
        tasksCompleted: 'Implemented Firestore database structure.',
        status: EntryStatus.approved,
      ),
    ],
    6: [
      LogbookEntry(
        date: DateTime(2024, 7, 27),
        dayOfWeek: 'Monday',
        tasksCompleted: 'Started working on the dashboard UI components.',
        status: EntryStatus.approved,
      ),
      LogbookEntry(
        date: DateTime(2024, 7, 28),
        dayOfWeek: 'Tuesday',
        tasksCompleted: 'Integrated charts and data visualization.',
        status: EntryStatus.rejected,
        feedback: 'Please provide more details about the implementation.',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Logbook',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        widget.student.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.grey[600],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student.matric,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student.department,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A3D62),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logbook Entries Grouped by Weeks
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logbookEntries.length,
              itemBuilder: (context, index) {
                final weekNumber = _logbookEntries.keys.toList()[index];
                final entries = _logbookEntries[weekNumber]!;
                return _buildWeekSection(weekNumber, entries);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSection(int weekNumber, List<LogbookEntry> entries) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Week $weekNumber',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Days in the week
          ...entries.map((entry) => _buildDayCard(entry, weekNumber)),
        ],
      ),
    );
  }

  Widget _buildDayCard(LogbookEntry entry, int weekNumber) {
    Color statusColor;
    IconData statusIcon;

    switch (entry.status) {
      case EntryStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case EntryStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case EntryStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LogbookEntryDetail(
              student: widget.student,
              entry: entry,
              weekNumber: weekNumber,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.dayOfWeek,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        entry.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.date.day}th ${_getMonthName(entry.date.month)} ${entry.date.year}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              entry.tasksCompleted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            if (entry.feedback != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.feedback!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

// Logbook Entry Model
class LogbookEntry {
  final DateTime date;
  final String dayOfWeek;
  final String tasksCompleted;
  final EntryStatus status;
  final String? feedback;

  LogbookEntry({
    required this.date,
    required this.dayOfWeek,
    required this.tasksCompleted,
    required this.status,
    this.feedback,
  });
}

enum EntryStatus { pending, approved, rejected }
