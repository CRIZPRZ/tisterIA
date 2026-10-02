// ids reales de API-Football, para poder mostrar el logo oficial
// (media.api-sports.io) desde antes de que carguen los picks.
const kLeagueIds = {
  'Liga MX': 262,
  'Premier League': 39,
  'La Liga': 140,
  'Champions League': 2,
  'Europa League': 3,
  'Conference League': 848,
  'Ligue 1': 61,
  'Serie A': 135,
  'Bundesliga': 78,
  'Eredivisie': 88,
  'Primeira Liga': 94,
  'Championship': 40,
  'Brasileirão Serie A': 71,
  'Liga Profesional Argentina': 128,
  'Liga BetPlay': 239,
  'Primera División Chile': 265,
  'Saudi Pro League': 307,
  'MLS': 253,
  'Leagues Cup': 772,
  'Amistosos Internacionales': 10,
};

final kLeagues = kLeagueIds.keys.toList();

String? leagueLogoUrl(String league) {
  final id = kLeagueIds[league];
  return id == null
      ? null
      : 'https://media.api-sports.io/football/leagues/$id.png';
}
