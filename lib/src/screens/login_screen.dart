import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../theme/glass_theme.dart';
import '../theme/glass_widgets.dart';

/// Two-step passwordless login:
///   step 0: enter email → Resend sends a 6-digit code
///   step 1: enter the code → session issued
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  late final List<TextEditingController> _codeCtrls;
  late final List<FocusNode> _codeFocus;
  bool _codeStep = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeCtrls = List.generate(6, (_) => TextEditingController());
    _codeFocus = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _codeCtrls) {
      c.dispose();
    }
    for (final f in _codeFocus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.requestOtp(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _codeStep = true;
        _loading = false;
      });
      _codeFocus.first.requestFocus();
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    final code = _codeCtrls.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = 'کد ۶ رقمی رو کامل وارد کن.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.verifyOtp(_emailCtrl.text, code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.9),
            radius: 1.3,
            colors: [Color(0xFF2A0A12), GlassTheme.bgDeep],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassPanel(
                  borderRadius: 32,
                  padding: const EdgeInsets.all(32),
                  opacity: 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(child: _LogoSmall()),
                      const SizedBox(height: 22),
                      Text(
                        _codeStep ? 'کد تایید رو وارد کن' : 'وارد شبدیز شو',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _codeStep
                            ? 'کد ۶ رقمی به ${_emailCtrl.text.trim()} ارسال شد.'
                            : 'ایمیلت رو بده؛ یه کد ۶ رقمی برات می‌فرستیم.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: GlassTheme.textMuted, height: 1.8),
                      ),
                      const SizedBox(height: 28),
                      if (!_codeStep) ...[
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(hintText: 'you@example.com'),
                          onSubmitted: (_) => _sendCode(),
                        ),
                      ] else ...[
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (i) => _codeBox(i)),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                      ],
                      const SizedBox(height: 26),
                      GlassButton(
                        label: _codeStep ? 'ورود' : 'دریافت کد',
                        icon: _codeStep ? Icons.lock_open_rounded : Icons.mail_outline_rounded,
                        loading: _loading,
                        onPressed: _codeStep ? _verify : _sendCode,
                      ),
                      if (_codeStep) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading ? null : () => setState(() => _codeStep = false),
                          child: const Text('تغییر ایمیل',
                              style: TextStyle(color: GlassTheme.textMuted, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'ورود اختیاریه — بدون ورود هم می‌تونی استفاده کنی، ولی با حساب کاربری علاقه‌مندی‌هات همه‌جا همراهته.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: GlassTheme.textMuted, height: 1.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _codeBox(int index) {
    return Container(
      width: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _codeCtrls[index],
        focusNode: _codeFocus[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: GlassTheme.accent, width: 1.6),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _codeFocus[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _codeFocus[index - 1].requestFocus();
          }
          if (_codeCtrls.every((c) => c.text.isNotEmpty)) {
            _verify();
          }
        },
      ),
    );
  }
}

class _LogoSmall extends StatelessWidget {
  const _LogoSmall();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: GlassTheme.accentGradient,
            boxShadow: [
              BoxShadow(
                color: GlassTheme.accent.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.star_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 14),
        Text(AppConfig.appName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }
}
