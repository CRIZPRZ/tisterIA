import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/leagues.dart';
import '../services/league_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/league_badge_card.dart';

/// Torneos de selecciones que se agrupan visualmente durante fechas FIFA.
/// La selección real sigue siendo la tarjeta individual y su [leagueId].
bool _isInternationalLeague(LeagueInfo league) {
  final name = league.name.toLowerCase();
  const internationalTerms = [
    'friendlies',
    'international friendl',
    'friendly international',
    'world cup',
    'world cup - qualification',
    'nations league',
    'copa america',
    'euro championship',
    'euro u',
    'gold cup',
    'africa cup',
    'afcon',
    'asian cup',
    'olympic',
    'confederations cup',
  ];
  return internationalTerms.any(name.contains);
}

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<LeagueInfo>? _leagues;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final leagues = await LeagueService.instance.fetchActiveLeagues();
      if (mounted) setState(() => _leagues = leagues);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Text(
            'Ligas',
            style: AppText.style(19, weight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toca una o varias ligas para ver sus picks en Home. Toca la estrella para elegir equipos favoritos.',
                  style: AppText.style(
                    12.5,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _error
                      ? Center(
                          child: TextButton(
                            onPressed: _load,
                            child: Text(
                              'No se pudo cargar — toca para reintentar',
                              style: AppText.style(
                                12.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : _leagues == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
                          ),
                        )
                      : SingleChildScrollView(
                          child: Builder(
                            builder: (context) {
                              // El catálogo seleccionable no depende de los
                              // picks del día. El backend suma ligas nuevas
                              // gestionadas desde admin; el catálogo local
                              // conserva las ligas principales entre fechas.
                              final byId = <int, LeagueInfo>{
                                for (final entry in kLeagueIds.entries)
                                  entry.value: LeagueInfo(
                                    leagueId: entry.value,
                                    name: entry.key,
                                  ),
                                for (final league in _leagues!)
                                  league.leagueId: league,
                              };
                              final catalog = byId.values.toList()
                                ..sort((a, b) => a.name.compareTo(b.name));
                              final international = catalog
                                  .where(_isInternationalLeague)
                                  .toList();
                              final domestic = catalog
                                  .where(
                                    (league) => !_isInternationalLeague(league),
                                  )
                                  .toList();

                              List<Widget> leagueCards(
                                List<LeagueInfo> leagues,
                              ) => leagues.map((league) {
                                final active = state.homeLeagueFilter.contains(
                                  league.leagueId,
                                );
                                return LeagueBadgeCard(
                                  league: league.name,
                                  logoUrl: league.logoUrl,
                                  active: active,
                                  onTap: () => context
                                      .read<AppState>()
                                      .setHomeLeagueFilter(league.leagueId),
                                  onPickTeam: () =>
                                      context.read<AppState>().openTeamPicker(
                                        league.leagueId,
                                        league.name,
                                      ),
                                );
                              }).toList();

                              Widget section(
                                String title,
                                List<LeagueInfo> leagues,
                              ) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppText.style(
                                      15,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 30,
                                    children: leagueCards(leagues),
                                  ),
                                ],
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (international.isNotEmpty) ...[
                                    section('Internacional', international),
                                    if (domestic.isNotEmpty)
                                      const SizedBox(height: 34),
                                  ],
                                  if (domestic.isNotEmpty)
                                    section(
                                      international.isEmpty
                                          ? 'Ligas'
                                          : 'Ligas nacionales y de clubes',
                                      domestic,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
