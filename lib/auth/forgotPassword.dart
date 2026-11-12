import 'package:flutter/material.dart';
import 'package:siwes360/auth/otpforgotpassword.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// Reset password, step 1 of 3: the email the account signs in with. The
/// server emails a 6-digit code to it (POST /auth/forgot-password).
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    setState(() => _busy = true);
    try {
      final result = await RequestService.forgotPassword(email);
      if (!mounted) return;
      if (result?['status'] != 'success') {
        showNote(context, result?['message'] ?? 'Could not send a code', error: true);
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OTPForgotPassword(email: email)));
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
                  Text('Forgot your password?', style: Txt.titleStyle),
                  const SizedBox(height: Space.xs),
                  Text('Enter the email you sign in with and we will send you a 6-digit code.', style: Txt.smallStyle),
                  const SizedBox(height: Space.xl),
                  Text('EMAIL', style: Txt.labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofocus: true,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _sendCode(),
                    style: Txt.bodyStyle,
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Enter your email';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: Space.xl),
                  PrimaryButton(label: 'Send code', onPressed: _sendCode, busy: _busy),
                  const SizedBox(height: Space.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
