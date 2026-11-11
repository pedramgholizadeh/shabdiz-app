import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/duration_format.dart';
import '../../data/models/playback.dart';
import '../../data/repositories/playback_repository.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key, required this.screeningId});

  final int screeningId;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  VlcPlayerController? _controller;
  PlaybackTicket? _ticket;
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  String? _error;
  bool _loading = true;
  bool _synced = true;
  bool _ended = false;
  bool _subtitleEnabled = false;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _ended = false;
    });
    try {
      final repository = ref.read(playbackRepositoryProvider);
      final ticket = await repository.join(widget.screeningId);
      if (!mounted) return;

      final controller = VlcPlayerController.network(
        ticket.sourceUrl,
        hwAcc: HwAcc.auto,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
          subtitle: VlcSubtitleOptions([
            VlcSubtitleOptions.fontSize(22),
            VlcSubtitleOptions.boldStyle(true),
            VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
          ]),
        ),
      );

      controller.addOnInitListener(() async {
        await controller.setTime(ticket.positionSeconds * 1000);
        if (ticket.subtitleUrl.isNotEmpty) {
          try {
            await controller.addSubtitleFromNetwork(
              ticket.subtitleUrl,
              isSelected: true,
            );
            _subtitleEnabled = true;
          } catch (_) {
            _subtitleEnabled = false;
          }
        }
        await controller.play();
      });

      _controller = controller;
      _ticket = ticket;
      if (mounted) setState(() => _loading = false);

      _syncTimer?.cancel();
      _heartbeatTimer?.cancel();
      _syncTimer = Timer.periodic(AppConfig.syncInterval, (_) => _resync());
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _heartbeat(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(error);
      });
    }
  }

  Future<void> _resync() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final sync =
          await ref.read(playbackRepositoryProvider).sync(widget.screeningId);
      if (!mounted) return;
      if (!sync.isLive) {
        await controller.pause();
        setState(() => _ended = true);
        return;
      }
      final currentMs = await controller.getTime();
      final targetMs = sync.positionSeconds * 1000;
      if ((currentMs - targetMs).abs() > 2500) {
        await controller.setTime(targetMs);
      }
      if (mounted) setState(() => _synced = true);
    } catch (_) {
      if (mounted) setState(() => _synced = false);
    }
  }

  Future<void> _heartbeat() async {
    try {
      await ref
          .read(playbackRepositoryProvider)
          .heartbeat(widget.screeningId);
    } catch (_) {
      // The next successful sync re-establishes presence.
    }
  }

  Future<void> _toggleSubtitle() async {
    final controller = _controller;
    if (controller == null || _ticket?.subtitleUrl.isEmpty != false) return;
    try {
      final tracks = await controller.getSpuTracks();
      final ids = tracks.keys.where((id) => id >= 0).toList();
      if (ids.isEmpty) return;
      final enable = !_subtitleEnabled;
      await controller.setSpuTrack(enable ? ids.first : -1);
      if (mounted) setState(() => _subtitleEnabled = enable);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تغییر زیرنویس ممکن نشد.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _error != null
              ? _PlayerError(message: _error!, onRetry: _load)
              : _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<VlcPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.hasError) {
          return _PlayerError(
            message: 'پخش فیلم آغاز نشد. لینک پخش یا اتصال شبکه را بررسی کنید.',
            onRetry: _load,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: VlcPlayer(
                controller: controller,
                aspectRatio:
                    value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  setState(() => _controlsVisible = !_controlsVisible),
            ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _PlayerChrome(
                  title: _ticket?.title ?? '',
                  value: value,
                  synced: _synced,
                  ended: _ended,
                  subtitleEnabled: _subtitleEnabled,
                  hasSubtitle: _ticket?.subtitleUrl.isNotEmpty ?? false,
                  onClose: () => context.pop(),
                  onTogglePlay: () async {
                    if (value.isPlaying) {
                      await controller.pause();
                    } else {
                      await controller.play();
                    }
                  },
                  onToggleSubtitle: _toggleSubtitle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerChrome extends StatelessWidget {
  const _PlayerChrome({
    required this.title,
    required this.value,
    required this.synced,
    required this.ended,
    required this.subtitleEnabled,
    required this.hasSubtitle,
    required this.onClose,
    required this.onTogglePlay,
    required this.onToggleSubtitle,
  });

  final String title;
  final VlcPlayerValue value;
  final bool synced;
  final bool ended;
  final bool subtitleEnabled;
  final bool hasSubtitle;
  final VoidCallback onClose;
  final Future<void> Function() onTogglePlay;
  final Future<void> Function() onToggleSubtitle;

  @override
  Widget build(BuildContext context) {
    final duration = value.duration;
    final position = value.position;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title.isEmpty ? 'سالن پخش شب‌دیز' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                _SyncBadge(synced: synced && !ended, ended: ended),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xE6000000), Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onTogglePlay(),
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${formatPlaybackTime(position)} / '
                      '${formatPlaybackTime(duration)}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    if (hasSubtitle)
                      TextButton.icon(
                        onPressed: () => onToggleSubtitle(),
                        icon: Icon(
                          subtitleEnabled
                              ? Icons.subtitles_rounded
                              : Icons.subtitles_off_rounded,
                          color: subtitleEnabled
                              ? AppColors.gold
                              : Colors.white54,
                          size: 20,
                        ),
                        label: Text(
                          'زیرنویس',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: subtitleEnabled
                                ? AppColors.gold
                                : Colors.white54,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.synced, required this.ended});

  final bool synced;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final (label, color) = ended
        ? ('پایان سانس', AppColors.muted)
        : synced
            ? ('هم‌زمان با سالن', AppColors.success)
            : ('در حال همگام‌سازی', AppColors.gold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.muted, size: 44),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.white70,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'بازگشت',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                    child: const Text('تلاش دوباره'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
