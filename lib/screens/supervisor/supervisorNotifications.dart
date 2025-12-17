import 'package:flutter/material.dart';
import 'package:siwes360/utils/request.dart';

class SupervisorNotifications extends StatefulWidget {
  const SupervisorNotifications({super.key});

  @override
  State<SupervisorNotifications> createState() =>
      _SupervisorNotificationsState();
}

class _SupervisorNotificationsState extends State<SupervisorNotifications>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<NotificationItem> _allNotifications = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
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
      final result = await RequestService.getNotifications(supervisorId);

      if (result != null && result['status'] == 'success') {
        final notificationsList = result['data'] as List? ?? [];

        setState(() {
          _allNotifications = notificationsList.map((notification) {
            return NotificationItem(
              id: notification['id'],
              type: _getNotificationType(
                notification['type'] ?? notification['message'],
              ),
              title: _getNotificationTitle(
                notification['type'] ?? notification['message'],
              ),
              message: notification['message'],
              timestamp: DateTime.parse(notification['created_at']),
              isRead:
                  notification['is_read'] == 1 ||
                  notification['is_read'] == true,
            );
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading notifications: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  NotificationType _getNotificationType(String typeOrMessage) {
    final lower = typeOrMessage.toLowerCase();
    if (lower.contains('submitted') || lower.contains('logbook')) {
      return NotificationType.logbook;
    } else if (lower.contains('student') || lower.contains('assigned')) {
      return NotificationType.student;
    } else if (lower.contains('review') || lower.contains('pending')) {
      return NotificationType.review;
    } else if (lower.contains('reminder') || lower.contains('due')) {
      return NotificationType.reminder;
    } else {
      return NotificationType.system;
    }
  }

  String _getNotificationTitle(String typeOrMessage) {
    final lower = typeOrMessage.toLowerCase();
    if (lower.contains('submitted')) return 'New Logbook Submission';
    if (lower.contains('student')) return 'Student Assignment';
    if (lower.contains('review')) return 'Review Required';
    if (lower.contains('pending')) return 'Pending Action';
    if (lower.contains('reminder')) return 'Reminder';
    return 'Notification';
  }

  List<NotificationItem> get _unreadNotifications =>
      _allNotifications.where((n) => !n.isRead).toList();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(int id) async {
    try {
      await RequestService.markNotificationAsRead(id);
      setState(() {
        final notification = _allNotifications.firstWhere((n) => n.id == id);
        notification.isRead = true;
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userData = await RequestService.loadUserData();
      if (userData != null && userData['role_data'] != null) {
        final supervisorId = userData['role_data']['user_id'];
        await RequestService.markAllNotificationsAsRead(supervisorId);

        setState(() {
          for (var notification in _allNotifications) {
            notification.isRead = true;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      await RequestService.deleteNotification(id);
      setState(() {
        _allNotifications.removeWhere((n) => n.id == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
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
                  onPressed: _loadNotifications,
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 232, 1),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF0A3D62)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A3D62),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0A3D62),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Unread'),
                  if (_unreadNotifications.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A3D62),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_unreadNotifications.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFF0A3D62),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Unread tab
            _unreadNotifications.isEmpty
                ? _buildEmptyState('No unread notifications')
                : _buildNotificationList(_unreadNotifications),
            // All tab
            _allNotifications.isEmpty
                ? _buildEmptyState('No notifications yet')
                : _buildNotificationList(_allNotifications),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _getNotificationIcon(notification.type),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.bold,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A3D62),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                notification.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
          },
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.logbook:
        icon = Icons.description_outlined;
        color = const Color(0xFF0A3D62);
        break;
      case NotificationType.student:
        icon = Icons.person_add_outlined;
        color = Colors.blue;
        break;
      case NotificationType.review:
        icon = Icons.rate_review_outlined;
        color = Colors.orange;
        break;
      case NotificationType.reminder:
        icon = Icons.notifications_active_outlined;
        color = Colors.red;
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// Notification Model
class NotificationItem {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });
}

enum NotificationType { logbook, student, review, reminder, system }
