// ids reales de API-Football, para poder mostrar el logo oficial
// (media.api-sports.io) desde antes de que carguen los picks.
const kLeagueIds = {
  'Liga MX': 262,
  'Premier League': 39,
  'La Liga': 140,
  'Champions League': 2,
  'MLS': 253,
  'Leagues Cup': 772,
};

final kLeagues = kLeagueIds.keys.toList();

String? leagueLogoUrl(String league) {
  final id = kLeagueIds[league];
  return id == null ? null : 'https://media.api-sports.io/football/leagues/$id.png';
}
