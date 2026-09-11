class PlayerPropPick {
  final int playerId;
  final String playerName;
  final int teamId;
  final double line;
  final double probOver;
  final int sampleMatches;
  final String pick;

  const PlayerPropPick({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    required this.line,
    required this.probOver,
    required this.sampleMatches,
    required this.pick,
  });

  /// probOver ya es la probabilidad del lado ganador cuando el pick es
  /// "Menos de" (invertida) — para mostrar siempre la % del pick elegido.
  int get displayPct {
    final isOver = pick.startsWith('Más de');
    final p = isOver ? probOver : (1 - probOver);
    return (p * 100).round();
  }

  factory PlayerPropPick.fromJson(Map<String, dynamic> json) => PlayerPropPick(
        playerId: json['playerId'] as int,
        playerName: json['playerName'] as String,
        teamId: json['teamId'] as int,
        line: (json['line'] as num).toDouble(),
        probOver: (json['probOver'] as num).toDouble(),
        sampleMatches: json['sampleMatches'] as int,
        pick: json['pick'] as String,
      );
}
