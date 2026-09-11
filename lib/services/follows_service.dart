import 'package:dio/dio.dart';
import 'api_client.dart';

import 'auth_service.dart';
import 'retry.dart';

/// "Seguir" un partido (🔔) para recibir sus notificaciones puntuales:
/// gol, alineación confirmada, resultado final.
class FollowsService {
  FollowsService._internal();
  static final FollowsService instance = FollowsService._internal();

  final Dio _dio = apiClient;

  /// fixture_ids (extraídos de "af-{fixtureId}-{market}") que el usuario sigue.
  Future<Set<int>> fetchFollowed() async {
    final res = await withRetry(
      () async => _dio.get('/follows', options: Options(headers: await AuthService.instance.authHeader())),
    );
    return (res.data as List).cast<int>().toSet();
  }

  /// Manda el estado deseado (no "voltea") — el endpoint es idempotente a
  /// propósito, así que esto se puede reintentar seguro ante un timeout sin
  /// arriesgarse a des-seguir por accidente algo que sí se guardó.
  Future<bool> setFollowing(String pickId, bool following) async {
    final res = await withRetry(
      () async => _dio.post(
        '/follows/$pickId',
        data: {'following': following},
        options: Options(headers: await AuthService.instance.authHeader()),
      ),
    );
    return res.data['following'] as bool;
  }
}
