import 'package:flutter_test/flutter_test.dart';
import 'package:shabdiz/core/utils/dates.dart';
import 'package:shabdiz/data/models/movie.dart';
import 'package:shabdiz/data/models/screening.dart';

void main() {
  test('Movie parses API payload', () {
    final movie = Movie.fromJson({
      'id': 7,
      'slug': 'odyssey',
      'title_fa': 'اودیسه',
      'title_en': 'The Odyssey',
      'synopsis_fa': 'داستان...',
      'year': 2026,
      'duration_seconds': 9000,
      'imdb_rating': 8.4,
      'rt_rating': 93,
      'director': 'Christopher Nolan',
      'genres': ['درام', 'ماجراجویی'],
    });

    expect(movie.titleFa, 'اودیسه');
    expect(movie.imdbRating, 8.4);
    expect(movie.genres, hasLength(2));
    expect(movie.durationLabel, '150 دقیقه');
  });

  test('Screening parses status and Jalali label', () {
    final screening = Screening.fromJson({
      'id': 3,
      'starts_at': '2026-11-21T17:30:00Z',
      'starts_at_jalali': '1405/08/30',
      'starts_at_label': 'شنبه ۳۰ آبان · ۲۱:۰۰',
      'ends_at': '2026-11-21T20:00:00Z',
      'status': 'live',
      'room': 'main',
      'movie': {'id': 7, 'title_fa': 'اودیسه', 'title_en': 'The Odyssey'},
    });

    expect(screening.isLive, isTrue);
    expect(screening.startsAtJalali, '1405/08/30');
  });

  test('Tehran Jalali conversion keeps the Persian calendar in sync', () {
    final date = DateTime.utc(2026, 11, 21, 17, 30);
    expect(Dates.jalaliDate(date), '1405/08/30');
    expect(Dates.clock(date), '21:00');
  });
}
