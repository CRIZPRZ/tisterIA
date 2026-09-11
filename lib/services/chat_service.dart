import 'package:dio/dio.dart';
import 'api_client.dart';

import '../models/chat.dart';
import 'auth_service.dart';

class ChatLimitReachedException implements Exception {}

class ChatReply {
  final String text;
  final List<ChatOutcome> outcomes;
  final List<String> suggestions;

  const ChatReply({required this.text, required this.outcomes, required this.suggestions});
}

class ChatService {
  ChatService._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await AuthService.instance.tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.headers.addAll(await AuthService.instance.authHeader());
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // cae al error original
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ChatService instance = ChatService._internal();

  final Dio _dio = apiClient;

  Future<ChatReply> sendMessage(String pickId, String message) async {
    try {
      final res = await _dio.post(
        '/chat/$pickId',
        data: {'message': message},
        options: Options(headers: await AuthService.instance.authHeader()),
      );
      final data = res.data as Map<String, dynamic>;
      return ChatReply(
        text: data['reply'] as String,
        outcomes: (data['outcomes'] as List? ?? [])
            .map((e) => ChatOutcome.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggestions: (data['suggestions'] as List? ?? []).cast<String>(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw ChatLimitReachedException();
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchHistory(String pickId) async {
    final res = await _dio.get(
      '/chat/$pickId/history',
      options: Options(headers: await AuthService.instance.authHeader()),
    );
    return (res.data as List).map((e) {
      final json = e as Map<String, dynamic>;
      return ChatMessage(
        role: json['role'] == 'ai' ? ChatRole.ai : ChatRole.user,
        text: json['text'] as String,
        outcomes: (json['outcomes'] as List? ?? [])
            .map((o) => ChatOutcome.fromJson(o as Map<String, dynamic>))
            .toList(),
        suggestions: (json['suggestions'] as List? ?? []).cast<String>(),
      );
    }).toList();
  }
}
