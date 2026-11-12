import 'package:flutter/material.dart';
import 'package:siwes360/screens/student/editStudentProfile.dart';
import 'package:siwes360/screens/supervisor/editSupervisorProfile.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/session.dart';
import 'package:siwes360/widgets/paper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings for every role: only things that work. Edit profile (students and
/// supervisors), change password, the ITF website, and sign out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Session? _session;

  static const _roleNames = {
    'student': 'Student',
    'supervisor': 'Workplace supervisor',
    'admin': 'Institution SIWES coordinator',
    'itf': 'ITF officer',
  };

  @override
  void initState() {
    super.initState();
    Session.load().then((s) {
      if (mounted) setState(() => _session = s);
    });
  }

  Future<void> _signOut() async {
    final ok = await confirm(context, title: 'Sign out?', message: 'You will need your email and password to sign in again.', action: 'Sign out');
    if (ok && mounted) Session.signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Settings'),
      ),
      body: s == null
          ? const LoadingView()
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
                  child: Row(
                    children: [
                      Monogram(name: s.fullName, size: 44),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.fullName, style: Txt.titleStyle),
                            Text(s.email, style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                            Text(_roleNames[s.role] ?? s.role, style: Txt.smallStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Account'),
                const Rule(),
                if (s.role == 'student' || s.role == 'supervisor')
                  LedgerRow(
                    leading: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => s.role == 'student'
                            ? EditStudentProfile(studentId: (s.roleData['user_id'] as num?)?.toInt() ?? s.id)
                            : EditSupervisorProfile(supervisorId: s.id),
                      ),
                    ),
                    child: Text('Edit profile', style: Txt.bodyStyle),
                  ),
                LedgerRow(
                  leading: const Icon(Icons.lock_outline, size: 20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                  child: Text('Change password', style: Txt.bodyStyle),
                ),
                const SectionLabel('Help'),
                const Rule(),
                LedgerRow(
                  leading: const Icon(Icons.open_in_new, size: 20),
                  showChevron: false,
                  onTap: () => launchUrl(Uri.parse('https://www.itf.gov.ng'), mode: LaunchMode.externalApplication),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ITF website', style: Txt.bodyStyle),
                      Text('SIWES guidelines and contacts', style: Txt.smallStyle),
                    ],
                  ),
                ),
                LedgerRow(
                  leading: const Icon(Icons.info_outline, size: 20),
                  trailing: Text('1.0.0', style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                  child: Text('Version', style: Txt.bodyStyle),
                ),
                const SizedBox(height: Space.xl),
                const Rule(),
                LedgerRow(
                  leading: const Icon(Icons.logout, size: 20, color: Palette.brick),
                  showChevron: false,
                  onTap: _signOut,
                  child: Text('Sign out', style: Txt.sans(Txt.body, weight: FontWeight.w600, color: Palette.brick)),
                ),
                const SizedBox(height: Space.xxl),
              ],
            ),
    );
  }
}

/// Change password with the current one (POST /auth/change-password).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final result = await RequestService.changePassword(_current.text, _next.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result?['status'] == 'success') {
      showNote(context, 'Password changed');
      Navigator.pop(context);
    } else {
      showNote(context, result?['message'] ?? 'Could not change your password', error: true);
    }
  }

  Widget _field(String label, TextEditingController c, String? Function(String?) validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Txt.labelStyle),
          const SizedBox(height: 6),
          TextFormField(controller: c, obscureText: true, style: Txt.bodyStyle, validator: validator),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Change password'),
      ),
      bottomNavigationBar: BottomAction(child: PrimaryButton(label: 'Change password', onPressed: _save, busy: _busy)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Space.page),
          children: [
            _field('Current password', _current, (v) => (v ?? '').isEmpty ? 'Enter your current password' : null),
            _field('New password', _next, (v) => (v ?? '').length < 8 ? 'Use at least 8 characters' : null),
            _field('New password again', _again, (v) => v != _next.text ? 'The passwords do not match' : null),
          ],
        ),
      ),
    );
  }
}
