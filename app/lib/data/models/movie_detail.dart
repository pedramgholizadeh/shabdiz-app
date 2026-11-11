import 'movie.dart';
import 'screening.dart';

class MovieDetail {
  const MovieDetail({required this.movie, required this.screenings});

  factory MovieDetail.fromJson(Map<String, dynamic> json) => MovieDetail(
        movie: Movie.fromJson(json['movie'] as Map<String, dynamic>? ?? const {}),
        screenings: (json['screenings'] as List<dynamic>? ?? const [])
            .map((item) => Screening.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Movie movie;
  final List<Screening> screenings;
}
