import 'package:dio/dio.dart';
import 'api_client.dart';

import 'auth_service.dart';
import 'retry.dart';

class NotificationsService {
  NotificationsService._internal();
  static final NotificationsService instance = NotificationsService._internal();

  final Dio _dio = apiClient;

  Future<Map<String, bool>> fetchPrefs() async {
    final res = await withRetry(
      () async => _dio.get('/notifications/prefs', options: Options(headers: await AuthService.instance.authHeader())),
    );
    return (res.data as Map<String, dynamic>).map((k, v) => MapEntry(k, v as bool));
  }

  Future<void> updatePrefs(Map<String, bool> changes) async {
    await _dio.put(
      '/notifications/prefs',
      data: changes,
      options: Options(headers: await AuthService.instance.authHeader()),
    );
  }

  Future<void> registerToken(String token, String platform) async {
    await _dio.post(
      '/notifications/register-token',
      data: {'token': token, 'platform': platform},
      options: Options(headers: await AuthService.instance.authHeader()),
    );
  }
}
