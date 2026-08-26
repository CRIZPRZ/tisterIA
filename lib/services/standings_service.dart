import 'package:dio/dio.dart';

import '../models/pick.dart';
import 'auth_service.dart';

class StandingsService {
  StandingsService._internal();
  static final StandingsService instance = StandingsService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<List<StandingRow>> fetchStandings(String league, {Set<String> highlightTeams = const {}}) async {
    final res = await _dio.get('/standings', queryParameters: {'league': league});
    return (res.data as List)
        .map((e) => StandingRow.fromJson(e as Map<String, dynamic>, highlightTeams: highlightTeams))
        .toList();
  }
}
