import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/logbook_widgets.dart';
import 'package:siwes360/widgets/paper.dart';

/// One week of one student's logbook, as the supervisor reviews it: every entry
/// in full with Approve or Return, then the weekly sign-off with a comment, like
/// the signature at the foot of a paper logbook page. Pops `true` if anything changed.
class WeekReviewScreen extends StatefulWidget {
  const WeekReviewScreen({super.key, required this.studentId, required this.studentName, required this.week, this.matricNo});

  final int studentId;
  final String studentName;
  final String? matricNo;
  final int week;

  @override
  State<WeekReviewScreen> createState() => _WeekReviewScreenState();
}

class _WeekReviewScreenState extends State<WeekReviewScreen> {
  bool _loading = true;
  String? _error;
  InternshipCalendar? _calendar;
  List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic>? _signoff;
  bool _signoffsAvailable = true;
  bool _changed = false;
  final Set<int> _busy = {};
  bool _signing = false;
  String _myInitials = '';
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      RequestService.getStudentById(widget.studentId),
      RequestService.getStudentDailyLogs(widget.studentId),
      RequestService.getStudentSignoffs(widget.studentId),
    ]);
    final session = await Session.load();
    if (!mounted) return;
    _myInitials = initialsOf(session?.fullName);
    if (results[0]?['status'] != 'success' || results[1]?['status'] != 'success') {
      setState(() {
        _loading = false;
        _error = results[1]?['message'] ?? results[0]?['message'] ?? 'Check your connection and try again.';
      });
      return;
    }
    final student = results[0]!['data'];
    final calendar = InternshipCalendar.from(student['internship_start_date'], student['internship_end_date']);
    final logs = List<Map<String, dynamic>>.from((results[1]!['data'] as List).map((e) => Map<String, dynamic>.from(e)));
    setState(() {
      _loading = false;
      _calendar = calendar;
      _entries = logs.where((l) {
        final d = parseDay(l['log_date']);
        return d != null && calendar != null && calendar.weekOf(d) == widget.week;
      }).toList()
        ..sort((a, b) => '${a['log_date']}'.compareTo('${b['log_date']}'));
      _signoffsAvailable = results[2]?['status'] == 'success';
      _signoff = _signoffsAvailable
          ? (results[2]!['data'] as List)
              .map((s) => Map<String, dynamic>.from(s))
              .where((s) => s['week_number'] == widget.week)
              .firstOrNull
          : null;
    });
  }

  int get _pending => _entries.where((e) => EntryStatus.of(e['status']) == EntryStatus.pending).length;

  DateTime? get _friday => _calendar?.weekStart(widget.week).add(const Duration(days: 4));

  Future<void> _approve(Map<String, dynamic> entry) async {
    setState(() => _busy.add(entry['id']));
    final result = await RequestService.approveDailyLog(entry['id'], '');
    if (!mounted) return;
    setState(() => _busy.remove(entry['id']));
    if (result?['status'] == 'success') {
      setState(() {
        entry['status'] = 'approved';
        _changed = true;
      });
    } else {
      showNote(context, result?['message'] ?? 'Could not approve the entry', error: true);
    }
  }

  Future<void> _approveAll() async {
    for (final entry in _entries.where((e) => EntryStatus.of(e['status']) == EntryStatus.pending).toList()) {
      await _approve(entry);
      if (!mounted) return;
    }
  }

  Future<void> _return(Map<String, dynamic> entry) async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final comment = await showPaperSheet<String>(
      context,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.lg),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Return ${Dates.short(parseDay(entry['log_date'])!)}', style: Txt.titleStyle),
              const SizedBox(height: Space.xs),
              Text('The student edits the entry and sends it back to you.', style: Txt.smallStyle),
              const SizedBox(height: Space.lg),
              RuledTextArea(
                controller: controller,
                label: 'What should they change?',
                minLines: 3,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Say what needs changing' : null,
              ),
              const SizedBox(height: Space.lg),
              PrimaryButton(
                label: 'Return entry',
                onPressed: () {
                  if (key.currentState!.validate()) Navigator.pop(context, controller.text.trim());
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (comment == null || !mounted) return;
    setState(() => _busy.add(entry['id']));
    final result = await RequestService.rejectDailyLog(entry['id'], comment);
    if (!mounted) return;
    setState(() => _busy.remove(entry['id']));
    if (result?['status'] == 'success') {
      setState(() {
        entry['status'] = 'rejected';
        entry['supervisor_comment'] = comment;
        _changed = true;
      });
    } else {
      showNote(context, result?['message'] ?? 'Could not return the entry', error: true);
    }
  }

  Future<void> _signOff() async {
    setState(() => _signing = true);
    final result = await RequestService.signOffWeek(widget.studentId, widget.week, _comment.text.trim());
    if (!mounted) return;
    setState(() => _signing = false);
    if (result?['status'] == 'success') {
      setState(() {
        _signoff = Map<String, dynamic>.from(result!['data'] ?? {});
        _changed = true;
      });
      showNote(context, 'Week ${widget.week} signed off');
    } else {
      showNote(context, result?['message'] ?? 'Could not sign off the week', error: true);
    }
  }

  bool get _canSign {
    final friday = _friday;
    return _signoffsAvailable &&
        _signoff == null &&
        _entries.isNotEmpty &&
        _pending == 0 &&
        friday != null &&
        !today().isBefore(friday);
  }

  @override
  Widget build(BuildContext context) {
    final start = _calendar?.weekStart(widget.week);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _changed),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.studentName, style: Txt.titleStyle),
                Text(
                  [
                    'Week ${widget.week}',
                    if (start != null) Dates.range(start, start.add(const Duration(days: 4))),
                  ].join(' · '),
                  style: Txt.mono(Txt.small, color: Palette.inkSoft),
                ),
              ],
            ),
            toolbarHeight: 64,
          ),
          // The footer sits under the list rather than in bottomNavigationBar,
          // so Sign off stays above the keyboard while writing the comment.
          body: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: Space.xxl),
                            children: [
                              if (_entries.isEmpty) const EmptyNote('No entries this week'),
                              for (final entry in _entries) _entry(entry),
                              _signoffSection(),
                            ],
                          ),
                        ),
                        ?_footer(),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _entry(Map<String, dynamic> e) {
    final status = EntryStatus.of(e['status']);
    final busy = _busy.contains(e['id']);
    final comment = '${e['supervisor_comment'] ?? ''}'.trim();
    Widget part(String label, dynamic text) {
      if ('${text ?? ''}'.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: Txt.labelStyle),
            const SizedBox(height: 4),
            Text('$text', style: Txt.bodyStyle),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.lg),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(Dates.short(parseDay(e['log_date'])!), style: Txt.mono(Txt.body, weight: FontWeight.w600)),
              const Spacer(),
              Stamp(status, initials: _myInitials),
            ],
          ),
          part('Activities', e['description']),
          part('Skills acquired', e['skills_acquired']),
          part('Challenges faced', e['challenges_faced']),
          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: Text('Your comment: $comment', style: Txt.sans(Txt.small, color: status.color)),
            ),
          if (status == EntryStatus.pending) ...[
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: SecondaryButton(label: 'Return', color: Palette.brick, onPressed: busy ? null : () => _return(e)),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: busy ? null : () => _approve(e),
                      child: busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Approve'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _signoffSection() {
    final friday = _friday;
    Widget body;
    if (!_signoffsAvailable) {
      body = Text('Weekly sign-off is not set up on the server yet.', style: Txt.smallStyle);
    } else if (_signoff != null) {
      final comment = '${_signoff!['comment'] ?? ''}';
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignOffStamp(
            week: widget.week,
            signedBy: '${_signoff!['supervisor_name']}',
            signedOn: parseDay(_signoff!['signed_at']),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text('“$comment”', style: Txt.bodyStyle.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      );
    } else if (_entries.isEmpty) {
      body = Text('Nothing to sign this week.', style: Txt.smallStyle);
    } else if (_pending > 0) {
      body = Text(
        'Review the ${plural(_pending, 'pending entry', 'pending entries')} above to sign off this week.',
        style: Txt.smallStyle,
      );
    } else if (friday != null && today().isBefore(friday)) {
      body = Text('You can sign off this week from ${Dates.short(friday)}.', style: Txt.smallStyle);
    } else {
      body = RuledTextArea(
        controller: _comment,
        label: 'Comment for the week',
        hint: 'How did the week go?',
        minLines: 2,
        optional: true,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEKLY SIGN-OFF', style: Txt.labelStyle),
          const SizedBox(height: Space.sm),
          const Rule.strong(),
          const SizedBox(height: Space.md),
          body,
        ],
      ),
    );
  }

  Widget? _footer() {
    if (_pending > 1) {
      return BottomAction(child: SecondaryButton(label: 'Approve all ${plural(_pending, 'entry', 'entries')}', onPressed: _approveAll));
    }
    if (_canSign) {
      return BottomAction(child: PrimaryButton(label: 'Sign off week ${widget.week}', onPressed: _signOff, busy: _signing));
    }
    return null;
  }
}
