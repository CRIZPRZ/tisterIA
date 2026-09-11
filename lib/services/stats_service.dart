import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';

class StatsService {
  StatsService._internal();
  static final StatsService instance = StatsService._internal();

  final Dio _dio = apiClient;

  Future<List<MatchStatRow>> fetchStats(String pickId) async {
    try {
      final res = await _dio.get('/stats/$pickId');
      return (res.data as List).map((e) => MatchStatRow.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      // 404 = todavía no hay estadísticas (partido no empezó) — no es un
      // error de red, es un estado vacío legítimo.
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }
}
