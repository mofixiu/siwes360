import 'package:flutter/material.dart';
import 'package:siwes360/widgets/supervisorbottomNavBar.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  // Sample data for pending approvals
  final List<PendingApproval> _pendingApprovals = [
    PendingApproval(
      studentName: 'David Okon',
      weekNumber: 8,
      imageUrl: 'assets/images/avatar.jpeg',
      matric: 'FOU/23/1234',
    ),
    PendingApproval(
      studentName: 'Chioma Adebayo',
      weekNumber: 7,
      imageUrl: 'assets/images/avatar.jpeg',
      matric: 'FOU/23/5678',
    ),
    PendingApproval(
      studentName: 'Ebo Mofiyinfoluwa',
      weekNumber: 6,
      imageUrl: 'assets/images/avatar.jpeg',
      matric: 'FOU/23/9012',
    ),
  ];

  // Sample data for recent activity
  final List<ActivityItem> _recentActivity = [
    ActivityItem(
      type: ActivityType.approval,
      title: "You approved Chioma Adebayo's entry.",
      timestamp: '2 hours ago',
    ),
    ActivityItem(
      type: ActivityType.submission,
      title: 'David Okon submitted his monthly report.',
      timestamp: 'Yesterday, 9:41 PM',
    ),
    ActivityItem(
      type: ActivityType.message,
      title: 'New message from the ITF coordinator.',
      timestamp: '2 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Dr. Anya',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
                        value: '12',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Pending\nApprovals',
                        value: '5',
                        isOrange: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Completed Reviews Card
                _buildStatCard(
                  label: 'Completed Reviews',
                  value: '28',
                  fullWidth: true,
                ),

                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.people_outline,
                      label: 'Students',
                      onTap: () {},
                    ),
                    _buildActionButton(
                      icon: Icons.search,
                      label: 'Search',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Pending Approvals Section
                const Text(
                  'Pending Approvals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // Pending Approvals List
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingApprovals.length,
                    itemBuilder: (context, index) {
                      return _buildPendingApprovalCard(
                        _pendingApprovals[index],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Recent Activity Section
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // Recent Activity List
                ..._recentActivity.map((activity) {
                  return _buildActivityItem(activity);
                }),

                const SizedBox(height: 100),
              ],
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

  Widget _buildPendingApprovalCard(PendingApproval approval) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Image
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                approval.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Week ${approval.weekNumber} Submission',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D62),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Review',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    IconData icon;
    Color iconColor;

    switch (activity.type) {
      case ActivityType.approval:
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case ActivityType.submission:
        icon = Icons.description_outlined;
        iconColor = const Color(0xFF0A3D62);
        break;
      case ActivityType.message:
        icon = Icons.email_outlined;
        iconColor = Colors.orange;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timestamp,
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

// Models
class PendingApproval {
  final String studentName;
  final int weekNumber;
  final String imageUrl;
  final String matric;

  PendingApproval({
    required this.studentName,
    required this.weekNumber,
    required this.imageUrl,
    required this.matric,
  });
}

class ActivityItem {
  final ActivityType type;
  final String title;
  final String timestamp;

  ActivityItem({
    required this.type,
    required this.title,
    required this.timestamp,
  });
}

enum ActivityType { approval, submission, message }
