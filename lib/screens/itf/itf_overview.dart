import 'package:flutter/material.dart';
import 'package:siwes360/screens/shared/settings.dart';
import 'package:siwes360/screens/shared/student_list.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';

/// ITF oversight across institutions: totals, last week's sign-offs, and each
/// institution's students placed, logging and behind. Read-only.
class ItfOverview extends StatefulWidget {
  const ItfOverview({super.key});

  @override
  State<ItfOverview> createState() => _ItfOverviewState();
}

class _ItfOverviewState extends State<ItfOverview> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  String? _region;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await Session.load();
    final result = await RequestService.getItfOverview();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _region = session?.roleData['region'];
      if (result?['status'] == 'success') {
        _error = null;
        _data = Map<String, dynamic>.from(result!['data']);
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(color: Palette.ink, onRefresh: _load, child: _body()),
      ),
    );
  }

  Widget _body() {
    final t = Map<String, dynamic>.from(_data['totals'] ?? {});
    final lastWeek = Map<String, dynamic>.from(_data['last_week'] ?? {});
    final schools = List<Map<String, dynamic>>.from((_data['schools'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    int n(String key) => (t[key] as num?)?.toInt() ?? 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        PageHeader(
          title: 'Institutions',
          subtitle: Text(
            [if (_region != null) 'ITF ${_region!.toUpperCase()}', Dates.short(today()).toUpperCase()].join(' · '),
            style: Txt.mono(Txt.small, weight: FontWeight.w500, color: Palette.inkSoft),
          ),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined, color: Palette.ink),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
          child: FigureLine([
            Figure('${n('students')}', 'students'),
            Figure('${n('logging')}', 'logging', color: Palette.olive),
            Figure('${n('behind')}', 'behind', color: n('behind') > 0 ? Palette.brick : Palette.ink),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
          child: Text(
            '${schools.length} institutions · ${n('placed')} placed · last week ${lastWeek['signed'] ?? 0} of ${lastWeek['due'] ?? 0} weeks signed',
            style: Txt.mono(Txt.label, color: Palette.inkSoft),
          ),
        ),
        const SectionLabel('By institution'),
        const Rule(),
        if (schools.isEmpty) const EmptyNote('No institutions yet'),
        for (final school in schools) _schoolRow(school),
      ],
    );
  }

  Widget _schoolRow(Map<String, dynamic> school) {
    final t = Map<String, dynamic>.from(school['totals'] ?? {});
    final lastWeek = Map<String, dynamic>.from(school['last_week'] ?? {});
    int n(String key) => (t[key] as num?)?.toInt() ?? 0;
    return LedgerRow(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItfInstitution(school: school))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${school['name']}', style: Txt.sans(Txt.body, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${school['address'] ?? ''}', style: Txt.sans(Txt.label, color: Palette.inkFaint)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: Txt.mono(Txt.small, color: Palette.inkSoft),
              children: [
                TextSpan(text: '${n('students')} students · '),
                TextSpan(text: '${n('logging')} logging', style: const TextStyle(color: Palette.olive)),
                const TextSpan(text: ' · '),
                TextSpan(text: '${n('behind')} behind', style: TextStyle(color: n('behind') > 0 ? Palette.brick : null)),
              ],
            ),
          ),
          Text(
            'Last week ${lastWeek['signed'] ?? 0}/${lastWeek['due'] ?? 0} signed · ${n('pending_entries')} entries waiting',
            style: Txt.mono(Txt.label, color: Palette.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// One institution's students, read-only.
class ItfInstitution extends StatefulWidget {
  const ItfInstitution({super.key, required this.school});

  final Map<String, dynamic> school;

  @override
  State<ItfInstitution> createState() => _ItfInstitutionState();
}

class _ItfInstitutionState extends State<ItfInstitution> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await RequestService.getItfSchoolStudents((widget.school['id'] as num).toInt());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?['status'] == 'success') {
        _error = null;
        _students = List<Map<String, dynamic>>.from((result!['data']['students'] as List).map((e) => Map<String, dynamic>.from(e)));
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: Text('${widget.school['name']}'),
        ),
        body: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(color: Palette.ink, onRefresh: _load, child: StudentList(students: _students)),
      ),
    );
  }
}
