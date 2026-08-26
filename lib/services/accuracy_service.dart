import 'package:dio/dio.dart';

import '../models/pick.dart';
import 'auth_service.dart';

class AccuracyService {
  AccuracyService._internal();
  static final AccuracyService instance = AccuracyService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<AccuracySummary> fetchAccuracy() async {
    final res = await _dio.get('/accuracy');
    return AccuracySummary.fromJson(res.data as Map<String, dynamic>);
  }
}
