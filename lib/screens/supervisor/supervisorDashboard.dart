import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siwes360/screens/supervisor/logbookEntryDetail.dart';
import 'package:siwes360/screens/supervisor/studentLogbookView.dart';
import 'package:siwes360/screens/supervisor/supervisorStudentsPage.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/supervisorbottomNavBar.dart';
import 'package:siwes360/screens/supervisor/supervisorNotifications.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String _errorMessage = '';
  int _unreadNotificationCount = 0; // Add this

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUnreadNotificationCount(); // Add this
  }

  // Add this new method
  Future<void> _loadUnreadNotificationCount() async {
    try {
      final userData = await RequestService.loadUserData();
      if (userData != null && userData['role_data'] != null) {
        final supervisorId = userData['role_data']['user_id'];
        final result = await RequestService.getNotifications(supervisorId);

        if (result != null && result['status'] == 'success') {
          final notifications = result['data'] as List? ?? [];
          final unreadCount = notifications
              .where((n) => n['is_read'] == 0 || n['is_read'] == false)
              .length;

          setState(() {
            _unreadNotificationCount = unreadCount;
          });
        }
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  // Update _loadDashboardData to also refresh notification count
  Future<void> _loadDashboardData() async {
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

      final result = await RequestService.getSupervisorDashboardData(
        supervisorId,
      );

      if (result != null && result['status'] == 'success') {
        setState(() {
          _dashboardData = result['data'];
          _isLoading = false;
        });

        // Refresh notification count after loading dashboard
        _loadUnreadNotificationCount();
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Failed to load dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _parseStatValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('MMM d').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0A3D62)),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 0),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadDashboardData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3D62),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 0),
      );
    }

    // Extract data
    final supervisor = _dashboardData?['supervisor'];
    final statistics = _dashboardData?['statistics'];
    final recentApprovals = _dashboardData?['recent_approvals'] as List? ?? [];

    final totalStudents = _parseStatValue(statistics?['total_students']);
    final pendingApprovals = _parseStatValue(statistics?['pending_approvals']);
    final completedReviews = _parseStatValue(statistics?['completed_reviews']);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF0A3D62),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/avatar.jpeg',
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${supervisor?['full_name']?.split(' ').first ?? 'Supervisor'}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (supervisor?['position'] != null)
                              Text(
                                supervisor!['position'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () async {
                              // Navigate and refresh count when returning
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SupervisorNotifications(),
                                ),
                              );
                              // Refresh notification count after returning
                              _loadUnreadNotificationCount();
                            },
                          ),
                          // Show unread notification count instead of pending approvals
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _unreadNotificationCount > 9
                                      ? '9+'
                                      : '$_unreadNotificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Stats Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          label: 'Assigned\nStudents',
                          value: totalStudents.toString(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          label: 'Pending\nApprovals',
                          value: pendingApprovals.toString(),
                          isOrange: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Completed Reviews Card
                  _buildStatCard(
                    label: 'Completed Reviews',
                    value: completedReviews.toString(),
                    fullWidth: true,
                  ),

                  const SizedBox(height: 30),

                  // Pending Approvals Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (recentApprovals.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // TODO: View all pending approvals
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Color(0xFF0A3D62)),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pending Approvals List
                  if (recentApprovals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending approvals',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All caught up! 🎉',
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
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentApprovals.length,
                        itemBuilder: (context, index) {
                          final approval = recentApprovals[index];
                          return _buildPendingApprovalCard(approval);
                        },
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Quick Stats Section
                  const Text(
                    'Quick Stats',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildQuickStatRow(
                          'Total Students',
                          totalStudents.toString(),
                          Icons.people_outline,
                          Colors.blue,
                        ),
                        const Divider(height: 24),
                        _buildQuickStatRow(
                          'Pending Reviews',
                          pendingApprovals.toString(),
                          Icons.pending_outlined,
                          Colors.orange,
                        ),
                        const Divider(height: 24),
                        _buildQuickStatRow(
                          'Completed Reviews',
                          completedReviews.toString(),
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                        const Divider(height: 24),
                        _buildQuickStatRow(
                          'Total Reviews',
                          (pendingApprovals + completedReviews).toString(),
                          Icons.assessment_outlined,
                          const Color(0xFF0A3D62),
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
      ),
      bottomNavigationBar: const SupervisorBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    bool fullWidth = false,
    bool isOrange = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOrange ? const Color(0xFFFFE4CC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOrange ? Colors.orange[300]! : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isOrange ? Colors.orange[800] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF0A3D62)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalCard(Map<String, dynamic> approval) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Avatar
          Container(
            height: 120, // Reduced from 140
            decoration: BoxDecoration(
              color: const Color(0xFF0A3D62).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Center(
              child: CircleAvatar(
                radius: 40, // Reduced from 50
                backgroundColor: const Color(0xFF0A3D62),
                child: Text(
                  (approval['student_name'] ?? 'S')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32, // Reduced from 40
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            // Wrap in Expanded to prevent overflow
            child: SingleChildScrollView(
              // Add scrolling for long content
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approval['student_name'] ?? 'Unknown Student',
                      style: const TextStyle(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approval['matric_no'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 11, // Reduced from 12
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDate(approval['log_date']),
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (approval['description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        approval['description'],
                        style: TextStyle(
                          fontSize: 12, // Reduced from 13
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to log review page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D62),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ), // Reduced from 14
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15, // Reduced from 16
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
