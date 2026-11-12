import 'package:flutter/material.dart';
import 'package:siwes360/screens/shared/student_record.dart';
import 'package:siwes360/screens/supervisor/supervisor_nav.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';

/// Students who chose this supervisor, with how many of their entries wait for review.
class SupervisorStudentsPage extends StatefulWidget {
  const SupervisorStudentsPage({super.key});

  @override
  State<SupervisorStudentsPage> createState() => _SupervisorStudentsPageState();
}

enum _Show { all, toReview, upToDate }

class _SupervisorStudentsPageState extends State<SupervisorStudentsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  String _query = '';
  _Show _show = _Show.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await Session.load();
    if (session == null) {
      if (mounted) Session.signOut(context);
      return;
    }
    final result = await RequestService.getSupervisorStudents(session.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?['status'] == 'success') {
        _error = null;
        _students = List<Map<String, dynamic>>.from((result!['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  int _pending(Map<String, dynamic> s) => int.tryParse('${s['pending_logs'] ?? 0}') ?? 0;

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    return _students.where((s) {
      final text = '${s['full_name']} ${s['matric_no']} ${s['school_name']}'.toLowerCase();
      if (q.isNotEmpty && !text.contains(q)) return false;
      return switch (_show) {
        _Show.all => true,
        _Show.toReview => _pending(s) > 0,
        _Show.upToDate => _pending(s) == 0,
      };
    }).toList();
  }

  Future<void> _open(Map<String, dynamic> s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StudentRecordScreen(
          studentId: (s['user_id'] as num).toInt(),
          name: '${s['full_name']}',
          canReview: true,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        bottomNavigationBar: const SupervisorNavBar(currentIndex: 1),
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : RefreshIndicator(color: Palette.ink, onRefresh: _load, child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    final visible = _visible;
    final toReview = _students.where((s) => _pending(s) > 0).length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        PageHeader(
          title: 'Students',
          subtitle: Text(
            '${plural(_students.length, 'student')} · $toReview with entries to review',
            style: Txt.mono(Txt.small, color: Palette.inkSoft),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: Txt.bodyStyle,
            decoration: const InputDecoration(
              hintText: 'Search by name or matric number',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page - Space.sm),
          child: Row(
            children: [
              for (final (show, label) in [(_Show.all, 'All'), (_Show.toReview, 'To review'), (_Show.upToDate, 'Up to date')])
                TextButton(
                  onPressed: () => setState(() => _show = show),
                  style: TextButton.styleFrom(
                    foregroundColor: _show == show ? Palette.ink : Palette.inkSoft,
                    textStyle: Txt.sans(Txt.small, weight: _show == show ? FontWeight.w700 : FontWeight.w500),
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(label),
                ),
            ],
          ),
        ),
        const Rule(),
        if (visible.isEmpty)
          EmptyNote(_students.isEmpty ? 'No students yet' : 'No students match',
              detail: _students.isEmpty ? 'Students choose you as their supervisor when they set up their logbook.' : null),
        for (final s in visible)
          LedgerRow(
            onTap: () => _open(s),
            leading: Monogram(name: s['full_name'], size: 36),
            trailing: _pending(s) > 0
                ? Text('${_pending(s)} to review', style: Txt.mono(Txt.small, weight: FontWeight.w500, color: Palette.ochre))
                : Text('Up to date', style: Txt.sans(Txt.small, weight: FontWeight.w500, color: Palette.olive)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s['full_name']}', style: Txt.sans(Txt.body, weight: FontWeight.w600)),
                Text('${s['matric_no'] ?? ''}', style: Txt.mono(Txt.label, color: Palette.inkSoft)),
                Text('${s['school_name'] ?? ''}', style: Txt.sans(Txt.label, color: Palette.inkFaint), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
      ],
    );
  }
}
