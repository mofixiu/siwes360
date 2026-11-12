import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';

/// Notifications for any role: unread first in ink, read in grey, swipe to delete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  int? _userId;
  List<Map<String, dynamic>> _items = [];
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await Session.load();
    if (session == null) return;
    _userId = session.id;
    final result = await RequestService.getNotifications(session.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?['status'] == 'success') {
        _error = null;
        _items = List<Map<String, dynamic>>.from((result!['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  bool _isRead(Map<String, dynamic> n) => n['is_read'] == 1 || n['is_read'] == true;

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (_isRead(n)) return;
    setState(() => n['is_read'] = 1);
    await RequestService.markNotificationAsRead(n['id']);
  }

  Future<void> _markAllRead() async {
    if (_userId == null) return;
    setState(() {
      for (final n in _items) {
        n['is_read'] = 1;
      }
    });
    await RequestService.markAllNotificationsAsRead(_userId!);
  }

  Future<void> _delete(Map<String, dynamic> n) async {
    setState(() => _items.remove(n));
    final result = await RequestService.deleteNotification(n['id']);
    if (mounted && result?['status'] != 'success') {
      showNote(context, 'Could not delete the notification', error: true);
      _load();
    }
  }

  // Short word for the kind of notification, as the API types them.
  String _kind(String? type) => switch (type) {
        'logbook' => 'NEW ENTRY',
        'approval' => 'APPROVED',
        'rejection' => 'RETURNED',
        'signoff' => 'SIGNED OFF',
        _ => 'NOTICE',
      };

  Color _kindColor(String? type) => switch (type) {
        'approval' || 'signoff' => Palette.olive,
        'rejection' => Palette.brick,
        'logbook' => Palette.ochre,
        _ => Palette.inkSoft,
      };

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !_isRead(n)).length;
    final visible = _unreadOnly ? _items.where((n) => !_isRead(n)).toList() : _items;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Notifications'),
        actions: [
          if (unread > 0) TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: Palette.ink,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.page - Space.sm, Space.sm, Space.page, Space.sm),
                        child: Row(
                          children: [
                            for (final (only, label) in [(false, 'All ${_items.length}'), (true, 'Unread $unread')])
                              TextButton(
                                onPressed: () => setState(() => _unreadOnly = only),
                                style: TextButton.styleFrom(
                                  foregroundColor: _unreadOnly == only ? Palette.ink : Palette.inkSoft,
                                  textStyle: Txt.sans(Txt.small, weight: _unreadOnly == only ? FontWeight.w700 : FontWeight.w500),
                                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(label),
                              ),
                          ],
                        ),
                      ),
                      const Rule(),
                      if (visible.isEmpty)
                        EmptyNote(_unreadOnly ? 'No unread notifications' : 'No notifications yet'),
                      for (final n in visible)
                        Dismissible(
                          key: ValueKey(n['id']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _delete(n),
                          background: Container(
                            color: Palette.brick,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: Space.page),
                            child: Text('Delete', style: Txt.sans(Txt.small, weight: FontWeight.w600, color: Colors.white)),
                          ),
                          child: LedgerRow(
                            onTap: () => _markRead(n),
                            showChevron: false,
                            leading: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRead(n) ? Colors.transparent : Palette.ink,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _kind(n['type']),
                                      style: Txt.sans(Txt.label, weight: FontWeight.w700, color: _kindColor(n['type']))
                                          .copyWith(letterSpacing: 0.9),
                                    ),
                                    const Spacer(),
                                    Text(_when(n['created_at']), style: Txt.mono(Txt.label, color: Palette.inkFaint)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${n['message']}',
                                  style: Txt.sans(
                                    Txt.small,
                                    weight: _isRead(n) ? FontWeight.w400 : FontWeight.w500,
                                    color: _isRead(n) ? Palette.inkSoft : Palette.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _when(dynamic createdAt) {
    final text = '${createdAt ?? ''}';
    final at = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return Dates.short(at);
  }
}
