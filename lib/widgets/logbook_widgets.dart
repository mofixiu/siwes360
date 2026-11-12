import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/widgets/paper.dart';

/// Pieces specific to the logbook: ruled writing areas, the Mon–Fri marks and
/// a single entry line.

/// A multi-line field drawn on ruled lines, with a faint margin line on the left.
class RuledTextArea extends StatelessWidget {
  const RuledTextArea({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 4,
    this.validator,
    this.optional = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final String? Function(String?)? validator;
  final bool optional;

  static const double _line = 28;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label.toUpperCase(), style: Txt.labelStyle),
            if (optional) ...[
              const SizedBox(width: Space.sm),
              Text('optional', style: Txt.sans(Txt.label, color: Palette.inkFaint)),
            ],
          ],
        ),
        const SizedBox(height: Space.xs),
        CustomPaint(
          painter: _RulesPainter(lineHeight: _line, top: 6),
          child: TextFormField(
            controller: controller,
            validator: validator,
            minLines: minLines,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: Txt.sans(Txt.body, height: _line / Txt.body),
            cursorColor: Palette.ink,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Txt.sans(Txt.body, color: Palette.inkFaint, height: _line / Txt.body),
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(18, 6, 0, 2),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _RulesPainter extends CustomPainter {
  _RulesPainter({required this.lineHeight, required this.top});

  final double lineHeight;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = Palette.rule
      ..strokeWidth = 1;
    // Each rule sits just under the text baseline of its line.
    for (var y = top + lineHeight - 5; y <= size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
    final margin = Paint()
      ..color = Palette.brick.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(8, 0), Offset(8, size.height), margin);
  }

  @override
  bool shouldRepaint(_RulesPainter old) => old.lineHeight != lineHeight || old.top != top;
}

/// What happened on one working day of the week.
enum DayMark { logged, missed, today, upcoming, outside }

/// Mon–Fri of one week as five boxes: a tick for a day with an entry, a dash for a
/// past working day without one, an outlined box for today.
class WeekMarks extends StatelessWidget {
  const WeekMarks({super.key, required this.monday, required this.marks, this.onTapDay});

  final DateTime monday;
  final List<DayMark> marks; // five
  final void Function(DateTime day)? onTapDay;

  static const _names = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: Space.sm),
          Expanded(child: _day(monday.add(Duration(days: i)), _names[i], marks[i])),
        ],
      ],
    );
  }

  Widget _day(DateTime day, String name, DayMark mark) {
    final isToday = mark == DayMark.today;
    final faint = mark == DayMark.upcoming || mark == DayMark.outside;
    Widget? inner;
    switch (mark) {
      case DayMark.logged:
        inner = const Icon(Icons.check, size: 20, color: Palette.ink);
      case DayMark.missed:
        inner = Container(width: 10, height: 2, color: Palette.brick);
      default:
        inner = null;
    }
    return InkWell(
      onTap: onTapDay == null || faint ? null : () => onTapDay!(day),
      child: Column(
        children: [
          Text(
            name,
            style: Txt.sans(Txt.label, weight: FontWeight.w600, color: faint ? Palette.inkFaint : Palette.inkSoft)
                .copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: faint ? Colors.transparent : Palette.sheet,
              border: Border.all(
                color: isToday ? Palette.ink : (faint ? Palette.rule : Palette.ruleStrong),
                width: isToday ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(Radii.stamp),
            ),
            alignment: Alignment.center,
            child: inner,
          ),
          const SizedBox(height: 4),
          Text('${day.day}', style: Txt.mono(Txt.label, color: faint ? Palette.inkFaint : Palette.inkSoft)),
        ],
      ),
    );
  }

  /// Works out the marks for the week starting [monday] from the days that have entries.
  static List<DayMark> marksFor(DateTime monday, Set<DateTime> loggedDays, {InternshipCalendar? calendar}) {
    final now = today();
    return List.generate(5, (i) {
      final day = monday.add(Duration(days: i));
      if (loggedDays.any((d) => sameDay(d, day))) return DayMark.logged;
      if (calendar != null && !calendar.contains(day)) return DayMark.outside;
      if (sameDay(day, now)) return DayMark.today;
      if (day.isAfter(now)) return DayMark.upcoming;
      return DayMark.missed;
    });
  }
}

/// One logbook entry on a ruled line: mono date, the first lines of the work,
/// and its stamp.
class EntryLine extends StatelessWidget {
  const EntryLine({super.key, required this.entry, this.reviewerInitials, this.onTap, this.showDate = true});

  final Map<String, dynamic> entry;
  final String? reviewerInitials;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final date = parseDay(entry['log_date']);
    final status = EntryStatus.of(entry['status']);
    final attachments = int.tryParse('${entry['attachment_count'] ?? (entry['attachments'] as List?)?.length ?? 0}') ?? 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.page, 14, Space.page, 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showDate && date != null) Text(Dates.short(date), style: Txt.mono(Txt.small, weight: FontWeight.w500)),
                if (attachments > 0) ...[
                  const SizedBox(width: Space.sm),
                  const Icon(Icons.attach_file, size: 14, color: Palette.inkFaint),
                  Text('$attachments', style: Txt.mono(Txt.label, color: Palette.inkFaint)),
                ],
                const Spacer(),
                Stamp(status, initials: reviewerInitials),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${entry['description'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Txt.sans(Txt.small, color: Palette.ink, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// A week heading in a logbook: "Week 9", its dates, entry count and sign-off.
class WeekHeading extends StatelessWidget {
  const WeekHeading({
    super.key,
    required this.week,
    required this.start,
    required this.end,
    required this.entries,
    this.signedBy,
    this.signedOn,
    this.showSignOff = true,
    this.onTap,
  });

  final int week;
  final DateTime start;
  final DateTime end;
  final int entries;
  final String? signedBy;
  final DateTime? signedOn;
  final bool showSignOff;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.ruleStrong))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Week $week', style: Txt.titleStyle),
                  const SizedBox(height: 2),
                  Text(
                    '${Dates.range(start, end.subtract(const Duration(days: 2)))} · ${plural(entries, 'entry', 'entries')}',
                    style: Txt.mono(Txt.label, color: Palette.inkSoft),
                  ),
                ],
              ),
            ),
            if (showSignOff) SignOffStamp(week: week, signedBy: signedBy, signedOn: signedOn, compact: true),
            if (onTap != null) const Icon(Icons.chevron_right, size: 20, color: Palette.inkFaint),
          ],
        ),
      ),
    );
  }
}
