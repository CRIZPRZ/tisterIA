import 'package:dio/dio.dart';
import 'api_client.dart';

import 'auth_service.dart';
import 'retry.dart';

class UsageInfo {
  final String plan;
  final int picksViewedToday;
  final int? picksLimit;
  final int chatMessagesToday;
  final int? chatLimit;
  final Set<int> viewedFixtureIds;

  const UsageInfo({
    required this.plan,
    required this.picksViewedToday,
    required this.picksLimit,
    required this.chatMessagesToday,
    required this.chatLimit,
    required this.viewedFixtureIds,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
        plan: json['plan'] as String,
        picksViewedToday: json['picksViewedToday'] as int,
        picksLimit: json['picksLimit'] as int?,
        chatMessagesToday: json['chatMessagesToday'] as int,
        chatLimit: json['chatLimit'] as int?,
        viewedFixtureIds: ((json['viewedFixtureIds'] as List?) ?? []).cast<int>().toSet(),
      );
}

class ViewPickResult {
  final bool allowed;
  final int picksViewedToday;
  final int? picksLimit;

  const ViewPickResult({required this.allowed, required this.picksViewedToday, required this.picksLimit});

  factory ViewPickResult.fromJson(Map<String, dynamic> json) => ViewPickResult(
        allowed: json['allowed'] as bool,
        picksViewedToday: json['picksViewedToday'] as int,
        picksLimit: json['picksLimit'] as int?,
      );
}

class UsageService {
  UsageService._internal();
  static final UsageService instance = UsageService._internal();

  final Dio _dio = apiClient;

  Future<UsageInfo> fetchToday() async {
    final res = await withRetry(
      () async => _dio.get('/usage/today', options: Options(headers: await AuthService.instance.authHeader())),
    );
    return UsageInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ViewPickResult> tryViewPick(String pickId) async {
    final res = await _dio.post(
      '/usage/view-pick',
      data: {'pickId': pickId},
      options: Options(headers: await AuthService.instance.authHeader()),
    );
    return ViewPickResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Se llama después de que el usuario terminó de ver un rewarded ad completo.
  Future<int> grantBonusPick() async {
    final res = await _dio.post('/usage/bonus-pick', options: Options(headers: await AuthService.instance.authHeader()));
    return res.data['picksLimit'] as int;
  }
}
