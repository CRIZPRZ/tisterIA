import 'package:dio/dio.dart';

import '../models/pick.dart';
import 'auth_service.dart';

class LineupService {
  LineupService._internal();
  static final LineupService instance = LineupService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<List<RealTeamLineup>> fetchLineups(String pickId) async {
    final res = await _dio.get('/lineups/$pickId');
    return (res.data as List).map((e) => RealTeamLineup.fromJson(e as Map<String, dynamic>)).toList();
  }
}
