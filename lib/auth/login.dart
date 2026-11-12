import 'package:flutter/material.dart';
import 'package:siwes360/auth/forgotPassword.dart';
import 'package:siwes360/auth/supervisorSignup.dart';
import 'package:siwes360/screens/student/firstLoginSetup.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/role_router.dart';
import 'package:siwes360/widgets/logo.dart';
import 'package:siwes360/widgets/paper.dart';

/// Sign in for every role. Students and school admins are given their login by
/// their institution, so only workplace supervisors can register here.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await RequestService.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (result == null || result['status'] != 'success') {
        showNote(context, result?['message'] ?? 'Could not sign in', error: true);
        return;
      }
      await RequestService.saveAuthToken(result['data']['token']);
      final user = Map<String, dynamic>.from(result['data']['user']);
      final roleData = result['data']['role_data'] == null ? null : Map<String, dynamic>.from(result['data']['role_data']);
      final saved = <String, dynamic>{...user, 'role_data': roleData};
      await RequestService.saveUserData(saved);
      if (!mounted) return;

      final firstLogin = user['role'] == 'student' &&
          roleData != null &&
          (roleData['is_first_login'] == true || roleData['is_first_login'] == 1 || roleData['is_first_login'] == '1');
      if (firstLogin) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FirstLoginSetup(userData: saved)));
      } else {
        RoleRouter.navigateToRoleBasedHome(context, '${user['role']}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: ConstrainedBox(
                // At least a screen tall, so the notes sit at the foot of the page.
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Space.xl),
                        const _CoverLabel(),
                        const SizedBox(height: Space.xxl),
                        Text('Sign in', style: Txt.titleStyle),
                        const SizedBox(height: Space.lg),
                        Text('EMAIL', style: Txt.labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          style: Txt.bodyStyle,
                          decoration: const InputDecoration(hintText: 'you@example.com'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Enter your email';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: Space.lg),
                        Row(
                          children: [
                            Expanded(child: Text('PASSWORD', style: Txt.labelStyle)),
                            InlineLink(
                              'Forgot password?',
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPassword())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _password,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signIn(),
                          style: Txt.bodyStyle,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              tooltip: _showPassword ? 'Hide password' : 'Show password',
                              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: Space.xl),
                        PrimaryButton(label: 'Sign in', onPressed: _signIn, busy: _busy),
                        const Spacer(),
                        const SizedBox(height: Space.xl),
                        const Rule(),
                        const SizedBox(height: Space.lg),
                        Text(
                          'Students get their login from their institution\'s SIWES office.',
                          style: Txt.smallStyle,
                        ),
                        const SizedBox(height: Space.sm),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Workplace supervisor? ', style: Txt.smallStyle),
                            InlineLink(
                              'Register your account',
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupervisorSignup())),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of the sign in page, like the label on a logbook's cover: a double
/// ruled box with the mark, the name and what the book is.
class _CoverLabel extends StatelessWidget {
  const _CoverLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: 1.5)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.lg),
        decoration: BoxDecoration(
          color: Palette.sheet.withValues(alpha: 0.6),
          border: Border.all(color: Palette.ink, width: 0.75),
        ),
        child: Column(
          children: [
            const SiwesMark(size: 52),
            const SizedBox(height: Space.md),
            Text('SIWES360', style: Txt.sans(Txt.display, weight: FontWeight.w700).copyWith(letterSpacing: 1.5)),
            const SizedBox(height: Space.xs),
            Text('DAILY LOGBOOK', style: Txt.mono(Txt.small, weight: FontWeight.w500, color: Palette.inkSoft).copyWith(letterSpacing: 3)),
            const SizedBox(height: Space.lg),
            const Rule(),
            const SizedBox(height: Space.md),
            Text(
              'Students’ Industrial Work Experience Scheme',
              textAlign: TextAlign.center,
              style: Txt.smallStyle,
            ),
          ],
        ),
      ),
    );
  }
}
