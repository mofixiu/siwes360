import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/addNewLogbookEntry.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';
import 'package:url_launcher/url_launcher.dart';

/// One entry in full, as a bottom sheet: the date, its stamp, what was written,
/// the supervisor's comment and attachments. The student may edit or delete it
/// while it is pending or returned. Returns true if the entry changed.
Future<bool> showEntrySheet(
  BuildContext context,
  Map<String, dynamic> entry, {
  String? reviewerName,
  int? week,
  bool canEdit = false,
}) async {
  final changed = await showPaperSheet<bool>(
    context,
    builder: (context) => _EntrySheet(entry: entry, reviewerName: reviewerName, week: week, canEdit: canEdit),
  );
  return changed ?? false;
}

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({required this.entry, this.reviewerName, this.week, required this.canEdit});

  final Map<String, dynamic> entry;
  final String? reviewerName;
  final int? week;
  final bool canEdit;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  bool _deleting = false;

  Map<String, dynamic> get e => widget.entry;

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete this entry?',
      message: 'It will be removed from your logbook and your supervisor will no longer see it.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    final result = await RequestService.deleteDailyLog(e['id']);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (result?['status'] == 'success') {
      Navigator.pop(context, true);
      showNote(context, 'Entry deleted');
    } else {
      showNote(context, result?['message'] ?? 'Could not delete the entry', error: true);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddNewLogEntry(existing: e)),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final date = parseDay(e['log_date']);
    final status = EntryStatus.of(e['status']);
    final attachments = List<Map<String, dynamic>>.from(
      (e['attachments'] as List? ?? []).map((a) => Map<String, dynamic>.from(a)),
    );
    final comment = '${e['supervisor_comment'] ?? ''}'.trim();
    final editable = widget.canEdit && status != EntryStatus.approved;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date == null ? 'Entry' : Dates.short(date), style: Txt.displayStyle),
                      if (widget.week != null || date != null)
                        Text(
                          [if (widget.week != null) 'Week ${widget.week}', if (date != null) '${date.year}'].join(' · '),
                          style: Txt.mono(Txt.small, color: Palette.inkSoft),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Stamp(status, initials: initialsOf(widget.reviewerName)),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            const Rule.strong(),
            _section('Activities', '${e['description'] ?? ''}'),
            _section('Skills acquired', '${e['skills_acquired'] ?? ''}'),
            _section('Challenges faced', '${e['challenges_faced'] ?? ''}'),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: Space.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: status.color, width: 2)),
                  color: Palette.sheet,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reviewerName == null ? "SUPERVISOR'S COMMENT" : "COMMENT FROM ${widget.reviewerName!.toUpperCase()}",
                      style: Txt.labelStyle,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(comment, style: Txt.bodyStyle),
                  ],
                ),
              ),
            ],
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: Space.lg),
              Text('ATTACHMENTS', style: Txt.labelStyle),
              const SizedBox(height: Space.xs),
              for (final a in attachments)
                LedgerRow(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  leading: const Icon(Icons.attach_file, size: 18),
                  onTap: () => launchUrl(Uri.parse('$host${a['file_path']}'), mode: LaunchMode.externalApplication),
                  showChevron: false,
                  child: Text('${a['file_name']}', style: Txt.sans(Txt.small, color: Palette.ink)),
                ),
            ],
            if (editable) ...[
              const SizedBox(height: Space.xl),
              if (status == EntryStatus.rejected)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Text('Edit the entry and it goes back to your supervisor for review.', style: Txt.smallStyle),
                ),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(label: 'Delete', color: Palette.brick, onPressed: _delete, busy: _deleting),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(child: PrimaryButton(label: 'Edit', onPressed: _edit)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String label, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Txt.labelStyle),
          const SizedBox(height: 6),
          Text(text, style: Txt.bodyStyle),
        ],
      ),
    );
  }
}
