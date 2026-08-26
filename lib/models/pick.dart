enum Confidence { alta, media, baja }

Confidence confidenceFromString(String s) {
  switch (s) {
    case 'alta':
      return Confidence.alta;
    case 'baja':
      return Confidence.baja;
    default:
      return Confidence.media;
  }
}

/// Convierte el formato con signo de API-Football ("-3.5", "+2.5") a texto,
/// ej. "Menos de 3.5" / "Más de 2.5". Null si no hay dato.
String? goalsLineLabel(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final sign = raw[0];
  final value = raw.substring(1);
  if (sign == '-') return 'Menos de $value goles';
  if (sign == '+') return 'Más de $value goles';
  return '$raw goles';
}

class Pick {
  final String id;
  final String sport;
  final String league;
  final int? leagueId;
  final String? matchDate;
  final String time;
  final String teamA;
  final String teamB;
  final int? teamAId;
  final int? teamBId;
  final String pick;
  final int prob;
  final int? probHome;
  final int? probDraw;
  final int? probAway;
  final String? goalsLine;
  final String? goalsExpectedHome;
  final String? goalsExpectedAway;
  final Confidence confidence;
  final bool premium;
  final int modelAccuracy;
  final String h2h;
  final List<String> formA;
  final List<String> formB;
  final String analysisP1;
  final String analysisP2;
  final bool isLive;
  final String? liveScore;
  final int? liveMinute;

  const Pick({
    required this.id,
    required this.sport,
    required this.league,
    this.leagueId,
    this.matchDate,
    required this.time,
    required this.teamA,
    required this.teamB,
    this.teamAId,
    this.teamBId,
    required this.pick,
    required this.prob,
    this.probHome,
    this.probDraw,
    this.probAway,
    this.goalsLine,
    this.goalsExpectedHome,
    this.goalsExpectedAway,
    required this.confidence,
    required this.premium,
    required this.modelAccuracy,
    required this.h2h,
    required this.formA,
    required this.formB,
    required this.analysisP1,
    required this.analysisP2,
    this.isLive = false,
    this.liveScore,
    this.liveMinute,
  });

  String? get leagueLogoUrl => leagueId == null ? null : 'https://media.api-sports.io/football/leagues/$leagueId.png';
  String? get teamALogoUrl => teamAId == null ? null : 'https://media.api-sports.io/football/teams/$teamAId.png';
  String? get teamBLogoUrl => teamBId == null ? null : 'https://media.api-sports.io/football/teams/$teamBId.png';

  factory Pick.fromJson(Map<String, dynamic> json) => Pick(
        id: json['id'] as String,
        sport: json['sport'] as String,
        league: json['league'] as String,
        leagueId: json['leagueId'] as int?,
        matchDate: json['matchDate'] as String?,
        time: json['time'] as String,
        teamA: json['teamA'] as String,
        teamB: json['teamB'] as String,
        teamAId: json['teamAId'] as int?,
        teamBId: json['teamBId'] as int?,
        pick: json['pick'] as String,
        prob: json['prob'] as int,
        probHome: json['probHome'] as int?,
        probDraw: json['probDraw'] as int?,
        probAway: json['probAway'] as int?,
        goalsLine: json['goalsLine'] as String?,
        goalsExpectedHome: json['goalsExpectedHome'] as String?,
        goalsExpectedAway: json['goalsExpectedAway'] as String?,
        confidence: confidenceFromString(json['confidence'] as String),
        premium: json['premium'] as bool,
        modelAccuracy: json['modelAccuracy'] as int,
        h2h: json['h2h'] as String,
        formA: (json['formA'] as List).cast<String>(),
        formB: (json['formB'] as List).cast<String>(),
        analysisP1: json['analysisP1'] as String,
        analysisP2: json['analysisP2'] as String,
        isLive: json['isLive'] as bool? ?? false,
        liveScore: json['liveScore'] as String?,
        liveMinute: json['liveMinute'] as int?,
      );
}

class Plan {
  final String id;
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool recommended;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.recommended = false,
  });
}

class HistoryEntry {
  final String teamA;
  final String teamB;
  final String pick;
  final bool hit;
  final String date;
  final String league;
  final Confidence confidence;

  const HistoryEntry({
    required this.teamA,
    required this.teamB,
    required this.pick,
    required this.hit,
    required this.date,
    required this.league,
    required this.confidence,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        teamA: json['teamA'] as String,
        teamB: json['teamB'] as String,
        pick: json['pick'] as String,
        hit: json['hit'] as bool,
        date: json['date'] as String,
        league: json['league'] as String,
        confidence: confidenceFromString(json['confidence'] as String),
      );
}

class AccuracyBreakdown {
  final Confidence confidence;
  final int hits;
  final int total;
  final int pct;

  const AccuracyBreakdown({required this.confidence, required this.hits, required this.total, required this.pct});

  factory AccuracyBreakdown.fromJson(Map<String, dynamic> json) => AccuracyBreakdown(
        confidence: confidenceFromString(json['confidence'] as String),
        hits: json['hits'] as int,
        total: json['total'] as int,
        pct: json['pct'] as int,
      );
}

class AccuracySummary {
  final int overallPct;
  final int overallHits;
  final int overallTotal;
  final List<AccuracyBreakdown> breakdown;
  final List<HistoryEntry> picks;

  const AccuracySummary({
    required this.overallPct,
    required this.overallHits,
    required this.overallTotal,
    required this.breakdown,
    required this.picks,
  });

  factory AccuracySummary.fromJson(Map<String, dynamic> json) => AccuracySummary(
        overallPct: json['overallPct'] as int,
        overallHits: json['overallHits'] as int,
        overallTotal: json['overallTotal'] as int,
        breakdown: (json['breakdown'] as List).map((e) => AccuracyBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
        picks: (json['picks'] as List).map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class StandingRow {
  final int pos;
  final String team;
  final int played;
  final int goalDiff;
  final int points;
  final bool highlighted;

  const StandingRow({
    required this.pos,
    required this.team,
    required this.played,
    required this.goalDiff,
    required this.points,
    this.highlighted = false,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json, {Set<String> highlightTeams = const {}}) => StandingRow(
        pos: json['pos'] as int,
        team: json['team'] as String,
        played: json['played'] as int,
        goalDiff: json['goalDiff'] as int,
        points: json['points'] as int,
        highlighted: highlightTeams.contains(json['team']),
      );
}

class RealLineupPlayer {
  final int id;
  final int number;
  final String name;
  final String pos;

  const RealLineupPlayer({required this.id, required this.number, required this.name, required this.pos});

  String get photoUrl => 'https://media.api-sports.io/football/players/$id.png';

  factory RealLineupPlayer.fromJson(Map<String, dynamic> json) => RealLineupPlayer(
        id: json['id'] as int,
        number: json['number'] as int,
        name: json['name'] as String,
        pos: json['pos'] as String,
      );
}

class RealTeamLineup {
  final int teamId;
  final String team;
  final String formation;
  final String coach;
  final int? coachId;
  final List<List<RealLineupPlayer>> rows;

  const RealTeamLineup({
    required this.teamId,
    required this.team,
    required this.formation,
    required this.coach,
    required this.coachId,
    required this.rows,
  });

  String get logoUrl => 'https://media.api-sports.io/football/teams/$teamId.png';
  String? get coachPhotoUrl => coachId == null ? null : 'https://media.api-sports.io/football/coachs/$coachId.png';

  factory RealTeamLineup.fromJson(Map<String, dynamic> json) => RealTeamLineup(
        teamId: json['teamId'] as int,
        team: json['team'] as String,
        formation: json['formation'] as String,
        coach: json['coach'] as String,
        coachId: json['coachId'] as int?,
        rows: (json['rows'] as List)
            .map((row) => (row as List).map((p) => RealLineupPlayer.fromJson(p as Map<String, dynamic>)).toList())
            .toList(),
      );
}

class MatchStatRow {
  final String label;
  final String valueA;
  final String valueB;
  final double fractionA;

  const MatchStatRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.fractionA,
  });

  factory MatchStatRow.fromJson(Map<String, dynamic> json) => MatchStatRow(
        label: json['label'] as String,
        valueA: json['valueA'] as String,
        valueB: json['valueB'] as String,
        fractionA: (json['fractionA'] as num).toDouble(),
      );
}

