import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/device_service.dart';
import '../theme/glass_theme.dart';
import '../theme/glass_widgets.dart';

/// Account & profile: shows the linked device, profile editing (name) and
/// login/logout. Login is optional in Shabdiz.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  bool _loadingDevice = true;
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) _nameCtrl.text = auth.user!.name;
    _deviceId = await DeviceService.instance.ensureDeviceId();
    if (mounted) setState(() => _loadingDevice = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(name: _nameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروفایل ذخیره شد ✓')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ذخیره نشد؛ دوباره تلاش کن.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('حساب کاربری')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassPanel(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(26),
                  opacity: 0.08,
                  child: user == null ? _guestBody() : _userBody(user),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(22),
                  opacity: 0.05,
                  child: _loadingDevice
                      ? const SizedBox(
                          height: 20,
                          child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                      : Row(
                          children: [
                            const Icon(Icons.devices_rounded, color: GlassTheme.textMuted, size: 20),
                            const SizedBox(width: 10),
                            const Text('شناسه دستگاه شما:',
                                style: TextStyle(fontSize: 12.5, color: GlassTheme.textMuted)),
                            const Spacer(),
                            Text(
                              _deviceId.length > 10 ? '${_deviceId.substring(0, 10)}…' : _deviceId,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: GlassTheme.textPrimary,
                                  fontFamilyFallback: ['monospace']),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _guestBody() {
    return Column(
      children: [
        const Icon(Icons.person_off_rounded, size: 52, color: GlassTheme.textMuted),
        const SizedBox(height: 16),
        const Text('مهمان هستی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text(
          'بدون ورود هم می‌تونی همه‌چیز رو ببینی، ولی با یه حساب رایگان علاقه‌مندی‌هات\nهیچ‌وقت گم نمی‌شن.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: GlassTheme.textMuted, height: 1.9),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: 240,
          child: GlassButton(
            label: 'ورود با ایمیل',
            icon: Icons.mail_outline_rounded,
            onPressed: () => Navigator.of(context).pushNamed('/login'),
          ),
        ),
      ],
    );
  }

  Widget _userBody(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: GlassTheme.accentSecondary.withValues(alpha: 0.25),
              child: Text(
                user.name.isNotEmpty ? user.name.characters.first : user.email.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name.isNotEmpty ? user.name : 'کاربر شبدیز',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(fontSize: 13, color: GlassTheme.textMuted),
                      textDirection: TextDirection.ltr),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('نام نمایشی', style: TextStyle(fontSize: 13, color: GlassTheme.textMuted)),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'مثلاً: پدرام')),
        const SizedBox(height: 18),
        GlassButton(
          label: 'ذخیره پروفایل',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _save,
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: GlassTheme.bgSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                title: const Text('خروج از حساب؟'),
                content: const Text('علاقه‌مندی‌های این دستگاه باقی می‌مونن.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('منصرف شدم')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
                ],
              ),
            );
            if (confirmed == true && mounted) {
              await context.read<AuthProvider>().logout();
            }
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('خروج از حساب'),
        ),
      ],
    );
  }
}
