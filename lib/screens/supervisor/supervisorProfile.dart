import 'package:flutter/material.dart';
import 'package:siwes360/screens/shared/settings.dart';
import 'package:siwes360/screens/supervisor/editSupervisorProfile.dart';
import 'package:siwes360/screens/supervisor/supervisor_nav.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';

/// The supervisor's contact and workplace details, and the institutions their
/// interns come from.
class SupervisorProfile extends StatefulWidget {
  const SupervisorProfile({super.key});

  @override
  State<SupervisorProfile> createState() => _SupervisorProfileState();
}

class _SupervisorProfileState extends State<SupervisorProfile> {
  bool _loading = true;
  String? _error;
  int? _id;
  Map<String, dynamic> _s = {};
  List<Map<String, dynamic>> _students = [];
  String? _photo;

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
    final results = await Future.wait([
      RequestService.getSupervisorById(session.id),
      RequestService.getSupervisorStudents(session.id),
    ]);
    final photo = await Session.photoPath('supervisor', session.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _id = session.id;
      _photo = photo;
      if (results[0]?['status'] == 'success') {
        _error = null;
        _s = Map<String, dynamic>.from(results[0]!['data']);
        _students = results[1]?['status'] == 'success'
            ? List<Map<String, dynamic>>.from((results[1]!['data'] as List).map((e) => Map<String, dynamic>.from(e)))
            : [];
      } else {
        _error = results[0]?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  Future<void> _edit() async {
    if (_id == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditSupervisorProfile(supervisorId: _id!)));
    _load();
  }

  String _v(String key) => '${_s[key] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final schools = <String, int>{};
    for (final st in _students) {
      final name = '${st['school_name'] ?? 'Institution not set'}';
      schools[name] = (schools[name] ?? 0) + 1;
    }
    return Scaffold(
      bottomNavigationBar: const SupervisorNavBar(currentIndex: 2),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: Palette.ink,
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: Space.xxl),
                      children: [
                        PageHeader(
                          title: 'Profile',
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
                          child: Row(
                            children: [
                              Monogram(name: _v('full_name'), size: 64, photoPath: _photo),
                              const SizedBox(width: Space.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_v('full_name'), style: Txt.titleStyle),
                                    Text(
                                      [_s['position'], _s['organization']].where((v) => v != null && '$v'.isNotEmpty).join(', '),
                                      style: Txt.smallStyle,
                                    ),
                                    const SizedBox(height: Space.xs),
                                    InlineLink('Edit profile', onTap: _edit),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SectionLabel('Contact'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.page),
                          child: Column(
                            children: [
                              const Rule(),
                              DetailLine(label: 'Email', value: _v('email'), mono: true),
                              DetailLine(label: 'Phone', value: _v('phone'), mono: true),
                              DetailLine(label: 'Organisation', value: _v('organization')),
                              DetailLine(label: 'Position', value: _v('position')),
                            ],
                          ),
                        ),
                        SectionLabel(
                          'Interns',
                          trailing: Text(plural(_students.length, 'student'), style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                        ),
                        const Rule(),
                        if (schools.isEmpty)
                          const EmptyNote('No interns yet', detail: 'Students choose you as their supervisor when they set up their logbook.'),
                        for (final entry in schools.entries)
                          LedgerRow(
                            showChevron: false,
                            trailing: Text(plural(entry.value, 'student'), style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                            child: Text(entry.key, style: Txt.bodyStyle),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
