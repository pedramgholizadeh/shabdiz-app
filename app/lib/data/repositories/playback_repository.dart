import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/playback.dart';

class PlaybackRepository {
  PlaybackRepository(this._dio);

  final Dio _dio;

  Future<PlaybackTicket> join(int screeningId) async {
    final response = await _dio.post<dynamic>('/screenings/$screeningId/join');
    return PlaybackTicket.fromJson(unwrapData(response));
  }

  Future<PlaybackSync> sync(int screeningId) async {
    final response =
        await _dio.get<dynamic>('/screenings/$screeningId/timeline');
    return PlaybackSync.fromJson(unwrapData(response));
  }

  Future<void> heartbeat(int screeningId, {int? positionSeconds}) async {
    await _dio.post<dynamic>(
      '/screenings/$screeningId/heartbeat',
      data: positionSeconds == null
          ? null
          : {'position_seconds': positionSeconds},
    );
  }
}

final playbackRepositoryProvider = Provider<PlaybackRepository>(
  (ref) => PlaybackRepository(ref.watch(apiClientProvider)),
);

final playbackTicketProvider =
    FutureProvider.autoDispose.family<PlaybackTicket, int>(
  (ref, screeningId) =>
      ref.watch(playbackRepositoryProvider).join(screeningId),
);
