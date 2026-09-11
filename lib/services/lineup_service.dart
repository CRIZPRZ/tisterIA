import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';

class LineupService {
  LineupService._internal();
  static final LineupService instance = LineupService._internal();

  final Dio _dio = apiClient;

  Future<List<RealTeamLineup>> fetchLineups(String pickId) async {
    try {
      final res = await _dio.get('/lineups/$pickId');
      return (res.data as List).map((e) => RealTeamLineup.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      // 404 = alineación todavía no confirmada — estado vacío legítimo, no
      // un error de red.
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }
}
