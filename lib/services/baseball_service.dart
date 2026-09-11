import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/baseball_game.dart';

class BaseballService {
  BaseballService._internal();
  static final BaseballService instance = BaseballService._internal();

  final Dio _dio = apiClient;

  Future<List<BaseballGame>> fetchResults({int? leagueId}) async {
    final res = await _dio.get('/baseball/results', queryParameters: {
      if (leagueId != null) 'league_id': leagueId,
    });
    return (res.data as List).map((e) => BaseballGame.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// null = todavía no hay muestra suficiente de alguno de los dos equipos
  /// (backend regresa 404 en ese caso, no es un error de red).
  Future<KboPrediction?> fetchPrediction({required String teamA, required String teamB, int leagueId = 5}) async {
    try {
      final res = await _dio.get('/baseball/predict', queryParameters: {
        'team_a': teamA,
        'team_b': teamB,
        'league_id': leagueId,
      });
      return KboPrediction.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<KboBatchPrediction>> fetchPredictionBatch({int leagueId = 5}) async {
    final res = await _dio.get('/baseball/predict/batch', queryParameters: {'league_id': leagueId});
    return (res.data as List).map((e) => KboBatchPrediction.fromJson(e as Map<String, dynamic>)).toList();
  }
}
