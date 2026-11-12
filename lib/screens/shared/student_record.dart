import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/entry_sheet.dart';
import 'package:siwes360/screens/supervisor/week_review.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/logbook_widgets.dart';
import 'package:siwes360/widgets/paper.dart';

/// A student's placement details and whole logbook, week by week, with each
/// week's sign-off. Supervisors open a week to review it; school admins and ITF
/// read it only.
class StudentRecordScreen extends StatefulWidget {
  const StudentRecordScreen({
    super.key,
    required this.studentId,
    required this.name,
    this.supervisorName,
    this.canReview = false,
  });

  final int studentId;
  final String name;
  final String? supervisorName;
  final bool canReview;

  @override
  State<StudentRecordScreen> createState() => _StudentRecordScreenState();
}

class _StudentRecordScreenState extends State<StudentRecordScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _student = {};
  List<Map<String, dynamic>> _logs = [];
  Map<int, Map<String, dynamic>> _signoffs = {};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      RequestService.getStudentById(widget.studentId),
      RequestService.getStudentDailyLogs(widget.studentId),
      RequestService.getStudentSignoffs(widget.studentId),
    ]);
    if (!mounted) return;
    if (results[0]?['status'] != 'success' || results[1]?['status'] != 'success') {
      setState(() {
        _loading = false;
        _error = results[0]?['message'] ?? results[1]?['message'] ?? 'Check your connection and try again.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _error = null;
      _student = Map<String, dynamic>.from(results[0]!['data']);
      _logs = List<Map<String, dynamic>>.from((results[1]!['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      _signoffs = {
        if (results[2]?['status'] == 'success')
          for (final s in results[2]!['data'] as List) (s['week_number'] as num).toInt(): Map<String, dynamic>.from(s),
      };
    });
  }

  InternshipCalendar? get _calendar => InternshipCalendar.from(_student['internship_start_date'], _student['internship_end_date']);

  String? get _reviewer => widget.supervisorName ?? _student['supervisor_name'];

  Future<void> _openWeek(int week) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WeekReviewScreen(
          studentId: widget.studentId,
          studentName: widget.name,
          matricNo: _student['matric_no'],
          week: week,
        ),
      ),
    );
    if (changed == true) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text(widget.name),
        ),
        body: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(color: Palette.ink, onRefresh: _load, child: _body()),
      ),
    );
  }

  Widget _body() {
    final calendar = _calendar;
    final s = _student;
    final weeks = <int, List<Map<String, dynamic>>>{};
    for (final log in _logs) {
      final d = parseDay(log['log_date']);
      if (d != null && calendar != null) weeks.putIfAbsent(calendar.weekOf(d), () => []).add(log);
    }
    final order = weeks.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final w in order) {
      weeks[w]!.sort((a, b) => '${a['log_date']}'.compareTo('${b['log_date']}'));
    }
    final pending = _logs.where((l) => EntryStatus.of(l['status']) == EntryStatus.pending).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 0),
          child: Row(
            children: [
              Monogram(name: widget.name, size: 48),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: Txt.titleStyle),
                    Text('${s['matric_no'] ?? ''}', style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 0),
          child: Column(
            children: [
              const Rule(),
              DetailLine(label: 'Institution', value: '${s['school_name'] ?? ''}'),
              DetailLine(
                label: 'Course',
                value: [s['department'], if (s['level'] != null) '${s['level']} level'].whereType<Object>().join(', '),
              ),
              DetailLine(
                label: 'Workplace',
                value: [s['workplace_name'], s['workplace_location']].where((v) => v != null && '$v'.isNotEmpty).join(', '),
              ),
              DetailLine(label: 'Supervisor', value: _reviewer ?? ''),
              DetailLine(
                label: 'Internship',
                value: calendar == null ? 'Dates not set' : '${Dates.full(calendar.start)} – ${Dates.full(calendar.end)}',
                mono: true,
              ),
            ],
          ),
        ),
        if (calendar != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
            child: DayProgress(
              day: calendar.dayNumber(today()),
              of: calendar.totalDays,
              trailing: '${plural(_logs.length, 'entry', 'entries')} · $pending pending',
            ),
          ),
        if (order.isEmpty) const EmptyNote('No entries yet'),
        for (final w in order) ...[
          WeekHeading(
            week: w,
            start: calendar!.weekStart(w),
            end: calendar.weekEnd(w),
            entries: weeks[w]!.length,
            signedBy: _signoffs[w]?['supervisor_name'],
            signedOn: parseDay(_signoffs[w]?['signed_at']),
            onTap: widget.canReview ? () => _openWeek(w) : null,
          ),
          for (final log in weeks[w]!)
            EntryLine(
              entry: log,
              reviewerInitials: initialsOf(_reviewer),
              onTap: widget.canReview
                  ? () => _openWeek(w)
                  : () => showEntrySheet(context, log, reviewerName: _reviewer, week: w),
            ),
        ],
      ],
    );
  }
}
