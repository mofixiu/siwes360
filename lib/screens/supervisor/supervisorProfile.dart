import 'dart:io';
import 'package:flutter/material.dart';
import 'package:siwes360/screens/supervisor/editSupervisorProfile.dart';
import 'package:siwes360/screens/supervisor/supervisorSettings.dart';
import 'package:siwes360/utils/custom_page_route.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/supervisorbottomNavBar.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SupervisorProfile extends StatefulWidget {
  const SupervisorProfile({super.key});

  @override
  State<SupervisorProfile> createState() => _SupervisorProfileState();
}

class _SupervisorProfileState extends State<SupervisorProfile> {
  String _selectedTab = 'students';
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _institutions = [];
  String _errorMessage = '';
  String _bio = '';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBio();
  }

  Future<void> _loadProfileImage() async {
    try {
      final userData = await RequestService.loadUserData();
      if (userData != null && userData['role_data'] != null) {
        final supervisorId = userData['role_data']['user_id'];
        final box = await Hive.openBox('supervisorProfile');
        final imagePath = box.get('profile_image_$supervisorId');

        if (imagePath != null && await File(imagePath).exists()) {
          setState(() {
            _profileImagePath = imagePath;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userData = await RequestService.loadUserData();

      if (userData == null || userData['role_data'] == null) {
        setState(() {
          _errorMessage = 'User data not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final supervisorId = userData['role_data']['user_id'];
      final result = await RequestService.getSupervisorById(supervisorId);

      if (result != null && result['status'] == 'success') {
        setState(() {
          _profileData = result['data'];
        });

        await _loadStudents(supervisorId);
        await _loadProfileImage();
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents(int supervisorId) async {
    try {
      final result = await RequestService.getSupervisorStudents(supervisorId);

      if (result != null && result['status'] == 'success') {
        final students = List<Map<String, dynamic>>.from(result['data'] ?? []);

        // Group students by institution
        Map<String, int> institutionCounts = {};
        for (var student in students) {
          final school = student['school_name'] ?? 'Unknown Institution';
          institutionCounts[school] = (institutionCounts[school] ?? 0) + 1;
        }

        // Create institutions list
        final institutions = institutionCounts.entries.map((entry) {
          return {
            'name': entry.key,
            'studentCount': entry.value,
            'icon': Icons.school,
          };
        }).toList();

        setState(() {
          _students = students;
          _institutions = institutions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBio() async {
    try {
      final box = await Hive.openBox('supervisorData');
      final savedBio = box.get('bio', defaultValue: '');
      setState(() {
        _bio = savedBio;
      });
    } catch (e) {
      print('Error loading bio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
        ),
        bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 2),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
        body: Center(
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
                onPressed: _loadProfile,
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
        ),
        bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 2),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: const Color(0xFF0A3D62),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                          context.pushFade(const SupervisorSettings());
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
                      // Profile Picture with Image Support
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A3D62),
                        ),
                        child: ClipOval(
                          child: _profileImagePath != null
                              ? Image.file(
                                  File(_profileImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        (_profileData?['full_name'] ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    (_profileData?['full_name'] ?? 'U')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        _profileData?['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Position
                      Text(
                        _profileData?['position'] ?? 'Industry Supervisor',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileData?['organization'] ?? 'N/A',
                        style: const TextStyle(
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
                          onPressed: () async {
                            final result = await context.pushFade(
                              EditSupervisorProfile(
                                supervisorId: _profileData!['user_id'],
                              ),
                            );

                            // Reload profile if changes were saved
                            if (result == true && mounted) {
                              _loadProfile();
                              _loadBio();
                            }
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
                        _profileData?['email'] ?? 'N/A',
                        Colors.grey[200]!,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Phone Number',
                        _profileData?['phone'] ?? 'N/A',
                        Colors.grey[200]!,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoRow(
                        Icons.work_outline,
                        'Position',
                        _profileData?['position'] ?? 'N/A',
                        Colors.grey[200]!,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoRow(
                        Icons.business_outlined,
                        'Organization',
                        _profileData?['organization'] ?? 'N/A',
                        Colors.grey[200]!,
                      ),

                      // Show bio if available
                      if (_bio.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            _bio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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
                      Row(
                        children: [
                          const Text(
                            'Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A3D62).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_students.length} ${_students.length == 1 ? 'Student' : 'Students'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A3D62),
                              ),
                            ),
                          ),
                        ],
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

                      // Content based on selected tab
                      if (_selectedTab == 'students')
                        _students.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No students assigned yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: _students.map((student) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildStudentTile(
                                      student['full_name'] ?? 'Unknown',
                                      student['matric_no'] ?? 'N/A',
                                      student['school_name'] ??
                                          'Unknown Institution',
                                      student['department'] ?? '',
                                    ),
                                  );
                                }).toList(),
                              )
                      else
                        _institutions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No institutions yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: _institutions.map((institution) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildInstitutionTile(
                                      institution['name']!,
                                      institution['studentCount']!,
                                      institution['icon']!,
                                    ),
                                  );
                                }).toList(),
                              ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
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
    String matric,
    String school,
    String department,
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0A3D62),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                  '$matric ${department.isNotEmpty ? '• $department' : ''}',
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
                    Expanded(
                      child: Text(
                        school,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
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
