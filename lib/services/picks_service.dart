import 'package:dio/dio.dart';

import '../models/pick.dart';
import 'auth_service.dart';

class PicksService {
  PicksService._internal();
  static final PicksService instance = PicksService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<List<Pick>> fetchPicks() async {
    final res = await _dio.get('/picks');
    return (res.data as List).map((e) => Pick.fromJson(e as Map<String, dynamic>)).toList();
  }
}
