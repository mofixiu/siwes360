import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/addNewLogbookEntry.dart';
import 'package:siwes360/screens/student/entry_sheet.dart';
import 'package:siwes360/screens/student/student_nav.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/logbook_widgets.dart';
import 'package:siwes360/widgets/paper.dart';

/// The whole logbook, a week to a page: each week's entries Monday to Friday,
/// with the supervisor's weekly sign-off beside the week.
class StudentLogbook extends StatefulWidget {
  const StudentLogbook({super.key});

  @override
  State<StudentLogbook> createState() => _StudentLogbookState();
}

enum _Filter { all, approved, pending, returned }

class _StudentLogbookState extends State<StudentLogbook> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _student = {};
  String? _supervisorName;
  List<Map<String, dynamic>> _logs = [];
  Map<int, Map<String, dynamic>> _signoffs = {};
  _Filter _filter = _Filter.all;

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
    ]);
    if (!mounted) return;
    if (results[1]?['status'] != 'success') {
      setState(() {
        _loading = false;
        _error = results[1]?['message'] ?? 'Check your connection and try again.';
      });
      return;
    }
    setState(() {
      _loading = false;
      if (results[0]?['status'] == 'success') {
        _student = Map<String, dynamic>.from(results[0]!['data']['student'] ?? {});
        _supervisorName = results[0]!['data']['supervisor']?['full_name'];
      }
      _logs = List<Map<String, dynamic>>.from((results[1]!['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      _signoffs = {
        if (results[2]?['status'] == 'success')
          for (final s in results[2]!['data'] as List) (s['week_number'] as num).toInt(): Map<String, dynamic>.from(s),
      };
    });
  }

  InternshipCalendar? get _calendar => InternshipCalendar.from(_student['internship_start_date'], _student['internship_end_date']);

  bool _matches(Map<String, dynamic> log) => _inFilter(_filter, log);

  static bool _inFilter(_Filter filter, Map<String, dynamic> log) {
    final status = EntryStatus.of(log['status']);
    return switch (filter) {
      _Filter.all => true,
      _Filter.approved => status == EntryStatus.approved,
      _Filter.pending => status == EntryStatus.pending,
      _Filter.returned => status == EntryStatus.rejected,
    };
  }

  Future<void> _write({DateTime? day}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddNewLogEntry(initialDate: day)),
    );
    if (created == true) _load();
  }

  Future<void> _open(Map<String, dynamic> entry) async {
    final d = parseDay(entry['log_date']);
    final changed = await showEntrySheet(
      context,
      entry,
      reviewerName: _supervisorName,
      week: d == null ? null : _calendar?.weekOf(d),
      canEdit: true,
    );
    if (changed) _load();
  }

  Future<void> _jumpToDate() async {
    final calendar = _calendar;
    final now = today();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: calendar?.start ?? DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Open the entry for',
    );
    if (picked == null || !mounted) return;
    final entry = _logs.where((l) => sameDay(parseDay(l['log_date']) ?? DateTime(0), picked)).firstOrNull;
    if (entry != null) {
      _open(entry);
    } else {
      final write = await confirm(
        context,
        title: 'No entry for ${Dates.short(picked)}',
        message: 'You did not write anything for that day.',
        action: 'Write it now',
      );
      if (write) _write(day: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const StudentNavBar(currentIndex: 1),
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
    final calendar = _calendar;
    final now = today();
    final counts = {for (final f in _Filter.values) f: _logs.where((l) => _inFilter(f, l)).length};

    // Group by internship week, newest week first; entries Monday to Friday.
    final weeks = <int, List<Map<String, dynamic>>>{};
    for (final log in _logs.where(_matches)) {
      final d = parseDay(log['log_date']);
      if (d == null) continue;
      weeks.putIfAbsent(calendar?.weekOf(d) ?? 0, () => []).add(log);
    }
    final order = weeks.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final w in order) {
      weeks[w]!.sort((a, b) => '${a['log_date']}'.compareTo('${b['log_date']}'));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        PageHeader(
          title: 'Logbook',
          actions: [
            IconButton(
              tooltip: 'Open a date',
              onPressed: _jumpToDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 20, color: Palette.ink),
            ),
            TextButton.icon(
              onPressed: _write,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New entry'),
            ),
          ],
        ),
        if (calendar != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
            child: DayProgress(
              day: calendar.dayNumber(now),
              of: calendar.totalDays,
              trailing: '${(calendar.totalDays - calendar.dayNumber(now)).clamp(0, calendar.totalDays)} days left',
            ),
          ),
        const SizedBox(height: Space.lg),
        _filters(counts),
        if (order.isEmpty)
          EmptyNote(
            _filter == _Filter.all ? 'No entries yet' : 'No ${_label(_filter).toLowerCase()} entries',
            detail: _filter == _Filter.all ? 'Your first entry will appear here, under week 1.' : null,
          ),
        for (final w in order) ...[
          if (calendar != null)
            WeekHeading(
              week: w,
              start: calendar.weekStart(w),
              end: calendar.weekEnd(w),
              entries: weeks[w]!.length,
              signedBy: _signoffs[w]?['supervisor_name'],
              signedOn: parseDay(_signoffs[w]?['signed_at']),
            ),
          for (final log in weeks[w]!)
            EntryLine(entry: log, reviewerInitials: initialsOf(_supervisorName), onTap: () => _open(log)),
          if (_signoffs[w]?['comment'] != null && '${_signoffs[w]!['comment']}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
              child: Text(
                '“${_signoffs[w]!['comment']}” — ${initialsOf(_signoffs[w]!['supervisor_name'])}',
                style: Txt.sans(Txt.small, color: Palette.inkSoft).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ],
    );
  }

  String _label(_Filter f) => switch (f) {
        _Filter.all => 'All',
        _Filter.approved => 'Approved',
        _Filter.pending => 'Pending',
        _Filter.returned => 'Returned',
      };

  Widget _filters(Map<_Filter, int> counts) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
      padding: const EdgeInsets.symmetric(horizontal: Space.page - Space.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in _Filter.values)
              InkWell(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _filter == f ? Palette.ink : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _label(f),
                        style: Txt.sans(
                          Txt.small,
                          weight: _filter == f ? FontWeight.w600 : FontWeight.w500,
                          color: _filter == f ? Palette.ink : Palette.inkSoft,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${counts[f]}', style: Txt.mono(Txt.label, color: Palette.inkFaint)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
