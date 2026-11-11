import 'json_utils.dart';

class Movie {
  const Movie({
    required this.id,
    required this.slug,
    required this.titleFa,
    required this.titleEn,
    required this.synopsis,
    required this.coverUrl,
    required this.backdropUrl,
    required this.year,
    required this.durationSeconds,
    required this.imdbRating,
    required this.rottenTomatoesRating,
    required this.director,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: asInt(json['id']),
      slug: asString(json['slug']),
      titleFa: asString(json['title_fa']),
      titleEn: asString(json['title_en']),
      synopsis: asString(json['synopsis_fa']),
      coverUrl: asString(json['cover_url']),
      backdropUrl: asString(json['backdrop_url']),
      year: asInt(json['year']),
      durationSeconds: asInt(json['duration_seconds']),
      imdbRating: asDouble(json['imdb_rating']),
      rottenTomatoesRating: asInt(json['rt_rating']),
      director: asString(json['director']),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((genre) => asString(genre))
          .where((genre) => genre.isNotEmpty)
          .toList(growable: false),
    );
  }

  final int id;
  final String slug;
  final String titleFa;
  final String titleEn;
  final String synopsis;
  final String coverUrl;
  final String backdropUrl;
  final int year;
  final int durationSeconds;
  final double? imdbRating;
  final int rottenTomatoesRating;
  final String director;
  final List<String> genres;

  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    return '$minutes دقیقه';
  }
}
