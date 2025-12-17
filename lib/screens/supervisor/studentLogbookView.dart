import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siwes360/screens/supervisor/supervisorStudentsPage.dart';
import 'package:siwes360/screens/supervisor/logbookEntryDetail.dart';
import 'package:siwes360/utils/request.dart';
import 'dart:convert';

class StudentLogbookView extends StatefulWidget {
  final Student student;

  const StudentLogbookView({super.key, required this.student});

  @override
  State<StudentLogbookView> createState() => _StudentLogbookViewState();
}

class _StudentLogbookViewState extends State<StudentLogbookView> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<int, List<LogbookEntry>> _logbookEntries = {};
  Map<String, dynamic>? _studentInfo;
  DateTime? _internshipStartDate; // Add this

  @override
  void initState() {
    super.initState();
    _loadStudentLogs();
  }

  Future<void> _loadStudentLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First, fetch student info to get internship start date
      final userData = await RequestService.loadUserData();
      if (userData == null || userData['role_data'] == null) {
        throw Exception('User data not found');
      }

      final supervisorId = userData['role_data']['user_id'];

      // Get student details (including internship dates)
      final studentResult = await RequestService.getStudentById(
        widget.student.userId,
      );

      if (studentResult != null && studentResult['status'] == 'success') {
        _studentInfo = studentResult['data'];

        // Parse internship start date
        if (_studentInfo?['internship_start_date'] != null) {
          _internshipStartDate = DateTime.parse(
            _studentInfo!['internship_start_date'],
          );
        }
      }

      // Fetch student's daily logs
      final result = await RequestService.getStudentDailyLogs(
        widget.student.userId,
      );

      if (result != null && result['status'] == 'success') {
        // Fix: The logs are directly in 'data', not nested under 'logs'
        final logs = result['data'] as List? ?? [];

        // Group logs by week
        Map<int, List<LogbookEntry>> groupedLogs = {};

        for (var log in logs) {
          final logDate = DateTime.parse(log['log_date']);
          final weekNumber = _getWeekNumber(logDate);

          // Parse attachments properly
          List<dynamic> attachmentsList = [];
          if (log['attachments'] != null) {
            if (log['attachments'] is List) {
              attachmentsList = log['attachments'];
            } else if (log['attachments'] is String &&
                log['attachments'] != '') {
              // If it's a JSON string, try to parse it
              try {
                attachmentsList = jsonDecode(log['attachments']);
              } catch (e) {
                print('Error parsing attachments JSON: $e');
              }
            }
          }

          final entry = LogbookEntry(
            id: log['id'],
            date: logDate,
            dayOfWeek: DateFormat('EEEE').format(logDate),
            tasksCompleted: log['description'] ?? '',
            status: _parseStatus(log['status'] ?? 'pending'),
            feedback: log['supervisor_comment'],
            attachments: attachmentsList,
            attachmentCount: log['attachment_count'] ?? 0,
            skillsAcquired: log['skills_acquired'],
            challengesFaced: log['challenges_faced'],
          );

          if (groupedLogs[weekNumber] == null) {
            groupedLogs[weekNumber] = [];
          }
          groupedLogs[weekNumber]!.add(entry);
        }

        // Sort logs within each week by date
        groupedLogs.forEach((week, entries) {
          entries.sort((a, b) => a.date.compareTo(b.date));
        });

        setState(() {
          _logbookEntries = groupedLogs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Failed to load logs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading logs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _getWeekNumber(DateTime date) {
    // Calculate week number based on internship start date
    if (_internshipStartDate == null) {
      // Fallback to simple calculation if start date not available
      return 1;
    }

    final difference = date.difference(_internshipStartDate!).inDays;
    final weekNumber = (difference / 7).floor() + 1;

    // Ensure week number is at least 1
    return weekNumber < 1 ? 1 : weekNumber;
  }

  EntryStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return EntryStatus.approved;
      case 'rejected':
        return EntryStatus.rejected;
      case 'pending':
      default:
        return EntryStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      appBar: AppBar(
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
        // Removed refresh button - using pull-to-refresh instead
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadStudentLogs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D62),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStudentLogs,
              color: const Color(0xFF0A3D62),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Info Card
                    Container(
                      decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                      children: [
                        Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0A3D62),
                          
                        ),
                        child: Center(
                          child: Text(
                          widget.student.name
                            .substring(0, 1)
                            .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
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
                          _buildStatusBadge(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Logbook Entries or Empty State
                    if (_logbookEntries.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No logbook entries yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Student hasn\'t submitted any logs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _logbookEntries.length,
                        itemBuilder: (context, index) {
                          final weekNumber = _logbookEntries.keys
                              .toList()[index];
                          final entries = _logbookEntries[weekNumber]!;
                          return _buildWeekSection(weekNumber, entries);
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    final pendingCount = widget.student.newEntriesCount ?? 0;

    if (pendingCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$pendingCount Pending',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Up to Date',
        style: TextStyle(
          color: Colors.green,
          fontSize: 13,
          fontWeight: FontWeight.bold,
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
            child: Row(
              children: [
                Text(
                  'Week $weekNumber',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '(${entries.length} ${entries.length == 1 ? 'entry' : 'entries'})',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
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
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LogbookEntryDetail(
              student: widget.student,
              entry: entry,
              weekNumber: weekNumber,
            ),
          ),
        );

        // Reload logs if entry was updated
        if (result == true) {
          _loadStudentLogs();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: entry.status == EntryStatus.pending
              ? Border.all(color: Colors.orange.withOpacity(0.3), width: 2)
              : null,
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
              DateFormat('MMMM d, yyyy').format(entry.date),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (entry.attachmentCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attachment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.attachmentCount} ${entry.attachmentCount == 1 ? 'attachment' : 'attachments'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Logbook Entry Model
class LogbookEntry {
  final int id;
  final DateTime date;
  final String dayOfWeek;
  final String tasksCompleted;
  final EntryStatus status;
  final String? feedback;
  final List<dynamic> attachments;
  final int attachmentCount;
  final String? skillsAcquired;
  final String? challengesFaced;

  LogbookEntry({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.tasksCompleted,
    required this.status,
    this.feedback,
    this.attachments = const [],
    this.attachmentCount = 0,
    this.skillsAcquired,
    this.challengesFaced,
  });
}

enum EntryStatus { pending, approved, rejected }
