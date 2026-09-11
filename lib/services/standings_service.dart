import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';

class StandingsService {
  StandingsService._internal();
  static final StandingsService instance = StandingsService._internal();

  final Dio _dio = apiClient;

  Future<List<StandingRow>> fetchStandings(String league, {Set<String> highlightTeams = const {}}) async {
    final res = await _dio.get('/standings', queryParameters: {'league': league});
    return (res.data as List)
        .map((e) => StandingRow.fromJson(e as Map<String, dynamic>, highlightTeams: highlightTeams))
        .toList();
  }

  /// Vacío cuando la liga no tiene fase eliminatoria (Premier League, La
  /// Liga) o todavía no llega a ella esta temporada.
  Future<List<BracketRound>> fetchBracket(String league, {Set<String> highlightTeams = const {}}) async {
    final res = await _dio.get('/standings/bracket', queryParameters: {'league': league});
    return (res.data as List)
        .map((e) => BracketRound.fromJson(e as Map<String, dynamic>, highlightTeams: highlightTeams))
        .toList();
  }
}
