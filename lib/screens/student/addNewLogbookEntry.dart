import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/logbook_widgets.dart';
import 'package:siwes360/widgets/paper.dart';

/// Write a day's entry, or edit one that is pending or returned. The date is the
/// title ("Tue 17 Dec · Week 3"), the writing goes on ruled lines, and Submit
/// stays at the bottom. Pops `true` when saved.
class AddNewLogEntry extends StatefulWidget {
  const AddNewLogEntry({super.key, this.existing, this.initialDate});

  final Map<String, dynamic>? existing;
  final DateTime? initialDate;

  @override
  State<AddNewLogEntry> createState() => _AddNewLogEntryState();
}

class _AddNewLogEntryState extends State<AddNewLogEntry> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _activities;
  late final TextEditingController _skills;
  late final TextEditingController _challenges;
  late DateTime _date;
  InternshipCalendar? _calendar;
  final List<PlatformFile> _files = [];
  bool _saving = false;

  static const _maxBytes = 10 * 1024 * 1024;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _activities = TextEditingController(text: e?['description'] ?? '');
    _skills = TextEditingController(text: e?['skills_acquired'] ?? '');
    _challenges = TextEditingController(text: e?['challenges_faced'] ?? '');
    _date = parseDay(e?['log_date']) ?? widget.initialDate ?? today();
    _loadCalendar();
  }

  @override
  void dispose() {
    _activities.dispose();
    _skills.dispose();
    _challenges.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar() async {
    final session = await Session.load();
    if (session == null) return;
    final id = (session.roleData['user_id'] as num?)?.toInt() ?? session.id;
    final result = await RequestService.getStudentById(id);
    if (!mounted || result?['status'] != 'success') return;
    setState(() {
      _calendar = InternshipCalendar.from(
        result!['data']['internship_start_date'],
        result['data']['internship_end_date'],
      );
    });
  }

  Future<void> _pickDate() async {
    final now = today();
    final first = _calendar?.start ?? DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : _date,
      firstDate: first,
      lastDate: now,
      helpText: 'Which day is this entry for?',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'xls', 'xlsx'],
    );
    if (result == null || !mounted) return;
    final total = [..._files, ...result.files].fold<int>(0, (sum, f) => sum + f.size);
    if (total > _maxBytes) {
      showNote(context, 'Attachments can be 10 MB in total', error: true);
      return;
    }
    setState(() => _files.addAll(result.files));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final fields = {
      'log_date': apiDay(_date),
      'description': _activities.text.trim(),
      'skills_acquired': _skills.text.trim(),
      'challenges_faced': _challenges.text.trim(),
    };
    final result = _editing
        ? await RequestService.updateDailyLog(widget.existing!['id'], fields)
        : await RequestService.createDailyLog({
            ...fields,
            'skills_acquired': _skills.text.trim().isEmpty ? null : _skills.text.trim(),
            'challenges_faced': _challenges.text.trim().isEmpty ? null : _challenges.text.trim(),
          }, attachments: _files.where((f) => f.path != null).map((f) => File(f.path!)).toList());
    if (!mounted) return;
    setState(() => _saving = false);
    if (result?['status'] == 'success') {
      showNote(context, _editing ? 'Entry updated and sent for review' : 'Entry sent to your supervisor');
      Navigator.pop(context, true);
    } else {
      showNote(context, result?['message'] ?? 'Could not save the entry', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = _calendar?.weekOf(_date);
    final returned = widget.existing != null && EntryStatus.of(widget.existing!['status']) == EntryStatus.rejected;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: InkWell(
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Dates.short(_date), style: Txt.titleStyle),
                  if (week != null) Text('  ·  Week $week', style: Txt.mono(Txt.body, color: Palette.inkSoft)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 20, color: Palette.inkSoft),
                ],
              ),
            ),
          ),
        ),
        // Submit sits under the form rather than in bottomNavigationBar, so it
        // stays above the keyboard.
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.xxl),
                  children: [
                    if (returned && '${widget.existing!['supervisor_comment'] ?? ''}'.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(Space.md),
                        decoration: const BoxDecoration(
                          color: Palette.sheet,
                          border: Border(left: BorderSide(color: Palette.brick, width: 2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RETURNED WITH THIS COMMENT', style: Txt.labelStyle),
                            const SizedBox(height: Space.xs),
                            Text('${widget.existing!['supervisor_comment']}', style: Txt.bodyStyle),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.xl),
                    ],
                    RuledTextArea(
                      controller: _activities,
                      label: 'Activities',
                      hint: 'What did you work on today?',
                      minLines: 6,
                      validator: (v) {
                        final text = v?.trim() ?? '';
                        if (text.isEmpty) return 'Write what you did today';
                        if (text.length < 20) return 'Add a little more detail (at least 20 characters)';
                        return null;
                      },
                    ),
                    const SizedBox(height: Space.xl),
                    RuledTextArea(
                      controller: _skills,
                      label: 'Skills acquired',
                      hint: 'Anything new you learnt',
                      minLines: 3,
                      optional: true,
                    ),
                    const SizedBox(height: Space.xl),
                    RuledTextArea(
                      controller: _challenges,
                      label: 'Challenges faced',
                      hint: 'Anything that slowed you down',
                      minLines: 3,
                      optional: true,
                    ),
                    if (!_editing) ...[
                      const SizedBox(height: Space.xl),
                      Row(
                        children: [
                          Text('ATTACHMENTS', style: Txt.labelStyle),
                          const SizedBox(width: Space.sm),
                          Text('optional · 10 MB total', style: Txt.sans(Txt.label, color: Palette.inkFaint)),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      const Rule(),
                      for (var i = 0; i < _files.length; i++)
                        LedgerRow(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
                          trailing: IconButton(
                            tooltip: 'Remove ${_files[i].name}',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _files.removeAt(i)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _files[i].name,
                                style: Txt.sans(Txt.small, color: Palette.ink),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(_size(_files[i].size), style: Txt.mono(Txt.label, color: Palette.inkFaint)),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Attach a file'),
                        ),
                      ),
                      Text('PDF, Word, Excel, JPG or PNG', style: Txt.sans(Txt.label, color: Palette.inkFaint)),
                    ],
                  ],
                ),
              ),
            ),
            BottomAction(
              child: PrimaryButton(
                label: _editing ? (returned ? 'Resubmit for review' : 'Save changes') : 'Submit for review',
                onPressed: _submit,
                busy: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _size(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
