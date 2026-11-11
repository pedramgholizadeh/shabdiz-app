import 'json_utils.dart';
import 'movie.dart';

class Screening {
  const Screening({
    required this.id,
    required this.movie,
    required this.startsAtUtc,
    required this.startsAtJalali,
    required this.startsAtLabel,
    required this.endsAtUtc,
    required this.status,
    required this.room,
  });

  factory Screening.fromJson(Map<String, dynamic> json) {
    return Screening(
      id: asInt(json['id']),
      movie: Movie.fromJson(json['movie'] as Map<String, dynamic>? ?? const {}),
      startsAtUtc: asUtcDate(json['starts_at']),
      startsAtJalali: asString(json['starts_at_jalali']),
      startsAtLabel: asString(json['starts_at_label']),
      endsAtUtc: asUtcDate(json['ends_at']),
      status: asString(json['status'], 'upcoming'),
      room: asString(json['room']),
    );
  }

  final int id;
  final Movie movie;
  final DateTime startsAtUtc;
  final String startsAtJalali;
  final String startsAtLabel;
  final DateTime endsAtUtc;
  final String status;
  final String room;

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
}
