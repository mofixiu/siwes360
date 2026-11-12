import 'package:flutter/material.dart';
import 'package:siwes360/screens/shared/settings.dart';
import 'package:siwes360/screens/student/editStudentProfile.dart';
import 'package:siwes360/screens/student/student_nav.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';

/// The student's record: official details from the institution (locked) and
/// the placement details they entered (editable from Edit profile).
class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool _loading = true;
  String? _error;
  int? _id;
  Map<String, dynamic> _s = {};
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
    final id = (session.roleData['user_id'] as num?)?.toInt() ?? session.id;
    final result = await RequestService.getStudentById(id);
    final photo = await Session.photoPath('student', id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _id = id;
      _photo = photo;
      if (result?['status'] == 'success') {
        _error = null;
        _s = Map<String, dynamic>.from(result!['data']);
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  Future<void> _edit() async {
    if (_id == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditStudentProfile(studentId: _id!)));
    _load();
  }

  String _v(String key) => '${_s[key] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final calendar = InternshipCalendar.from(_s['internship_start_date'], _s['internship_end_date']);
    return Scaffold(
      bottomNavigationBar: const StudentNavBar(currentIndex: 2),
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
                              onPressed: () async {
                                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                _load();
                              },
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
                                    Text(_v('matric_no'), style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                                    const SizedBox(height: Space.xs),
                                    InlineLink('Edit profile', onTap: _edit),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SectionLabel('Official record'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.page),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Official records cannot be edited.', style: Txt.smallStyle),
                              const SizedBox(height: Space.xs),
                              LockedField(label: 'Institution', value: _v('school_name')),
                              LockedField(label: 'Department', value: _v('department')),
                              LockedField(label: 'Level', value: _s['level'] == null ? '' : '${_s['level']} level'),
                              LockedField(label: 'Matric number', value: _v('matric_no'), mono: true),
                              LockedField(label: 'Email', value: _v('email'), mono: true),
                            ],
                          ),
                        ),
                        const SectionLabel('Placement'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.page),
                          child: Column(
                            children: [
                              const Rule(),
                              DetailLine(label: 'Phone', value: _v('phone'), mono: true),
                              DetailLine(label: 'Company', value: _v('workplace_name')),
                              DetailLine(label: 'Address', value: _v('workplace_address')),
                              DetailLine(label: 'Location', value: _v('workplace_location')),
                              DetailLine(label: 'Supervisor', value: _v('supervisor_name')),
                              DetailLine(
                                label: 'Internship',
                                value: calendar == null
                                    ? ''
                                    : '${Dates.full(calendar.start)} – ${Dates.full(calendar.end)}',
                                mono: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
