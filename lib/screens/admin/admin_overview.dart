import 'package:flutter/material.dart';
import 'package:siwes360/screens/admin/admin_students.dart';
import 'package:siwes360/screens/admin/admin_supervisors.dart';
import 'package:siwes360/screens/shared/settings.dart';
import 'package:siwes360/screens/shared/student_list.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';
import 'package:siwes360/widgets/paper_nav_bar.dart';

class AdminNavBar extends StatelessWidget {
  const AdminNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static final items = [
    NavItem('Overview', Icons.dashboard_outlined, Icons.dashboard, (_) => const AdminOverview()),
    NavItem('Students', Icons.school_outlined, Icons.school, (_) => const AdminStudents()),
    NavItem('Supervisors', Icons.badge_outlined, Icons.badge, (_) => const AdminSupervisors()),
  ];

  @override
  Widget build(BuildContext context) => PaperNavBar(items: items, currentIndex: currentIndex);
}

/// The institution's SIWES coordinator: who is placed and logging, who has
/// fallen behind, last week's sign-offs, and which supervisors have work waiting.
/// Only this institution's students.
class AdminOverview extends StatefulWidget {
  const AdminOverview({super.key});

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await RequestService.getAdminOverview();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?['status'] == 'success') {
        _error = null;
        _data = Map<String, dynamic>.from(result!['data']);
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  void _openStudents(StudentFilter filter) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminStudents(initialFilter: filter, pushed: true)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AdminNavBar(currentIndex: 0),
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
    final t = Map<String, dynamic>.from(_data['totals'] ?? {});
    final lastWeek = Map<String, dynamic>.from(_data['last_week'] ?? {});
    final behind = List<Map<String, dynamic>>.from((_data['behind'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    final supervisors = List<Map<String, dynamic>>.from((_data['supervisors'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    final school = Map<String, dynamic>.from(_data['school'] ?? {});
    int n(String key) => (t[key] as num?)?.toInt() ?? 0;
    final due = (lastWeek['due'] as num?)?.toInt() ?? 0;
    final signed = (lastWeek['signed'] as num?)?.toInt() ?? 0;
    final behindAfter = _data['rules']?['behind_after_working_days'] ?? 3;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        PageHeader(
          title: '${school['name'] ?? 'Your institution'}',
          subtitle: Text(
            'SIWES OFFICE · ${Dates.short(today()).toUpperCase()}',
            style: Txt.mono(Txt.small, weight: FontWeight.w500, color: Palette.inkSoft),
          ),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined, color: Palette.ink),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
          child: FigureLine([
            Figure('${n('students')}', 'students'),
            Figure('${n('logging')}', 'logging', color: Palette.olive),
            Figure('${n('behind')}', 'behind', color: n('behind') > 0 ? Palette.brick : Palette.ink),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
          child: Text(
            '${n('placed')} placed · ${n('not_set_up')} not set up · ${n('no_supervisor')} without a supervisor',
            style: Txt.mono(Txt.label, color: Palette.inkSoft),
          ),
        ),

        const SectionLabel("Last week's sign-off"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: _data['signoffs_available'] == false
              ? Text('Weekly sign-off is not set up on the server yet.', style: Txt.smallStyle)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$signed of $due weeks signed', style: Txt.mono(Txt.body, weight: FontWeight.w500)),
                    const SizedBox(height: Space.sm),
                    LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(height: 3, color: Palette.rule),
                          Container(height: 3, width: due == 0 ? 0 : c.maxWidth * signed / due, color: Palette.olive),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      '${n('unsigned_weeks')} finished weeks across all students still need a signature.',
                      style: Txt.smallStyle,
                    ),
                  ],
                ),
        ),

        SectionLabel(
          'Behind on logs',
          trailing: n('behind') > 0 ? InlineLink('See all ${n('behind')}', onTap: () => _openStudents(StudentFilter.behind)) : null,
        ),
        const Rule(),
        if (behind.isEmpty) EmptyNote('Everyone has logged in the last $behindAfter working days'),
        for (final s in behind)
          LedgerRow(
            onTap: () => openStudentRecord(context, s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s['full_name']}', style: Txt.sans(Txt.body, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  s['last_log_date'] == null
                      ? 'No entries yet'
                      : 'Last entry ${Dates.short(parseDay(s['last_log_date'])!)} · ${s['working_days_since_last_entry']} working days ago',
                  style: Txt.mono(Txt.small, color: Palette.brick),
                ),
              ],
            ),
          ),

        SectionLabel(
          'Supervisors with work waiting',
          trailing: InlineLink(
            'All supervisors',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSupervisors(pushed: true))),
          ),
        ),
        const Rule(),
        if (supervisors.isEmpty) const EmptyNote('No entries are waiting for a supervisor'),
        for (final s in supervisors) SupervisorRow(supervisor: s),

        if (n('not_set_up') > 0) ...[
          const SectionLabel('Not set up'),
          const Rule(),
          LedgerRow(
            onTap: () => _openStudents(StudentFilter.notSetUp),
            child: Text(
              '${plural(n('not_set_up'), 'student has', 'students have')} not entered their placement yet',
              style: Txt.bodyStyle,
            ),
          ),
        ],
      ],
    );
  }
}
