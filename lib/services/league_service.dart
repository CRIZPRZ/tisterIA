import 'package:dio/dio.dart';
import 'api_client.dart';

class LeagueInfo {
  final int leagueId;
  final String name;

  const LeagueInfo({required this.leagueId, required this.name});

  String get logoUrl => 'https://media.api-sports.io/football/leagues/$leagueId.png';

  factory LeagueInfo.fromJson(Map<String, dynamic> json) => LeagueInfo(
        leagueId: json['leagueId'] as int,
        name: json['name'] as String,
      );
}

class LeagueService {
  LeagueService._internal();
  static final LeagueService instance = LeagueService._internal();

  final Dio _dio = apiClient;

  /// Todas las ligas activas agregadas desde el panel admin — reemplaza
  /// la lista fija que antes vivía hardcodeada en data/leagues.dart y no
  /// reflejaba ligas nuevas sin un release de la app.
  Future<List<LeagueInfo>> fetchActiveLeagues() async {
    final res = await _dio.get('/leagues');
    return (res.data as List).map((e) => LeagueInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}
