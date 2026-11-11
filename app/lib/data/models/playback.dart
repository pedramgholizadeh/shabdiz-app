import 'json_utils.dart';

class PlaybackTicket {
  const PlaybackTicket({
    required this.sessionId,
    required this.title,
    required this.sourceUrl,
    required this.subtitleUrl,
    required this.subtitleLabel,
    required this.positionSeconds,
    required this.serverTimeUtc,
    required this.isLive,
  });

  factory PlaybackTicket.fromJson(Map<String, dynamic> json) {
    return PlaybackTicket(
      sessionId: asString(json['session_id']),
      title: asString(json['movie_title_fa']),
      sourceUrl: asString(json['source_url']),
      subtitleUrl: asString(json['subtitle_url']),
      subtitleLabel: asString(json['subtitle_label'], 'زیرنویس'),
      positionSeconds: asInt(json['position_seconds']),
      serverTimeUtc: asUtcDate(json['server_time']),
      isLive: json['is_live'] == true,
    );
  }

  final String sessionId;
  final String title;
  final String sourceUrl;
  final String subtitleUrl;
  final String subtitleLabel;
  final int positionSeconds;
  final DateTime serverTimeUtc;
  final bool isLive;
}

class PlaybackSync {
  const PlaybackSync({
    required this.positionSeconds,
    required this.serverTimeUtc,
    required this.isLive,
  });

  factory PlaybackSync.fromJson(Map<String, dynamic> json) {
    return PlaybackSync(
      positionSeconds: asInt(json['position_seconds']),
      serverTimeUtc: asUtcDate(json['server_time']),
      isLive: json['is_live'] == true,
    );
  }

  final int positionSeconds;
  final DateTime serverTimeUtc;
  final bool isLive;
}
