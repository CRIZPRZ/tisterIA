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
  final String? venue;
  final String? venueCity;
  final String teamA;
  final String teamB;
  final int? teamAId;
  final int? teamBId;
  final String pick;
  final int prob;
  final int? probHome;
  final int? probDraw;
  final int? probAway;
  // desglose de la fuente que REALMENTE se usó (ml/dixon_coles/api) — este
  // es el que se debe mostrar, no probHome/probDraw/probAway (esos son
  // siempre el % crudo de la API, solo para comparación interna).
  final int? market0ProbHome;
  final int? market0ProbDraw;
  final int? market0ProbAway;
  final int? predictedScoreHome;
  final int? predictedScoreAway;
  final List<ScoreProbability> scoreProbabilities;
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
  final int? liveExtra;
  final String? liveStatus;
  final int liveYellowA;
  final int liveYellowB;
  final int liveRedA;
  final int liveRedB;
  // true/false una vez que el partido terminó y hay resultado real para
  // calificar este pick; null mientras no se pueda calificar todavía.
  final bool? hit;

  const Pick({
    required this.id,
    required this.sport,
    required this.league,
    this.leagueId,
    this.matchDate,
    required this.time,
    this.venue,
    this.venueCity,
    required this.teamA,
    required this.teamB,
    this.teamAId,
    this.teamBId,
    required this.pick,
    required this.prob,
    this.probHome,
    this.probDraw,
    this.probAway,
    this.market0ProbHome,
    this.market0ProbDraw,
    this.market0ProbAway,
    this.predictedScoreHome,
    this.predictedScoreAway,
    this.scoreProbabilities = const [],
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
    this.liveExtra,
    this.liveStatus,
    this.liveYellowA = 0,
    this.liveYellowB = 0,
    this.liveRedA = 0,
    this.liveRedB = 0,
    this.hit,
  });

  /// true si el backend decidió no fabricar una predicción (datos
  /// insuficientes) — el partido sigue mostrándose (alineación, eventos,
  /// stats), solo sin número de confianza inventado.
  bool get hasNoPrediction => pick == 'Sin predicción disponible';

  /// El id del fixture real de API-Football, extraído de "af-{fixtureId}-{market}".
  int? get fixtureId {
    final parts = id.split('-');
    if (parts.length < 3 || parts[0] != 'af') return null;
    return int.tryParse(parts[1]);
  }

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
        venue: json['venue'] as String?,
        venueCity: json['venueCity'] as String?,
        teamA: json['teamA'] as String,
        teamB: json['teamB'] as String,
        teamAId: json['teamAId'] as int?,
        teamBId: json['teamBId'] as int?,
        pick: json['pick'] as String,
        prob: json['prob'] as int,
        probHome: json['probHome'] as int?,
        probDraw: json['probDraw'] as int?,
        probAway: json['probAway'] as int?,
        market0ProbHome: json['market0ProbHome'] as int?,
        market0ProbDraw: json['market0ProbDraw'] as int?,
        market0ProbAway: json['market0ProbAway'] as int?,
        predictedScoreHome: json['predictedScoreHome'] as int?,
        predictedScoreAway: json['predictedScoreAway'] as int?,
        scoreProbabilities: (json['scoreProbabilities'] as List?)
                ?.map((e) => ScoreProbability.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
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
        liveExtra: json['liveExtra'] as int?,
        liveStatus: json['liveStatus'] as String?,
        liveYellowA: json['liveYellowA'] as int? ?? 0,
        liveYellowB: json['liveYellowB'] as int? ?? 0,
        liveRedA: json['liveRedA'] as int? ?? 0,
        liveRedB: json['liveRedB'] as int? ?? 0,
        hit: json['hit'] as bool?,
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
  final String market;

  const HistoryEntry({
    required this.teamA,
    required this.teamB,
    required this.pick,
    required this.hit,
    required this.date,
    required this.league,
    required this.confidence,
    required this.market,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        teamA: json['teamA'] as String,
        teamB: json['teamB'] as String,
        pick: json['pick'] as String,
        hit: json['hit'] as bool,
        date: json['date'] as String,
        league: json['league'] as String,
        confidence: confidenceFromString(json['confidence'] as String),
        market: json['market'] as String? ?? 'Otro',
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
  final List<String> availableLeagues;
  final List<String> availableDates;
  final List<String> availableMatches;

  const AccuracySummary({
    required this.overallPct,
    required this.overallHits,
    required this.overallTotal,
    required this.breakdown,
    required this.picks,
    this.availableLeagues = const [],
    this.availableDates = const [],
    this.availableMatches = const [],
  });

  factory AccuracySummary.fromJson(Map<String, dynamic> json) => AccuracySummary(
        overallPct: json['overallPct'] as int,
        overallHits: json['overallHits'] as int,
        overallTotal: json['overallTotal'] as int,
        breakdown: (json['breakdown'] as List).map((e) => AccuracyBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
        picks: (json['picks'] as List).map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)).toList(),
        availableLeagues: (json['availableLeagues'] as List?)?.map((e) => e as String).toList() ?? const [],
        availableDates: (json['availableDates'] as List?)?.map((e) => e as String).toList() ?? const [],
        availableMatches: (json['availableMatches'] as List?)?.map((e) => e as String).toList() ?? const [],
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

class BracketMatch {
  final String teamHome;
  final String teamAway;
  final int? teamHomeId;
  final int? teamAwayId;
  final int? goalsHome;
  final int? goalsAway;
  final String? status;
  final String? date;
  final String? time;
  final bool highlighted;
  /// true solo para el partido sintético "Final" que la app agrega cuando
  /// la ronda todavía no está definida en la API — no viene del backend.
  final bool isPlaceholder;

  const BracketMatch({
    required this.teamHome,
    required this.teamAway,
    required this.teamHomeId,
    required this.teamAwayId,
    required this.goalsHome,
    required this.goalsAway,
    required this.status,
    required this.date,
    this.time,
    this.highlighted = false,
    this.isPlaceholder = false,
  });

  /// FT/AET/PEN — el partido ya tiene marcador definitivo que mostrar.
  bool get isFinished => status == 'FT' || status == 'AET' || status == 'PEN';

  String? get teamHomeLogoUrl => teamHomeId == null ? null : 'https://media.api-sports.io/football/teams/$teamHomeId.png';
  String? get teamAwayLogoUrl => teamAwayId == null ? null : 'https://media.api-sports.io/football/teams/$teamAwayId.png';

  factory BracketMatch.fromJson(Map<String, dynamic> json, {Set<String> highlightTeams = const {}}) => BracketMatch(
        teamHome: json['teamHome'] as String,
        teamAway: json['teamAway'] as String,
        teamHomeId: json['teamHomeId'] as int?,
        teamAwayId: json['teamAwayId'] as int?,
        goalsHome: json['goalsHome'] as int?,
        goalsAway: json['goalsAway'] as int?,
        status: json['status'] as String?,
        date: json['date'] as String?,
        time: json['time'] as String?,
        highlighted: highlightTeams.contains(json['teamHome']) || highlightTeams.contains(json['teamAway']),
      );
}

class BracketRound {
  final String round;
  final List<BracketMatch> matches;

  const BracketRound({required this.round, required this.matches});

  factory BracketRound.fromJson(Map<String, dynamic> json, {Set<String> highlightTeams = const {}}) => BracketRound(
        round: json['round'] as String,
        matches: (json['matches'] as List)
            .map((m) => BracketMatch.fromJson(m as Map<String, dynamic>, highlightTeams: highlightTeams))
            .toList(),
      );
}

class TeamOption {
  final int teamId;
  final String name;
  final String? logo;

  const TeamOption({required this.teamId, required this.name, this.logo});

  factory TeamOption.fromJson(Map<String, dynamic> json) => TeamOption(
        teamId: json['teamId'] as int,
        name: json['name'] as String,
        logo: json['logo'] as String?,
      );
}

class ScoreProbability {
  final int home;
  final int away;
  final int pct;
  const ScoreProbability({required this.home, required this.away, required this.pct});

  factory ScoreProbability.fromJson(Map<String, dynamic> json) => ScoreProbability(
        home: json['home'] as int,
        away: json['away'] as int,
        pct: json['pct'] as int,
      );
}

class TeamStats {
  final String? form;
  final int played;
  final int wins;
  final int draws;
  final int loses;
  final int goalsFor;
  final int goalsAgainst;
  final int cleanSheets;

  const TeamStats({
    required this.form,
    required this.played,
    required this.wins,
    required this.draws,
    required this.loses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.cleanSheets,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) => TeamStats(
        form: json['form'] as String?,
        played: json['played'] as int,
        wins: json['wins'] as int,
        draws: json['draws'] as int,
        loses: json['loses'] as int,
        goalsFor: json['goalsFor'] as int,
        goalsAgainst: json['goalsAgainst'] as int,
        cleanSheets: json['cleanSheets'] as int,
      );
}

class MatchEvent {
  final int minute;
  final int? extraMinute;
  final String type; // "Goal" | "Card"
  final String detail;
  final int teamId;
  final String team;
  final String player;
  final String? assist;

  const MatchEvent({
    required this.minute,
    required this.extraMinute,
    required this.type,
    required this.detail,
    required this.teamId,
    required this.team,
    required this.player,
    required this.assist,
  });

  bool get isGoal => type == 'Goal';
  bool get isRedCard => type == 'Card' && detail.contains('Red');
  bool get isYellowCard => type == 'Card' && !isRedCard;

  String get minuteLabel => extraMinute != null && extraMinute! > 0 ? "$minute+$extraMinute'" : "$minute'";

  factory MatchEvent.fromJson(Map<String, dynamic> json) => MatchEvent(
        minute: json['minute'] as int,
        extraMinute: json['extraMinute'] as int?,
        type: json['type'] as String,
        detail: json['detail'] as String,
        teamId: json['teamId'] as int,
        team: json['team'] as String,
        player: json['player'] as String,
        assist: json['assist'] as String?,
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

class InjuredPlayer {
  final int id;
  final String name;
  final String reason;

  const InjuredPlayer({required this.id, required this.name, required this.reason});

  factory InjuredPlayer.fromJson(Map<String, dynamic> json) => InjuredPlayer(
        id: json['id'] as int,
        name: json['name'] as String,
        reason: json['reason'] as String,
      );
}

class RealTeamLineup {
  final int teamId;
  final String team;
  final String formation;
  final String coach;
  final int? coachId;
  final List<List<RealLineupPlayer>> rows;
  final List<RealLineupPlayer> substitutes;
  final List<InjuredPlayer> injuries;

  const RealTeamLineup({
    required this.teamId,
    required this.team,
    required this.formation,
    required this.coach,
    required this.coachId,
    required this.rows,
    this.substitutes = const [],
    this.injuries = const [],
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
        substitutes: (json['substitutes'] as List? ?? [])
            .map((p) => RealLineupPlayer.fromJson(p as Map<String, dynamic>))
            .toList(),
        injuries: (json['injuries'] as List? ?? [])
            .map((p) => InjuredPlayer.fromJson(p as Map<String, dynamic>))
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

