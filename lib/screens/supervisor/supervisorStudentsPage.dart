import 'package:flutter/material.dart';
import 'package:siwes360/screens/supervisor/studentLogbookView.dart';
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

  final List<Student> _students = [
    Student(
      name: 'John Doe',
      matric: 'CS/2021/045',
      department: 'Computer Science',
      imageUrl: 'assets/images/avatar.jpeg',
      status: StudentStatus.newEntries,
      newEntriesCount: 3,
      isOnline: true,
    ),
    Student(
      name: 'Sarah Smith',
      matric: 'EN/2021/112',
      department: 'Engineering',
      imageUrl: 'assets/images/avatar.jpeg',
      status: StudentStatus.upToDate,
      isOnline: false,
    ),
    Student(
      name: 'Michael Obi',
      matric: 'MC/2021/008',
      department: 'Mass Comm',
      imageUrl: 'assets/images/avatar.jpeg',
      status: StudentStatus.pendingApproval,
      isOnline: false,
    ),
    Student(
      name: 'Amara Kalu',
      matric: 'EC/2021/092',
      department: 'Economics',
      imageUrl: 'assets/images/avatar.jpeg',
      status: StudentStatus.newEntries,
      newEntriesCount: 1,
      isOnline: false,
    ),
  ];

  List<Student> get _filteredStudents {
    List<Student> filtered = _students;

    // Apply filter
    if (_selectedFilter == 'Review Needed') {
      filtered = filtered
          .where(
            (s) =>
                s.status == StudentStatus.newEntries ||
                s.status == StudentStatus.pendingApproval,
          )
          .toList();
    } else if (_selectedFilter == 'Up to Date') {
      filtered = filtered
          .where((s) => s.status == StudentStatus.upToDate)
          .toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.matric.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
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
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Students',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ],
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
              child: _filteredStudents.isEmpty
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
                            'No students found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(_filteredStudents[index]);
                      },
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

  Widget _buildStudentCard(Student student) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentLogbookView(student: student),
          ),
        );
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
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      student.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey[600],
                        );
                      },
                    ),
                  ),
                ),
                if (student.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
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
  final String name;
  final String matric;
  final String department;
  final String imageUrl;
  final StudentStatus status;
  final int? newEntriesCount;
  final bool isOnline;

  Student({
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
