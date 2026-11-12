import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/addNewLogbookEntry.dart';
import 'package:siwes360/screens/student/entry_sheet.dart';
import 'package:siwes360/screens/student/studentLogbook.dart';
import 'package:siwes360/screens/shared/notifications.dart';
import 'package:siwes360/screens/student/student_nav.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/logbook_widgets.dart';
import 'package:siwes360/widgets/paper.dart';

/// The student's "Today" tab. It answers one question: have I logged today?
/// Then this week's Mon–Fri marks, the day count, and who signs the logbook.
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _student = {};
  Map<String, dynamic>? _supervisor;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _signoffs = [];
  int _unread = 0;
  String? _photo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _student.isEmpty;
      _error = null;
    });
    final session = await Session.load();
    if (session == null) {
      if (mounted) Session.signOut(context);
      return;
    }
    final id = (session.roleData['user_id'] as num?)?.toInt() ?? session.id;
    final results = await Future.wait([
      RequestService.getStudentDashboardData(id),
      RequestService.getAllDailyLogs(id),
      RequestService.getStudentSignoffs(id),
      RequestService.getNotifications(session.id),
    ]);
    final photo = await Session.photoPath('student', id);
    if (!mounted) return;
    final dashboard = results[0];
    if (dashboard?['status'] != 'success') {
      setState(() {
        _loading = false;
        _error = dashboard?['message'] ?? 'Check your connection and try again.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _student = Map<String, dynamic>.from(dashboard!['data']['student'] ?? {});
      _supervisor = dashboard['data']['supervisor'] == null ? null : Map<String, dynamic>.from(dashboard['data']['supervisor']);
      _logs = _list(results[1]);
      _signoffs = _list(results[2]);
      _unread = _list(results[3]).where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
      _photo = photo;
    });
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic>? result) => result?['status'] == 'success'
      ? List<Map<String, dynamic>>.from((result!['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)))
      : [];

  InternshipCalendar? get _calendar => InternshipCalendar.from(_student['internship_start_date'], _student['internship_end_date']);

  Map<String, dynamic>? _entryOn(DateTime day) {
    for (final log in _logs) {
      final d = parseDay(log['log_date']);
      if (d != null && sameDay(d, day)) return log;
    }
    return null;
  }

  Future<void> _write() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddNewLogEntry()));
    if (created == true) _load();
  }

  Future<void> _open(Map<String, dynamic> entry) async {
    final d = parseDay(entry['log_date']);
    final changed = await showEntrySheet(
      context,
      entry,
      reviewerName: _supervisor?['full_name'],
      week: d == null ? null : _calendar?.weekOf(d),
      canEdit: true,
    );
    if (changed) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const StudentNavBar(currentIndex: 0),
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
    final now = today();
    final calendar = _calendar;
    final week = calendar?.weekOf(now);
    final todayEntry = _entryOn(now);
    final monday = InternshipCalendar.mondayOf(now);
    final logged = _logs.map((l) => parseDay(l['log_date'])).whereType<DateTime>().toSet();
    final marks = WeekMarks.marksFor(monday, logged, calendar: calendar);
    final loggedThisWeek = marks.where((m) => m == DayMark.logged).length;
    final dueThisWeek = marks.where((m) => m != DayMark.upcoming && m != DayMark.outside).length;
    final returned = _logs.where((l) => EntryStatus.of(l['status']) == EntryStatus.rejected).toList();
    final lastSignoff = _signoffs.isEmpty ? null : _signoffs.last;
    final weeksDone = calendar == null ? 0 : (calendar.weekOf(now) - 1).clamp(0, calendar.totalWeeks);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        // Who and when.
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.sm, 0),
          child: Row(
            children: [
              Monogram(name: _student['full_name'], size: 36, photoPath: _photo),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_student['full_name'] ?? ''}', style: Txt.sans(Txt.small, weight: FontWeight.w600, color: Palette.ink)),
                    Text('${_student['matric_no'] ?? ''}', style: Txt.mono(Txt.label, color: Palette.inkSoft)),
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
        const SizedBox(height: Space.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [Dates.short(now).toUpperCase(), if (week != null && calendar!.contains(now)) 'WEEK $week'].join(' · '),
                style: Txt.mono(Txt.small, weight: FontWeight.w500, color: Palette.inkSoft),
              ),
              const SizedBox(height: Space.sm),
              ..._todayStatus(now, calendar, todayEntry),
            ],
          ),
        ),

        if (calendar != null && !now.isBefore(calendar.start)) ...[
          SectionLabel(
            'This week',
            trailing: Text('$loggedThisWeek of $dueThisWeek days', style: Txt.mono(Txt.small, color: Palette.inkSoft)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: WeekMarks(
              monday: monday,
              marks: marks,
              onTapDay: (day) {
                final entry = _entryOn(day);
                if (entry != null) _open(entry);
              },
            ),
          ),
        ],

        if (calendar != null) ...[
          const SectionLabel('Internship'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: DayProgress(
              day: calendar.dayNumber(now),
              of: calendar.totalDays,
              trailing: 'ends ${Dates.full(calendar.end)}',
            ),
          ),
          const SizedBox(height: Space.lg),
          const Rule(),
        ],
        LedgerRow(
          child: _rowText(
            'Supervisor',
            _supervisor == null
                ? 'Not linked yet'
                : [_supervisor!['full_name'], _supervisor!['organization']].where((v) => v != null).join(', '),
          ),
        ),
        LedgerRow(
          trailing: lastSignoff == null
              ? null
              : SignOffStamp(
                  week: (lastSignoff['week_number'] as num).toInt(),
                  signedBy: '${lastSignoff['supervisor_name']}',
                  compact: true,
                ),
          child: _rowText(
            'Weeks signed off',
            calendar == null ? '—' : '${_signoffs.length} of $weeksDone finished weeks',
            mono: true,
          ),
        ),
        if (returned.isNotEmpty)
          LedgerRow(
            onTap: () => _open(returned.first),
            trailing: const Stamp(EntryStatus.rejected),
            child: _rowText(
              'Returned for changes',
              returned.length == 1
                  ? Dates.short(parseDay(returned.first['log_date'])!)
                  : '${returned.length} entries, oldest ${Dates.short(parseDay(returned.last['log_date'])!)}',
              mono: true,
            ),
          ),
        LedgerRow(
          onTap: () => Navigator.of(context).pushReplacement(
            PageRouteBuilder(pageBuilder: (_, _, _) => const StudentLogbook(), transitionDuration: Duration.zero),
          ),
          child: _rowText('All entries', plural(_logs.length, 'entry', 'entries'), mono: true),
        ),
      ],
    );
  }

  List<Widget> _todayStatus(DateTime now, InternshipCalendar? calendar, Map<String, dynamic>? entry) {
    String title;
    String detail;
    Widget? action;
    final supervisorName = _supervisor?['full_name'];

    if (entry != null) {
      final status = EntryStatus.of(entry['status']);
      title = 'Logged today';
      detail = switch (status) {
        EntryStatus.pending => supervisorName == null ? 'Waiting for review.' : 'Waiting for $supervisorName to review.',
        EntryStatus.approved => 'Approved already.',
        EntryStatus.rejected => 'Returned with a comment. Edit it and send it back.',
      };
      action = SecondaryButton(label: "Open today's entry", onPressed: () => _open(entry));
    } else if (calendar == null) {
      title = 'Internship dates not set';
      detail = 'Add your start and end dates in your profile.';
    } else if (now.isBefore(calendar.start)) {
      title = 'Starts ${Dates.short(calendar.start)}';
      detail = 'Your first entry is due on your first day.';
    } else if (now.isAfter(calendar.end)) {
      title = 'Internship finished';
      detail = 'Your last day was ${Dates.full(calendar.end)}.';
    } else if (!isWorkingDay(now)) {
      title = 'No entry due today';
      detail = "It's the weekend. You can still write up a day you missed.";
      action = SecondaryButton(label: 'Write an entry', onPressed: _write);
    } else {
      title = 'Not logged yet today';
      detail = 'Write down what you did before you leave work.';
      action = PrimaryButton(label: "Write today's entry", onPressed: _write);
    }

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: Txt.displayStyle)),
          if (entry != null) Stamp(EntryStatus.of(entry['status']), initials: initialsOf(supervisorName)),
        ],
      ),
      const SizedBox(height: Space.xs),
      Text(detail, style: Txt.smallStyle),
      if (action != null) ...[const SizedBox(height: Space.lg), action],
    ];
  }

  Widget _rowText(String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Txt.smallStyle),
        const SizedBox(height: 2),
        Text(value, style: mono ? Txt.mono(Txt.small, weight: FontWeight.w500) : Txt.sans(Txt.body, weight: FontWeight.w500)),
      ],
    );
  }
}
