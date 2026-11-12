import 'package:flutter/material.dart';
import 'package:siwes360/auth/login.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// Reset password, step 3 of 3: the new password, sent with the single-use
/// [resetToken] from step 2 (POST /auth/reset-password). Ends at sign in.
class CreateNewPassword extends StatefulWidget {
  const CreateNewPassword({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _busy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await RequestService.resetPassword(widget.resetToken, _passwordController.text);
      if (!mounted) return;
      if (result?['status'] != 'success') {
        showNote(context, result?['message'] ?? 'Could not change your password', error: true);
        return;
      }
      showNote(context, 'Password changed. Sign in with your new password.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: const Text('Reset password'),
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
                  Text('Choose a new password', style: Txt.titleStyle),
                  const SizedBox(height: Space.xs),
                  Text('At least 8 characters, with a capital letter and a number.', style: Txt.smallStyle),
                  const SizedBox(height: Space.xl),
                  _passwordField(
                    label: 'New password',
                    controller: _passwordController,
                    visible: _isPasswordVisible,
                    onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter a new password';
                      if (value.length < 8) return 'Use at least 8 characters';
                      if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include a capital letter';
                      if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include a number';
                      return null;
                    },
                  ),
                  _passwordField(
                    label: 'New password again',
                    controller: _confirmPasswordController,
                    visible: _isConfirmPasswordVisible,
                    onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _confirm(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter the password again';
                      if (value != _passwordController.text) return 'The passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: Space.sm),
                  PrimaryButton(label: 'Change password', onPressed: _confirm, busy: _busy),
                  const SizedBox(height: Space.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    bool autofocus = false,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
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
            obscureText: !visible,
            autocorrect: false,
            enableSuggestions: false,
            autofocus: autofocus,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: Txt.bodyStyle,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                tooltip: visible ? 'Hide password' : 'Show password',
                icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: onToggle,
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
