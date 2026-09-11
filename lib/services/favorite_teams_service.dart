import 'package:dio/dio.dart';
import 'api_client.dart';

import 'auth_service.dart';
import 'retry.dart';

/// Equipos favoritos globales (no por liga) — alimentan el auto-follow del
/// backend: en cuanto se genera un pick de un fixture donde juega uno de
/// estos equipos, se sigue automático (misma campanita 🔔), en cualquier
/// liga/torneo que juegue.
class FavoriteTeamsService {
  FavoriteTeamsService._internal();
  static final FavoriteTeamsService instance = FavoriteTeamsService._internal();

  final Dio _dio = apiClient;

  Future<Set<int>> fetchFavorites() async {
    final res = await withRetry(
      () async => _dio.get('/favorite-teams', options: Options(headers: await AuthService.instance.authHeader())),
    );
    return (res.data as List).cast<int>().toSet();
  }

  /// Idempotente (manda el estado deseado) — reintentar ante un timeout es
  /// seguro, mismo patrón que /follows.
  Future<bool> setFavorite(int teamId, bool favorite) async {
    final res = await withRetry(
      () async => _dio.post(
        '/favorite-teams/$teamId',
        data: {'favorite': favorite},
        options: Options(headers: await AuthService.instance.authHeader()),
      ),
    );
    return res.data['favorite'] as bool;
  }
}
