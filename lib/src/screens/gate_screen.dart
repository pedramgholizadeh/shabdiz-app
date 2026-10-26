import 'dart:math';
import 'package:flutter/material.dart';
import '../config.dart';
import '../services/geo_service.dart';
import '../theme/glass_theme.dart';
import '../theme/glass_widgets.dart';

/// Bootstrap gate shown before the app loads:
///  - brief branded splash while services initialize
///  - friendly "turn off your VPN" screen when the IP is outside Iran
class GateScreen extends StatefulWidget {
  final Future<void> Function() init;
  final VoidCallback onReady;

  const GateScreen({super.key, required this.init, required this.onReady});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> with SingleTickerProviderStateMixin {
  final GeoService _geo = GeoService();
  GeoStatus _status = GeoStatus.unknown;
  bool _checking = true;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _run();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final results = await Future.wait([_geo.check(), widget.init()]);
    if (!mounted) return;
    setState(() {
      _status = results[0] as GeoStatus;
      _checking = false;
    });
    if (_status == GeoStatus.iran || _status == GeoStatus.unknown) {
      widget.onReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.8),
          radius: 1.4,
          colors: [Color(0xFF2A0A12), GlassTheme.bgDeep],
          stops: [0.0, 0.6],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: _checking
              ? _splash()
              : (_status == GeoStatus.iran || _status == GeoStatus.unknown
                  ? const SizedBox.shrink()
                  : _vpnNotice()),
        ),
      ),
    );
  }

  Widget _splash() {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Logo(size: 84),
          const SizedBox(height: 20),
          Text(AppConfig.appName,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('سینمای بی‌مرز، با یک کلیک',
              style: TextStyle(color: GlassTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _vpnNotice() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GlassPanel(
        borderRadius: 32,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
        opacity: 0.08,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GlassTheme.accent.withValues(alpha: 0.14),
                  border: Border.all(color: GlassTheme.accent.withValues(alpha: 0.5), width: 1.5),
                ),
                child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 26),
              const Text(
                'وی‌پی‌ان روشنه! 🔌',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              const Text(
                'شبدیز فقط داخل ایران سرویس می‌ده.\n'
                'لطفاً وی‌پی‌ان رو خاموش کن و دوباره امتحان کن —\n'
                'بعدش همه چی سر جاشه و فیلم و سریال منتظرته! 🍿',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.9, color: GlassTheme.textMuted),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                child: GlassButton(
                  label: 'خاموش کردم، دوباره چک کن',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    setState(() => _checking = true);
                    _run();
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_status == GeoStatus.unknown)
                const Text(
                  'اگه مشکل ادامه داشت، بعداً دوباره سر بزن.',
                  style: TextStyle(fontSize: 11.5, color: GlassTheme.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatefulWidget {
  final double size;
  const _Logo({required this.size});

  @override
  State<_Logo> createState() => _LogoState();
}

class _LogoState extends State<_Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final pulse = _pulse;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = 0.35 + 0.25 * sin(pulse.value * pi);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: GlassTheme.accentGradient,
            boxShadow: [
              BoxShadow(
                color: GlassTheme.accent.withValues(alpha: glow),
                blurRadius: 42,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.star_rounded, color: Colors.white, size: size * 0.55),
        );
      },
    );
  }
}
