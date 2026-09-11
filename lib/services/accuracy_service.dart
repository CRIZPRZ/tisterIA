import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/pick.dart';

class AccuracyService {
  AccuracyService._internal();
  static final AccuracyService instance = AccuracyService._internal();

  final Dio _dio = apiClient;

  Future<AccuracySummary> fetchAccuracy({String? league, String? date}) async {
    final res = await _dio.get('/accuracy', queryParameters: {
      if (league != null) 'league': league,
      if (date != null) 'date': date,
    });
    return AccuracySummary.fromJson(res.data as Map<String, dynamic>);
  }
}
