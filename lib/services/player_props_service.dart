import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/player_prop_pick.dart';

class PlayerPropsService {
  PlayerPropsService._internal();
  static final PlayerPropsService instance = PlayerPropsService._internal();

  final Dio _dio = apiClient;

  Future<List<PlayerPropPick>> fetchForFixture(int fixtureId) async {
    final res = await _dio.get('/player-props/$fixtureId');
    return (res.data as List).map((e) => PlayerPropPick.fromJson(e as Map<String, dynamic>)).toList();
  }
}
