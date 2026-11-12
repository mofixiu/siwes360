import 'package:flutter/material.dart';
import 'package:siwes360/screens/admin/admin_overview.dart';
import 'package:siwes360/screens/admin/admin_students.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// Workplace supervisors of the institution's students, with how much of those
/// students' work is waiting for them. Counts only this institution's students.
class AdminSupervisors extends StatefulWidget {
  const AdminSupervisors({super.key, this.pushed = false});

  final bool pushed;

  @override
  State<AdminSupervisors> createState() => _AdminSupervisorsState();
}

class _AdminSupervisorsState extends State<AdminSupervisors> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _supervisors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await RequestService.getAdminSupervisors();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?['status'] == 'success') {
        _error = null;
        _supervisors = List<Map<String, dynamic>>.from(
          (result!['data']['supervisors'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        if (!widget.pushed)
          PageHeader(
            title: 'Supervisors',
            subtitle: Text(
              '${plural(_supervisors.length, 'supervisor')} · sorted by work waiting',
              style: Txt.mono(Txt.small, color: Palette.inkSoft),
            ),
          ),
        const SizedBox(height: Space.lg),
        const Rule(),
        if (_supervisors.isEmpty) const EmptyNote('No supervisors linked yet'),
        for (final s in _supervisors) SupervisorRow(supervisor: s),
      ],
    );
    final content = _loading
        ? const LoadingView()
        : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : RefreshIndicator(color: Palette.ink, onRefresh: _load, child: list);
    return Scaffold(
      appBar: widget.pushed
          ? AppBar(
              leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              title: const Text('Supervisors'),
            )
          : null,
      bottomNavigationBar: widget.pushed ? null : const AdminNavBar(currentIndex: 2),
      body: widget.pushed ? content : SafeArea(bottom: false, child: content),
    );
  }
}

/// A supervisor with entries and weeks waiting for them. Opens their students.
class SupervisorRow extends StatelessWidget {
  const SupervisorRow({super.key, required this.supervisor});

  final Map<String, dynamic> supervisor;

  @override
  Widget build(BuildContext context) {
    final s = supervisor;
    final pending = (s['pending_entries'] as num?)?.toInt() ?? 0;
    final unsigned = (s['unsigned_weeks'] as num?)?.toInt() ?? 0;
    final oldest = parseDay(s['oldest_pending_date']);
    return LedgerRow(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminStudents(
            pushed: true,
            supervisorId: (s['supervisor_id'] as num).toInt(),
            supervisorName: '${s['full_name']}',
          ),
        ),
      ),
      leading: Monogram(name: s['full_name'], size: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s['full_name']}', style: Txt.sans(Txt.body, weight: FontWeight.w600)),
          Text(
            [plural((s['students'] as num).toInt(), 'student'), if (unsigned > 0) '${plural(unsigned, 'week')} unsigned'].join(' · '),
            style: Txt.mono(Txt.label, color: Palette.inkSoft),
          ),
          const SizedBox(height: 2),
          Text(
            pending == 0
                ? (unsigned == 0 ? 'Up to date' : 'No entries waiting')
                : '${plural(pending, 'entry', 'entries')} waiting${oldest == null ? '' : ' since ${Dates.dayMonth(oldest)}'}',
            style: Txt.mono(Txt.small, color: pending == 0 ? Palette.olive : Palette.ochre),
          ),
        ],
      ),
    );
  }
}
