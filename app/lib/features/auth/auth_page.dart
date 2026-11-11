import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/brand_mark.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _codeStep = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'یک ایمیل معتبر وارد کنید.');
      return;
    }
    await _run(() async {
      await ref.read(authRepositoryProvider).requestOtp(email);
      if (!mounted) return;
      setState(() => _codeStep = true);
      _codeFocus.requestFocus();
    });
  }

  Future<void> _verify() async {
    await _run(() async {
      await ref.read(authRepositoryProvider).verifyOtp(
            _emailController.text.trim(),
            _codeController.text.trim(),
          );
      if (mounted) context.go('/timeline');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(),
              const SizedBox(height: 56),
              Text(
                _codeStep ? 'کد ورود را وارد کنید' : 'به شب‌دیز خوش آمدید',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                _codeStep
                    ? 'کد شش‌رقمی به ${_emailController.text.trim()} ارسال شد.'
                    : 'با ایمیل خود وارد شوید؛ رمز عبوری لازم نیست.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (!_codeStep) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  onSubmitted: (_) => _requestCode(),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  enabled: !_busy,
                  maxLength: 6,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 26,
                    letterSpacing: 10,
                    color: AppColors.text,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _codeStep = false),
                    child: const Text(
                      'تغییر ایمیل',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: AppColors.live,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : (_codeStep ? _verify : _requestCode),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Text(_codeStep ? 'ورود به شب‌دیز' : 'دریافت کد ورود'),
              ),
              const SizedBox(height: 28),
              const Text(
                'با ورود، قوانین استفاده و حریم خصوصی شب‌دیز را می‌پذیرید.',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  height: 1.8,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
