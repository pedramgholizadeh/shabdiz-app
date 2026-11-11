import 'package:flutter_test/flutter_test.dart';
import 'package:shabdiz/core/utils/dates.dart';
import 'package:shabdiz/data/models/movie.dart';
import 'package:shabdiz/data/models/screening.dart';
import 'package:shabdiz/data/models/user.dart';
import 'package:shabdiz/data/models/watch_history_item.dart';

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

  test('User flags guest accounts from the API payload', () {
    final guest = User.fromJson({
      'id': 12,
      'email': null,
      'name': 'مهمان',
      'is_guest': true,
    });
    final member = User.fromJson({
      'id': 13,
      'email': 'user@example.com',
      'name': 'کاربر',
      'is_guest': 0,
    });

    expect(guest.isGuest, isTrue);
    expect(guest.email, isEmpty);
    expect(member.isGuest, isFalse);
    expect(User.fromJson({'id': 1}).isGuest, isFalse);
  });

  test('WatchHistoryItem parses progress rows', () {
    final item = WatchHistoryItem.fromJson({
      'screening_id': 9,
      'movie_slug': 'odyssey',
      'movie_title_fa': 'اودیسه',
      'cover_url': 'https://cdn.example.com/cover.jpg',
      'position_seconds': 5400,
      'duration_seconds': 9000,
      'percent': 60,
      'completed': false,
      'starts_at_label': 'شنبه ۳۰ آبان · ۲۱:۰۰',
    });

    expect(item.movieSlug, 'odyssey');
    expect(item.percent, 60);
    expect(item.completed, isFalse);

    final completed = WatchHistoryItem.fromJson({
      'screening_id': 9,
      'movie_slug': 'odyssey',
      'movie_title_fa': 'اودیسه',
      'cover_url': '',
      'position_seconds': 9000,
      'duration_seconds': 9000,
      'percent': 100,
      'completed': true,
      'starts_at_label': '',
    });
    expect(completed.completed, isTrue);
  });
}
