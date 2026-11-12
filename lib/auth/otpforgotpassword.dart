import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siwes360/auth/createnewpassword.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// Reset password, step 2 of 3: the 6-digit code emailed to [email]
/// (POST /auth/verify-reset-otp). A correct code returns a single-use reset
/// token for step 3.
class OTPForgotPassword extends StatefulWidget {
  const OTPForgotPassword({super.key, required this.email});

  final String email;

  @override
  State<OTPForgotPassword> createState() => _OTPForgotPasswordState();
}

class _OTPForgotPasswordState extends State<OTPForgotPassword> {
  static const _length = 6;

  /// The server sends at most one code a minute.
  static const _resendAfter = 60;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  bool _busy = false;
  bool _resending = false;
  int _secondsLeft = _resendAfter;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = _resendAfter;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final result = await RequestService.forgotPassword(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    if (result?['status'] != 'success') {
      showNote(context, result?['message'] ?? 'Could not send a new code', error: true);
      return;
    }
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(_startCountdown);
    showNote(context, 'A new code is on its way');
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != _length) {
      showNote(context, 'Enter all 6 digits of the code', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await RequestService.verifyResetOTP(widget.email, otp);
      if (!mounted) return;
      final token = result?['data'] is Map ? result!['data']['reset_token'] : null;
      if (result?['status'] != 'success' || token is! String) {
        showNote(context, result?['message'] ?? 'That code did not work', error: true);
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreateNewPassword(resetToken: token)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty && index == _length - 1) {
      _focusNodes[index].unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.stamp),
      borderSide: const BorderSide(color: Palette.ruleStrong),
    );
    final minutes = _secondsLeft ~/ 60;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.xl),
                Text('Enter the code', style: Txt.titleStyle),
                const SizedBox(height: Space.xs),
                Text('We sent a 6-digit code to', style: Txt.smallStyle),
                const SizedBox(height: 2),
                Text(widget.email, style: Txt.mono(Txt.small, weight: FontWeight.w500)),
                const SizedBox(height: Space.xl),
                Text('CODE', style: Txt.labelStyle),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Row(
                    children: [
                      for (var i = 0; i < _length; i++) ...[
                        if (i > 0) const SizedBox(width: Space.sm),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              autofocus: i == 0,
                              expands: true,
                              maxLines: null,
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: Txt.mono(Txt.title, weight: FontWeight.w500),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Palette.sheet,
                                contentPadding: EdgeInsets.zero,
                                border: box,
                                enabledBorder: box,
                                focusedBorder: box.copyWith(borderSide: const BorderSide(color: Palette.ink, width: 1.4)),
                              ),
                              onChanged: (value) => _onDigitChanged(i, value),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _secondsLeft > 0
                      ? Text.rich(
                          TextSpan(
                            text: 'You can ask for a new code in ',
                            style: Txt.smallStyle,
                            children: [TextSpan(text: '$minutes:$seconds', style: Txt.mono(Txt.small, color: Palette.inkSoft))],
                          ),
                        )
                      : _resending
                          ? Text('Sending a new code', style: Txt.smallStyle)
                          : Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('No code? ', style: Txt.smallStyle),
                                InlineLink('Send a new one', onTap: _resend),
                              ],
                            ),
                ),
                const SizedBox(height: Space.xl),
                PrimaryButton(label: 'Verify code', onPressed: _verify, busy: _busy),
                const SizedBox(height: Space.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
