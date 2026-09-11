import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/match_stream.dart';
import 'auth_service.dart';

class StreamService {
  StreamService._internal();
  static final StreamService instance = StreamService._internal();

  final Dio _dio = apiClient;

  /// null = sin transmisión disponible para este pick ahora mismo.
  Future<MatchStream?> fetchStream(String pickId) async {
    final res = await _dio.get(
      '/stream/$pickId',
      options: Options(headers: await AuthService.instance.authHeader()),
    );
    return MatchStream.fromJson(res.data as Map<String, dynamic>);
  }
}
