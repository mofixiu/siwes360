import 'package:flutter/material.dart';
import 'package:siwes360/screens/shared/notifications.dart';
import 'package:siwes360/screens/supervisor/supervisor_nav.dart';
import 'package:siwes360/screens/supervisor/week_review.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';

/// The supervisor's work, a student-week at a time: weeks with entries to review,
/// then weeks ready for the weekly sign-off. Stats sit on one line above.
class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  bool _loading = true;
  String? _error;
  Session? _session;
  Map<String, dynamic> _queue = {};
  int _unread = 0;
  String? _photo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _queue.isEmpty;
      _error = null;
    });
    final session = await Session.load();
    if (session == null) {
      if (mounted) Session.signOut(context);
      return;
    }
    final results = await Future.wait([
      RequestService.getSupervisorQueue(session.id),
      RequestService.getNotifications(session.id),
    ]);
    final photo = await Session.photoPath('supervisor', session.id);
    if (!mounted) return;
    if (results[0]?['status'] != 'success') {
      setState(() {
        _loading = false;
        _error = results[0]?['message'] ?? 'Check your connection and try again.';
      });
      return;
    }
    final notes = results[1]?['status'] == 'success' ? results[1]!['data'] as List : const [];
    setState(() {
      _loading = false;
      _session = session;
      _queue = Map<String, dynamic>.from(results[0]!['data']);
      _unread = notes.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
      _photo = photo;
    });
  }

  Future<void> _openWeek(Map<String, dynamic> group) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WeekReviewScreen(
          studentId: (group['student_id'] as num).toInt(),
          studentName: '${group['full_name']}',
          matricNo: group['matric_no'],
          week: (group['week_number'] as num).toInt(),
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const SupervisorNavBar(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(color: Palette.ink, onRefresh: _load, child: _body()),
      ),
    );
  }

  Widget _body() {
    final stats = Map<String, dynamic>.from(_queue['stats'] ?? {});
    final review = List<Map<String, dynamic>>.from((_queue['review'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    final sign = List<Map<String, dynamic>>.from((_queue['sign'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    final pending = (stats['pending_entries'] as num?)?.toInt() ?? 0;
    final toSign = (stats['weeks_to_sign'] as num?)?.toInt() ?? 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.sm, 0),
          child: Row(
            children: [
              Monogram(name: _session?.fullName, size: 36, photoPath: _photo),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_session?.fullName ?? '', style: Txt.sans(Txt.small, weight: FontWeight.w600)),
                    Text(Dates.short(today()), style: Txt.mono(Txt.label, color: Palette.inkSoft)),
                  ],
                ),
              ),
              IconButton(
                tooltip: _unread > 0 ? 'Notifications, $_unread unread' : 'Notifications',
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  _load();
                },
                icon: Badge(
                  isLabelVisible: _unread > 0,
                  backgroundColor: Palette.brick,
                  smallSize: 7,
                  child: const Icon(Icons.notifications_none, color: Palette.ink),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
          child: Text(
            pending == 0 && toSign == 0 ? 'All reviewed' : 'Logbooks to review',
            style: Txt.displayStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 0),
          child: FigureLine([
            Figure('${stats['students'] ?? 0}', 'students'),
            Figure('$pending', 'to review', color: pending > 0 ? Palette.ochre : Palette.ink),
            Figure('$toSign', toSign == 1 ? 'week to sign' : 'weeks to sign'),
          ]),
        ),
        SectionLabel('Entries to review', padding: const EdgeInsets.fromLTRB(Space.page, Space.xxl, Space.page, Space.sm)),
        const Rule(),
        if (review.isEmpty) const EmptyNote('Nothing waiting for review', detail: 'New entries from your students appear here.'),
        for (final g in review) _groupRow(g, '${plural((g['pending'] as num).toInt(), 'entry', 'entries')} to review'),
        const SectionLabel('Ready to sign off'),
        const Rule(),
        if (_queue['signoffs_available'] == false)
          const EmptyNote('Weekly sign-off is not set up on the server yet')
        else if (sign.isEmpty)
          const EmptyNote('No weeks waiting for your signature', detail: 'A week is ready once every entry in it is reviewed, from its Friday.')
        else
          for (final g in sign) _groupRow(g, '${g['approved']} approved', sign: true),
      ],
    );
  }

  Widget _groupRow(Map<String, dynamic> g, String count, {bool sign = false}) {
    final start = parseDay(g['week_start'])!;
    return LedgerRow(
      onTap: () => _openWeek(g),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${g['full_name']} · Week ${g['week_number']}', style: Txt.sans(Txt.body, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            '${Dates.range(start, start.add(const Duration(days: 4)))} · $count',
            style: Txt.mono(Txt.small, color: sign ? Palette.inkSoft : Palette.ochre),
          ),
        ],
      ),
    );
  }
}
