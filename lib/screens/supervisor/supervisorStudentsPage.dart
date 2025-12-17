import 'package:flutter/material.dart';
import 'package:siwes360/screens/supervisor/studentLogbookView.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/supervisorbottomNavBar.dart';

class SupervisorStudentsPage extends StatefulWidget {
  const SupervisorStudentsPage({super.key});

  @override
  State<SupervisorStudentsPage> createState() => _SupervisorStudentsPageState();
}

class _SupervisorStudentsPageState extends State<SupervisorStudentsPage> {
  String _selectedFilter = 'All Students';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load user data from storage
      final userData = await RequestService.loadUserData();

      if (userData == null || userData['role_data'] == null) {
        setState(() {
          _errorMessage = 'User data not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final supervisorId = userData['role_data']['user_id'];

      // Fetch students from API
      final result = await RequestService.getSupervisorStudents(supervisorId);

      if (result != null && result['status'] == 'success') {
        setState(() {
          _students = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Failed to load students';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading students: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  StudentStatus _getStudentStatus(Map<String, dynamic> student) {
    final pendingLogs = student['pending_logs'] ?? 0;
    final totalLogs = student['total_logs'] ?? 0;

    if (pendingLogs > 0) {
      return StudentStatus.newEntries;
    } else if (totalLogs > 0) {
      return StudentStatus.upToDate;
    } else {
      return StudentStatus.upToDate;
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    List<Map<String, dynamic>> filtered = _students;

    // Apply filter
    if (_selectedFilter == 'Review Needed') {
      filtered = filtered.where((s) {
        final status = _getStudentStatus(s);
        return status == StudentStatus.newEntries ||
            status == StudentStatus.pendingApproval;
      }).toList();
    } else if (_selectedFilter == 'Up to Date') {
      filtered = filtered.where((s) {
        final status = _getStudentStatus(s);
        return status == StudentStatus.upToDate;
      }).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final name = (s['full_name'] ?? '').toLowerCase();
        final matric = (s['matric_no'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || matric.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - removed refresh button
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'My Students',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('All Students'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Review Needed'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Up to Date'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A3D62),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
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
                            onPressed: _loadStudents,
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
                  : _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No students found'
                                : 'No students assigned yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      color: const Color(0xFF0A3D62),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          return _buildStudentCard(_filteredStudents[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A3D62) : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> studentData) {
    final status = _getStudentStatus(studentData);
    final pendingLogs = studentData['pending_logs'] ?? 0;

    // Create Student object for navigation
    final student = Student(
      userId: studentData['user_id'],
      name: studentData['full_name'] ?? 'Unknown',
      matric: studentData['matric_no'] ?? 'N/A',
      department: studentData['department'] ?? 'N/A',
      imageUrl: 'assets/images/avatar.jpeg',
      status: status,
      newEntriesCount: pendingLogs > 0 ? pendingLogs : null,
      isOnline: false, // TODO: Implement online status tracking
    );

    return GestureDetector(
      onTap: () async {
        // Navigate and reload on return
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentLogbookView(student: student),
          ),
        );

        // Reload students list if logbook was updated
        if (result == true) {
          _loadStudents();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A3D62),
              ),
              child: Center(
                child: Text(
                  student.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.matric} • ${student.department}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(student),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Student student) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    switch (student.status) {
      case StudentStatus.newEntries:
        bgColor = const Color(0xFF0A3D62).withOpacity(0.1);
        textColor = const Color(0xFF0A3D62);
        icon = Icons.fiber_manual_record;
        text = '${student.newEntriesCount} New Entries';
        break;
      case StudentStatus.upToDate:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        text = 'Up to date';
        break;
      case StudentStatus.pendingApproval:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.access_time;
        text = 'Pending Approval';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Student Model
class Student {
  final int userId;
  final String name;
  final String matric;
  final String department;
  final String imageUrl;
  final StudentStatus status;
  final int? newEntriesCount;
  final bool isOnline;

  Student({
    required this.userId,
    required this.name,
    required this.matric,
    required this.department,
    required this.imageUrl,
    required this.status,
    this.newEntriesCount,
    required this.isOnline,
  });
}

enum StudentStatus { newEntries, upToDate, pendingApproval }
