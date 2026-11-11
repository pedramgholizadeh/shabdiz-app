import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/movie_detail.dart';
import '../models/screening.dart';

class MovieRepository {
  MovieRepository(this._dio);

  final Dio _dio;

  Future<List<Screening>> timeline() async {
    final response = await _dio.get<dynamic>('/timeline');
    final data = unwrapData(response);
    return (data['items'] as List<dynamic>? ?? const [])
        .map((item) => Screening.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<MovieDetail> detail(String slug) async {
    final response = await _dio.get<dynamic>('/movies/$slug');
    return MovieDetail.fromJson(unwrapData(response));
  }
}

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(ref.watch(apiClientProvider)),
);

final timelineProvider = FutureProvider.autoDispose<List<Screening>>(
  (ref) => ref.watch(movieRepositoryProvider).timeline(),
);

final movieDetailProvider =
    FutureProvider.autoDispose.family<MovieDetail, String>(
  (ref, slug) => ref.watch(movieRepositoryProvider).detail(slug),
);
