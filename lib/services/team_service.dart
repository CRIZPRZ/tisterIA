import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';
import 'auth_service.dart';

/// Historial de un equipo: todos los partidos (cualquier liga) donde jugó,
/// usando los picks 1X2 ya generados/backfilleados como fuente.
class TeamService {
  TeamService._internal();
  static final TeamService instance = TeamService._internal();

  final Dio _dio = apiClient;

  Future<List<Pick>> fetchMatches(int teamId) async {
    final res = await _dio.get(
      '/teams/$teamId/matches',
      options: Options(headers: await AuthService.instance.authHeader()),
    );
    return (res.data as List).map((j) => Pick.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<TeamOption>> fetchByLeague(int leagueId) async {
    final res = await _dio.get('/teams/by-league', queryParameters: {'league_id': leagueId});
    return (res.data as List).map((j) => TeamOption.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<TeamStats> fetchStats(int teamId, int leagueId) async {
    final res = await _dio.get('/teams/$teamId/stats', queryParameters: {'league_id': leagueId});
    return TeamStats.fromJson(res.data as Map<String, dynamic>);
  }
}
