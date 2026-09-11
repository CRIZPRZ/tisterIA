import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';
import 'retry.dart';

class PicksService {
  PicksService._internal();
  static final PicksService instance = PicksService._internal();

  final Dio _dio = apiClient;

  Future<List<Pick>> fetchPicks() async {
    final res = await withRetry(() => _dio.get('/picks'));
    return (res.data as List).map((e) => Pick.fromJson(e as Map<String, dynamic>)).toList();
  }
}
