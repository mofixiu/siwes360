import 'package:flutter/material.dart';
import 'package:siwes360/auth/login.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// Registration for workplace supervisors, the only role that signs up in the
/// app. Students and school admins get their login from their institution.
class SupervisorSignup extends StatefulWidget {
  const SupervisorSignup({super.key});

  @override
  State<SupervisorSignup> createState() => _SupervisorSignupState();
}

class _SupervisorSignupState extends State<SupervisorSignup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _positionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!RequestService.isInitialized) {
      RequestService.initialize();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await RequestService.register({
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role': 'supervisor',
        'organization': _organizationController.text.trim(),
        'position': _positionController.text.trim(),
      });
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        showNote(context, 'Account created. Sign in to continue.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
          (_) => false,
        );
      } else {
        showNote(context, result?['message'] ?? 'Could not register your account', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      showNote(context, 'Could not register your account. Check your connection and try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toSignIn() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // No title: the heading below names the page.
        appBar: AppBar(
          leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Space.xl),
                  Text('Register as a workplace supervisor', style: Txt.displayStyle),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Students choose you as their supervisor when they set up their logbook.',
                    style: Txt.smallStyle,
                  ),

                  _heading('Your details'),
                  const Rule(),
                  const SizedBox(height: Space.lg),
                  _field(
                    label: 'Full name',
                    controller: _nameController,
                    hint: 'First and last name',
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your full name' : null,
                  ),
                  _field(
                    label: 'Work email',
                    controller: _emailController,
                    hint: 'you@company.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  _field(
                    label: 'Phone number',
                    controller: _phoneController,
                    hint: '0800 000 0000',
                    keyboardType: TextInputType.phone,
                    mono: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your phone number' : null,
                  ),

                  _heading('Workplace'),
                  const Rule(),
                  const SizedBox(height: Space.lg),
                  _field(
                    label: 'Organisation',
                    controller: _organizationController,
                    hint: 'Company or organisation name',
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your organisation' : null,
                  ),
                  _field(
                    label: 'Position',
                    controller: _positionController,
                    hint: 'e.g. Site engineer',
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your position' : null,
                  ),

                  _heading('Password'),
                  const Rule(),
                  const SizedBox(height: Space.lg),
                  _field(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'At least 8 characters',
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      if (v.length < 8) return 'Use at least 8 characters';
                      return null;
                    },
                  ),
                  _field(
                    label: 'Password again',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onTogglePassword: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter the password again';
                      if (v != _passwordController.text) return 'The passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: Space.sm),
                  PrimaryButton(label: 'Register', onPressed: _handleRegister, busy: _isLoading),
                  const SizedBox(height: Space.xl),
                  const Rule(),
                  const SizedBox(height: Space.lg),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Already registered? ', style: Txt.smallStyle),
                      InlineLink('Sign in', onTap: _toSignIn),
                    ],
                  ),
                  const SizedBox(height: Space.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => SectionLabel(text, padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm));

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    bool mono = false,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Txt.labelStyle),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !isPasswordVisible,
            autocorrect: !isPassword && keyboardType != TextInputType.emailAddress,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: mono ? Txt.mono(Txt.body) : Txt.bodyStyle,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: isPassword
                  ? IconButton(
                      tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                      icon: Icon(isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: onTogglePassword,
                    )
                  : null,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
