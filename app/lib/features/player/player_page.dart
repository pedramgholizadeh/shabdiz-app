import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  Player? _player;
  VideoController? _videoController;
  SubtitleTrack? _subtitleTrack;
  StreamSubscription<String>? _errorSubscription;
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  Timer? _hideControlsTimer;
  PlaybackTicket? _ticket;
  String? _error;
  bool _loading = true;
  bool _synced = true;
  bool _ended = false;
  bool _subtitleEnabled = false;
  bool _controlsVisible = true;

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _load();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _hideControlsTimer?.cancel();
    _sendFinalHeartbeat();
    _errorSubscription?.cancel();
    _player?.dispose();
    if (_isMobile) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  /// Records the last watched position before teardown; fire-and-forget.
  void _sendFinalHeartbeat() {
    final player = _player;
    if (player == null) return;
    final position = player.state.position.inSeconds;
    unawaited(
      ref
          .read(playbackRepositoryProvider)
          .heartbeat(widget.screeningId, positionSeconds: position)
          .then((_) {}, onError: (_) {}),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _ended = false;
    });
    _hideControlsTimer?.cancel();
    await _errorSubscription?.cancel();
    await _player?.dispose();
    _player = null;
    _videoController = null;
    _subtitleTrack = null;

    try {
      final repository = ref.read(playbackRepositoryProvider);
      final ticket = await repository.join(widget.screeningId);
      if (!mounted) return;

      final player = Player(
        configuration: const PlayerConfiguration(title: 'ShabDiz'),
      );
      final controller = VideoController(player);
      _player = player;
      _videoController = controller;
      _ticket = ticket;

      _errorSubscription = player.stream.error.listen((message) {
        if (!mounted) return;
        setState(() {
          _error = message.isEmpty
              ? 'پخش فیلم آغاز نشد. لینک پخش یا اتصال شبکه را بررسی کنید.'
              : 'خطای پخش: $message';
        });
      });

      await player.open(Media(ticket.sourceUrl), play: false);
      await player.seek(Duration(seconds: ticket.positionSeconds));

      if (ticket.subtitleUrl.isNotEmpty) {
        try {
          _subtitleTrack = SubtitleTrack.uri(
            ticket.subtitleUrl,
            title: ticket.subtitleLabel,
            language: 'fa',
          );
          await player.setSubtitleTrack(_subtitleTrack!);
          _subtitleEnabled = true;
        } catch (_) {
          _subtitleTrack = null;
          _subtitleEnabled = false;
        }
      }

      await player.play();
      if (!mounted) return;
      setState(() => _loading = false);

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

  /// The player is a top-level route: pop only when there is something to
  /// pop, otherwise return to the timeline.
  void _exitPlayer() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/timeline');
    }
  }

  Future<void> _resync() async {
    final player = _player;
    if (player == null) return;
    try {
      final sync =
          await ref.read(playbackRepositoryProvider).sync(widget.screeningId);
      if (!mounted) return;
      if (!sync.isLive) {
        await player.pause();
        setState(() => _ended = true);
        return;
      }
      final target = Duration(seconds: sync.positionSeconds);
      final drift = player.state.position - target;
      if (drift.inMilliseconds.abs() > 2500) {
        await player.seek(target);
      }
      if (mounted) setState(() => _synced = true);
    } catch (_) {
      if (mounted) setState(() => _synced = false);
    }
  }

  Future<void> _heartbeat() async {
    final player = _player;
    try {
      await ref
          .read(playbackRepositoryProvider)
          .heartbeat(
            widget.screeningId,
            positionSeconds: player?.state.position.inSeconds,
          );
    } catch (_) {
      // The next successful sync re-establishes presence.
    }
  }

  Future<void> _toggleSubtitle() async {
    final player = _player;
    final track = _subtitleTrack;
    if (player == null || track == null) return;
    try {
      final enable = !_subtitleEnabled;
      await player.setSubtitleTrack(
        enable ? track : SubtitleTrack.no(),
      );
      if (mounted) setState(() => _subtitleEnabled = enable);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تغییر زیرنویس ممکن نشد.')),
        );
      }
    }
  }

  void _togglePlay() {
    _player?.playOrPause();
    _showControlsTemporarily();
  }

  /// Reveal the controls and auto-hide them shortly after — the 10-foot TV
  /// flow relies on keys rather than taps, so controls must dismiss themselves.
  void _showControlsTemporarily() {
    if (!mounted) return;
    setState(() => _controlsVisible = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_player?.state.playing ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      if (!_controlsVisible) {
        _showControlsTemporarily();
        return KeyEventResult.handled;
      }
      _exitPlayer();
      return KeyEventResult.handled;
    }

    const playPauseKeys = [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.mediaPlayPause,
      LogicalKeyboardKey.mediaPlay,
      LogicalKeyboardKey.mediaPause,
      LogicalKeyboardKey.gameButtonA,
    ];
    if (playPauseKeys.contains(key)) {
      _togglePlay();
      return KeyEventResult.handled;
    }

    // The server owns the clock, so arrows never seek: they only surface the
    // controls (TV remotes send arrows from the D-pad). While the controls
    // are visible, arrows are left to the focus traversal between buttons.
    const revealKeys = [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.mediaStepForward,
      LogicalKeyboardKey.mediaStepBackward,
    ];
    if (revealKeys.contains(key)) {
      if (!_controlsVisible) {
        _showControlsTemporarily();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
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
              ? _PlayerError(message: _error!, onRetry: _load, onBack: _exitPlayer)
              : Focus(
                  autofocus: true,
                  onKeyEvent: _handleKey,
                  child: _buildPlayer(),
                ),
    );
  }

  Widget _buildPlayer() {
    final player = _player;
    final controller = _videoController;
    if (player == null || controller == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Video(
          controller: controller,
          controls: NoVideoControls,
          fit: BoxFit.contain,
          pauseUponEnteringBackgroundMode: true,
          subtitleViewConfiguration: const SubtitleViewConfiguration(
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(blurRadius: 6, color: Colors.black87, offset: Offset(0, 2)),
              ],
            ),
            textAlign: TextAlign.center,
            padding: EdgeInsets.fromLTRB(24, 24, 24, 64),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        ),
        StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, positionSnapshot) {
            return StreamBuilder<bool>(
              stream: player.stream.playing,
              initialData: player.state.playing,
              builder: (context, playingSnapshot) {
                return StreamBuilder<Duration>(
                  stream: player.stream.duration,
                  initialData: player.state.duration,
                  builder: (context, durationSnapshot) {
                    return AnimatedOpacity(
                      opacity: _controlsVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: IgnorePointer(
                        ignoring: !_controlsVisible,
                        child: _PlayerChrome(
                          title: _ticket?.title ?? '',
                          position: positionSnapshot.data ?? Duration.zero,
                          duration: durationSnapshot.data ?? Duration.zero,
                          isPlaying: playingSnapshot.data ?? false,
                          synced: _synced,
                          ended: _ended,
                          subtitleEnabled: _subtitleEnabled,
                          hasSubtitle:
                              (_ticket?.subtitleUrl.isNotEmpty ?? false) &&
                                  _subtitleTrack != null,
                          onClose: _exitPlayer,
                          onTogglePlay: _togglePlay,
                          onToggleSubtitle: _toggleSubtitle,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PlayerChrome extends StatelessWidget {
  const _PlayerChrome({
    required this.title,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.synced,
    required this.ended,
    required this.subtitleEnabled,
    required this.hasSubtitle,
    required this.onClose,
    required this.onTogglePlay,
    required this.onToggleSubtitle,
  });

  final String title;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool synced;
  final bool ended;
  final bool subtitleEnabled;
  final bool hasSubtitle;
  final VoidCallback onClose;
  final VoidCallback onTogglePlay;
  final Future<void> Function() onToggleSubtitle;

  @override
  Widget build(BuildContext context) {
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
                      onPressed: onTogglePlay,
                      icon: Icon(
                        isPlaying
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
  const _PlayerError({required this.message, required this.onRetry, required this.onBack});

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

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
                    onPressed: onBack,
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
