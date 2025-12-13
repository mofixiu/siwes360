import 'package:flutter/material.dart';
import 'package:siwes360/screens/supervisor/editSupervisorProfile.dart';
import 'package:siwes360/screens/supervisor/supervisorSettings.dart';
import 'package:siwes360/widgets/supervisorbottomNavBar.dart';

class SupervisorProfile extends StatefulWidget {
  const SupervisorProfile({super.key});

  @override
  State<SupervisorProfile> createState() => _SupervisorProfileState();
}

class _SupervisorProfileState extends State<SupervisorProfile> {
  String _selectedTab = 'students'; // 'students' or 'institutions'

  // Sample data for students
  final List<Map<String, String>> _students = [
    {
      'name': 'Adekunle Adebayo',
      'id': '123456',
      'school': 'Covenant University',
      'image': 'assets/images/avatar.jpeg',
    },
    {
      'name': 'Chiamaka Nwosu',
      'id': '654321',
      'school': 'University of Lagos',
      'image': 'assets/images/avatar.jpeg',
    },
    {
      'name': 'David Okon',
      'id': '789012',
      'school': 'Covenant University',
      'image': 'assets/images/avatar.jpeg',
    },
  ];

  // Sample data for associated institutions
  final List<Map<String, dynamic>> _institutions = [
    {'name': 'Covenant University', 'studentCount': 2, 'icon': Icons.school},
    {'name': 'University of Lagos', 'studentCount': 1, 'icon': Icons.school},
  ];

  List<Map<String, String>> get _filteredStudents {
    return _students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF0A3D62),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SupervisorSettings(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Profile Picture with edit button
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange[100],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/avatar.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0A3D62),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    const Text(
                      'Dr. Amina Bello',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Designation
                    Text(
                      'Industry Supervisor',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Innovatech Solutions Ltd.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A3D62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditSupervisorProfile(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3D62),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Personal Details Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      'amina.bello@innovatech.com',
                      Colors.grey[200]!,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone Number',
                      '+234 801 234 5678',
                      Colors.grey[200]!,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      Icons.business_outlined,
                      'Position',
                      'Senior Software Engineer',
                      Colors.grey[200]!,
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Office Location',
                      'Block A, Floor 3, Room 305',
                      Colors.grey[200]!,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Management Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 'students';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'students'
                                      ? const Color(0xFF0A3D62)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Intern Students',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 'students'
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 'institutions';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'institutions'
                                      ? const Color(0xFF0A3D62)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Institutions',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 'institutions'
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search Bar (only for students tab)
                    if (_selectedTab == 'students')
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                    if (_selectedTab == 'students') const SizedBox(height: 16),

                    // Content based on selected tab
                    if (_selectedTab == 'students')
                      ..._filteredStudents.map((student) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildStudentTile(
                            student['name']!,
                            'ID: ${student['id']}',
                            student['school']!,
                            student['image']!,
                          ),
                        );
                      })
                    else
                      ..._institutions.map((institution) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInstitutionTile(
                            institution['name']!,
                            institution['studentCount']!,
                            institution['icon']!,
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color backgroundColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.black54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(
    String name,
    String id,
    String school,
    String imageUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: ClipOval(
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: 22, color: Colors.grey[600]);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  id,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      school,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionTile(String name, int studentCount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A3D62).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF0A3D62)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$studentCount student${studentCount > 1 ? 's' : ''} interning',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
