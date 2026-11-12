import 'package:flutter/material.dart';
import 'package:siwes360/screens/shared/student_record.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/widgets/paper.dart';

/// Where a student stands today, as the API's oversight endpoints describe it.
class Standing {
  Standing._();

  static String label(String? standing) => switch (standing) {
        'logging' => 'Logging',
        'behind' => 'Behind',
        'not_set_up' => 'Not set up',
        'not_started' => 'Not started',
        'finished' => 'Finished',
        _ => '—',
      };

  static Color color(String? standing) => switch (standing) {
        'logging' => Palette.olive,
        'behind' => Palette.brick,
        'finished' => Palette.inkSoft,
        _ => Palette.inkFaint,
      };
}

/// Filters on the student list. Matches the API's ?filter= values.
enum StudentFilter {
  all('All'),
  behind('Behind'),
  waiting('Waiting review'),
  unsigned('Unsigned weeks'),
  notSetUp('Not set up'),
  noSupervisor('No supervisor');

  const StudentFilter(this.label);

  final String label;

  bool matches(Map<String, dynamic> s) => switch (this) {
        StudentFilter.all => true,
        StudentFilter.behind => s['standing'] == 'behind',
        StudentFilter.waiting => ((s['pending_logs'] as num?) ?? 0) > 0,
        StudentFilter.unsigned => ((s['unsigned_weeks'] as List?) ?? const []).isNotEmpty,
        StudentFilter.notSetUp => s['standing'] == 'not_set_up',
        StudentFilter.noSupervisor => s['supervisor_id'] == null,
      };
}

/// One student on an oversight list: name, matric number, how their logbook is
/// going, and their standing in its colour.
class OversightStudentRow extends StatelessWidget {
  const OversightStudentRow({super.key, required this.student, this.onTap, this.showSchool = false});

  final Map<String, dynamic> student;
  final VoidCallback? onTap;
  final bool showSchool;

  @override
  Widget build(BuildContext context) {
    final s = student;
    final standing = '${s['standing']}';
    final last = parseDay(s['last_log_date']);
    final unsigned = (s['unsigned_weeks'] as List?) ?? const [];
    final pending = (s['pending_logs'] as num?)?.toInt() ?? 0;
    final facts = <String>[
      if (s['current_week'] != null) 'Week ${s['current_week']}',
      if (standing == 'not_set_up') 'has not set up the logbook',
      if (standing != 'not_set_up') last == null ? 'no entries' : 'last entry ${Dates.relative(last)}',
      if (pending > 0) '$pending pending',
      if (unsigned.isNotEmpty) '${plural(unsigned.length, 'week')} unsigned',
    ];
    return LedgerRow(
      onTap: onTap,
      leading: Monogram(name: s['full_name'], size: 36),
      trailing: Text(
        Standing.label(standing),
        style: Txt.sans(Txt.small, weight: FontWeight.w600, color: Standing.color(standing)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s['full_name']}', style: Txt.sans(Txt.body, weight: FontWeight.w600)),
          Text(
            [s['matric_no'], if (showSchool) s['school_name']].whereType<Object>().join(' · '),
            style: Txt.mono(Txt.label, color: Palette.inkSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(facts.join(' · '), style: Txt.sans(Txt.label, color: Palette.inkSoft), maxLines: 2),
        ],
      ),
    );
  }
}

/// Opens a student's logbook read-only (school admins and ITF).
Future<void> openStudentRecord(BuildContext context, Map<String, dynamic> s) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentRecordScreen(
        studentId: (s['user_id'] as num).toInt(),
        name: '${s['full_name']}',
        supervisorName: s['supervisor_name'],
      ),
    ),
  );
}

/// A filterable, searchable list of students with their standing. Used for a
/// school admin's students, one supervisor's students, and one institution (ITF).
class StudentList extends StatefulWidget {
  const StudentList({
    super.key,
    required this.students,
    this.initialFilter = StudentFilter.all,
    this.header,
    this.behindAfter = 3,
  });

  final List<Map<String, dynamic>> students;
  final StudentFilter initialFilter;
  final Widget? header;
  final int behindAfter;

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  late StudentFilter _filter = widget.initialFilter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = widget.students
        .where(_filter.matches)
        .where((s) => q.isEmpty || '${s['full_name']} ${s['matric_no']}'.toLowerCase().contains(q))
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        ?widget.header,
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: Txt.bodyStyle,
            decoration: const InputDecoration(hintText: 'Search by name or matric number', prefixIcon: Icon(Icons.search, size: 20)),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.page - Space.sm),
          child: Row(
            children: [
              for (final f in StudentFilter.values)
                TextButton(
                  onPressed: () => setState(() => _filter = f),
                  style: TextButton.styleFrom(
                    foregroundColor: _filter == f ? Palette.ink : Palette.inkSoft,
                    textStyle: Txt.sans(Txt.small, weight: _filter == f ? FontWeight.w700 : FontWeight.w500),
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text('${f.label} ${widget.students.where(f.matches).length}'),
                ),
            ],
          ),
        ),
        const Rule(),
        if (_filter == StudentFilter.behind)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
            child: Text('No entry for ${widget.behindAfter} or more working days.', style: Txt.smallStyle),
          ),
        if (visible.isEmpty) const EmptyNote('No students here'),
        for (final s in visible) OversightStudentRow(student: s, onTap: () => openStudentRecord(context, s)),
      ],
    );
  }
}
