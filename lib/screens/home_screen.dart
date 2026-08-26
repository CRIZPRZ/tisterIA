import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/pick.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pick_card.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

const _kDayTitles = {0: 'Picks de hoy', 1: 'Picks de mañana', 2: 'Picks de pasado mañana'};

class _DayTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _DayTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [0, 1, 2].map((d) {
            final active = selected == d;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.textWhite : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    const ['Hoy', 'Mañana', 'Pasado mañana'][d],
                    style: AppText.style(12.5, weight: FontWeight.w700, color: active ? const Color(0xFF0B0F0C) : AppColors.textMuted),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _hasError = kSimulateNetworkError;
  final Set<String> _collapsedLeagues = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    final ok = kSimulateNetworkError ? false : await context.read<AppState>().loadPicks();
    if (mounted) {
      setState(() {
        _loading = false;
        _hasError = !ok;
      });
    }
  }

  Future<void> _onRefresh() async {
    final ok = await context.read<AppState>().loadPicks();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar. Intenta de nuevo.'), backgroundColor: AppColors.card),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final picks = state.homeLeagueFilter == null
        ? state.filteredPicks
        : state.filteredPicks.where((p) => p.league == state.homeLeagueFilter).toList();
    final leagueIds = <String, int?>{for (final p in state.allPicks) p.league: p.leagueId};
    final leagues = state.favoriteLeagueIds.isEmpty
        ? leagueIds.keys.toList()
        : leagueIds.keys.where((l) => state.favoriteLeagueIds.contains(leagueIds[l])).toList();
    final featured = picks.isEmpty ? null : picks.reduce((a, b) => a.prob >= b.prob ? a : b);

    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.card,
      onRefresh: _onRefresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _TopHeader(featured: featured, featuredLocked: featured != null && state.isLocked(featured)),
          const SizedBox(height: 18),
          _PromoTiles(onOpenAccuracy: () => context.read<AppState>().go(AppScreen.accuracyHistory)),
          if (leagues.isNotEmpty) ...[
            const SizedBox(height: 22),
            _LeagueChips(
              leagues: leagues,
              leagueIds: leagueIds,
              selected: state.homeLeagueFilter,
              onSelect: (league) => context.read<AppState>().setHomeLeagueFilter(
                    state.homeLeagueFilter == league ? null : league,
                  ),
            ),
          ],
          const SizedBox(height: 22),
          _DayTabs(selected: state.dayOffset, onSelect: (d) => context.read<AppState>().setDayOffset(d)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 7, height: 7, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                    Text(_kDayTitles[state.dayOffset]!, style: AppText.style(15, weight: FontWeight.w800)),
                  ],
                ),
                if (!_loading && !_hasError)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                    child: Text('${picks.length} partidos', style: AppText.style(11, weight: FontWeight.w700, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: kSportTabs.entries.map((e) {
                final active = state.filter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => context.read<AppState>().setFilter(e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.green : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.green : AppColors.cardBorder),
                      ),
                      child: Text(
                        e.value,
                        style: AppText.style(12.5, weight: FontWeight.w700, color: active ? const Color(0xFF0B0F0C) : AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          _buildBody(state, picks),
        ],
      ),
    );
  }

  Widget _buildBody(AppState state, List<Pick> picks) {
    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 100),
        child: NetworkErrorView(onRetry: _load),
      );
    }

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
        child: Column(
          children: List.generate(4, (i) => const Padding(padding: EdgeInsets.only(bottom: 12), child: PickCardSkeleton())),
        ),
      );
    }

    if (picks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60, bottom: 100),
        child: EmptyState(
          icon: Icons.sports_soccer_rounded,
          title: 'Sin picks en esta categoría',
          message: 'Por ahora no tenemos picks para este deporte. Prueba con otra pestaña o vuelve más tarde.',
        ),
      );
    }

    // Agrupa por liga preservando el orden en que aparecen (así los
    // favoritos, ya ordenados primero en filteredPicks, encabezan el feed).
    final grouped = <String, List<Pick>>{};
    for (final p in picks) {
      grouped.putIfAbsent(p.league, () => []).add(p);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          final collapsed = _collapsedLeagues.contains(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    if (collapsed) {
                      _collapsedLeagues.remove(entry.key);
                    } else {
                      _collapsedLeagues.add(entry.key);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: AppText.style(12, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5),
                        ),
                        AnimatedRotation(
                          turns: collapsed ? -0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: collapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.value
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PickCard(
                                pick: p,
                                locked: state.isLocked(p),
                                onOpen: () => context.read<AppState>().openDetail(p.id),
                                onUnlock: () => context.read<AppState>().go(AppScreen.paywall),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final Pick? featured;
  final bool featuredLocked;
  const _TopHeader({required this.featured, required this.featuredLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: AppColors.screenBg,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TipsterIA', style: AppText.style(19, weight: FontWeight.w800, color: Colors.white)),
              GestureDetector(
                onTap: () => context.read<AppState>().go(AppScreen.profile),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline_rounded, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          if (featured != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.read<AppState>().openDetail(featured!.id),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.55), width: 1.4),
                  boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.18), blurRadius: 24, spreadRadius: -2)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Match of the Day', style: AppText.style(14, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              TeamCrest(name: featured!.teamA, size: 34, logoUrl: featured!.teamALogoUrl),
                              const SizedBox(width: 8),
                              Text('vs', style: AppText.style(11.5, weight: FontWeight.w700, color: AppColors.textFaint)),
                              const SizedBox(width: 8),
                              TeamCrest(name: featured!.teamB, size: 34, logoUrl: featured!.teamBLogoUrl),
                            ],
                          ),
                        ),
                        ProbRing(pct: featured!.prob, size: 62, strokeWidth: 5, fontSize: 15, label: 'CONFIANZA'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${featured!.teamA} vs ${featured!.teamB} · ${featured!.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(11.5, weight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      featuredLocked ? 'Toca para ver el pick' : 'Tip: ${featured!.pick}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(12.5, weight: FontWeight.w700, color: AppColors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PromoTiles extends StatelessWidget {
  final VoidCallback onOpenAccuracy;
  const _PromoTiles({required this.onOpenAccuracy});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          Container(
            width: 210,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAT IA', style: AppText.style(9.5, weight: FontWeight.w800, color: AppColors.green, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text('Pregunta lo que quieras de cualquier partido', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.style(12.5, weight: FontWeight.w700, height: 1.25)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onOpenAccuracy,
            child: Container(
              width: 210,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRECISIÓN', style: AppText.style(9.5, weight: FontWeight.w800, color: AppColors.green, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Revisa el historial real de aciertos del modelo', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.style(12.5, weight: FontWeight.w700, height: 1.25)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueChips extends StatelessWidget {
  final List<String> leagues;
  final Map<String, int?> leagueIds;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _LeagueChips({required this.leagues, required this.leagueIds, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 10),
          child: Text('LIGAS', style: AppText.style(11.5, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
        ),
        SizedBox(
          height: 88,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: leagues.map((league) {
              final active = selected == league;
              return GestureDetector(
                onTap: () => onSelect(league),
                child: Container(
                  width: 76,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppColors.green : AppColors.cardBorder, width: active ? 1.4 : 1),
                    boxShadow: active ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: -1)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TeamCrest(
                        name: league,
                        size: 40,
                        logoUrl: leagueIds[league] == null ? null : 'https://media.api-sports.io/football/leagues/${leagueIds[league]}.png',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        league,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppText.style(10, weight: FontWeight.w600, color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
