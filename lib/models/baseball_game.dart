class BaseballGame {
  final int gameId;
  final String league;
  final String matchDate;
  final String time;
  final String teamA;
  final String teamB;
  final int? teamAId;
  final int? teamBId;
  final int? homeScore;
  final int? awayScore;
  final String status;

  const BaseballGame({
    required this.gameId,
    required this.league,
    required this.matchDate,
    required this.time,
    required this.teamA,
    required this.teamB,
    this.teamAId,
    this.teamBId,
    this.homeScore,
    this.awayScore,
    required this.status,
  });

  // API-Baseball sigue el mismo patrón de media que API-Football
  // (media.api-sports.io/{deporte}/{tipo}/{id}.png), solo cambia el
  // segmento del deporte.
  String? get teamALogoUrl => teamAId == null ? null : 'https://media.api-sports.io/baseball/teams/$teamAId.png';
  String? get teamBLogoUrl => teamBId == null ? null : 'https://media.api-sports.io/baseball/teams/$teamBId.png';

  factory BaseballGame.fromJson(Map<String, dynamic> json) => BaseballGame(
        gameId: json['gameId'] as int,
        league: json['league'] as String,
        matchDate: json['matchDate'] as String,
        time: json['time'] as String,
        teamA: json['teamA'] as String,
        teamB: json['teamB'] as String,
        teamAId: json['teamAId'] as int?,
        teamBId: json['teamBId'] as int?,
        homeScore: json['homeScore'] as int?,
        awayScore: json['awayScore'] as int?,
        status: json['status'] as String,
      );
}

class KboPrediction {
  final String favorite;
  final double probFavorite;
  final double runLine;
  final double probOver;
  final int sampleMin;

  const KboPrediction({
    required this.favorite,
    required this.probFavorite,
    required this.runLine,
    required this.probOver,
    required this.sampleMin,
  });

  factory KboPrediction.fromJson(Map<String, dynamic> json) => KboPrediction(
        favorite: json['favorite'] as String,
        probFavorite: (json['probFavorite'] as num).toDouble(),
        runLine: (json['runLine'] as num).toDouble(),
        probOver: (json['probOver'] as num).toDouble(),
        sampleMin: json['sampleMin'] as int,
      );
}

class KboBatchPrediction {
  final int gameId;
  final String favorite;
  final double probFavorite;
  final bool? hit;
  final double? runLine;
  final String? runSide; // "over" | "under"
  final double? probRunTotal;
  final bool? runTotalHit;

  const KboBatchPrediction({
    required this.gameId,
    required this.favorite,
    required this.probFavorite,
    this.hit,
    this.runLine,
    this.runSide,
    this.probRunTotal,
    this.runTotalHit,
  });

  factory KboBatchPrediction.fromJson(Map<String, dynamic> json) => KboBatchPrediction(
        gameId: json['gameId'] as int,
        favorite: json['favorite'] as String,
        probFavorite: (json['probFavorite'] as num).toDouble(),
        hit: json['hit'] as bool?,
        runLine: (json['runLine'] as num?)?.toDouble(),
        runSide: json['runSide'] as String?,
        probRunTotal: (json['probRunTotal'] as num?)?.toDouble(),
        runTotalHit: json['runTotalHit'] as bool?,
      );
}
