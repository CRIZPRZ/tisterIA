import 'package:dio/dio.dart';

import '../models/pick.dart';
import 'auth_service.dart';

class StatsService {
  StatsService._internal();
  static final StatsService instance = StatsService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<List<MatchStatRow>> fetchStats(String pickId) async {
    final res = await _dio.get('/stats/$pickId');
    return (res.data as List).map((e) => MatchStatRow.fromJson(e as Map<String, dynamic>)).toList();
  }
}
