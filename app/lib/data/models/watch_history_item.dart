import 'json_utils.dart';

class WatchHistoryItem {
  const WatchHistoryItem({
    required this.screeningId,
    required this.movieSlug,
    required this.movieTitleFa,
    required this.coverUrl,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.percent,
    required this.completed,
    required this.startsAtLabel,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) =>
      WatchHistoryItem(
        screeningId: asInt(json['screening_id']),
        movieSlug: asString(json['movie_slug']),
        movieTitleFa: asString(json['movie_title_fa']),
        coverUrl: asString(json['cover_url']),
        positionSeconds: asInt(json['position_seconds']),
        durationSeconds: asInt(json['duration_seconds']),
        percent: asInt(json['percent']),
        completed: json['completed'] == true || asInt(json['completed']) == 1,
        startsAtLabel: asString(json['starts_at_label']),
      );

  final int screeningId;
  final String movieSlug;
  final String movieTitleFa;
  final String coverUrl;
  final int positionSeconds;
  final int durationSeconds;
  final int percent;
  final bool completed;
  final String startsAtLabel;
}
