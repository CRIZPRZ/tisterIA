import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';

class EventsService {
  EventsService._internal();
  static final EventsService instance = EventsService._internal();

  final Dio _dio = apiClient;

  Future<List<MatchEvent>> fetchEvents(String pickId) async {
    try {
      final res = await _dio.get('/events/$pickId');
      return (res.data as List).map((e) => MatchEvent.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      // 404 = todavía no hay eventos (partido no empezó) — no es un error
      // de red, es un estado vacío legítimo.
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }
}
