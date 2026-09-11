import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pick.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/live_minute_text.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

const _monthAbbr = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _shortDate(String? matchDate) {
  if (matchDate == null) return '';
  final parts = matchDate.split('-');
  if (parts.length != 3) return matchDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return matchDate;
  return '$day ${_monthAbbr[month - 1]}';
}

String _dateLabel(String? matchDate) {
  if (matchDate == null) return 'Sin fecha';
  final today = DateTime.now();
  final parts = matchDate.split('-');
  if (parts.length != 3) return matchDate;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return matchDate;
  final date = DateTime(y, m, d);
  final diff = date.difference(DateTime(today.year, today.month, today.day)).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  return _shortDate(matchDate);
}

// Finalizado (no en vivo, con marcador) va abajo; lo demás (por jugarse o
// en curso) va arriba, ordenado por fecha+hora real de kickoff. También
// cuenta como pasado si el kickoff ya pasó hace rato aunque nunca se haya
// cacheado el marcador (huecos del tracking en vivo) — si no, ese partido
// se queda pegado arriba en "próximos" para siempre.
bool _isPastPick(Pick p) {
  if (p.liveScore != null && !p.isLive) return true;
  if (p.isLive) return false;
  final kickoff = _kickoff(p);
  if (kickoff == null) return false;
  return DateTime.now().difference(kickoff) > const Duration(hours: 3);
}

DateTime? _kickoff(Pick p) {
  final md = p.matchDate;
  if (md == null) return null;
  final dateParts = md.split('-');
  final timeParts = p.time.split(':');
  if (dateParts.length != 3 || timeParts.length != 2) return null;
  final y = int.tryParse(dateParts[0]);
  final m = int.tryParse(dateParts[1]);
  final d = int.tryParse(dateParts[2]);
  final h = int.tryParse(timeParts[0]);
  final min = int.tryParse(timeParts[1]);
  if (y == null || m == null || d == null || h == null || min == null) return null;
  return DateTime(y, m, d, h, min);
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DateFilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0x262ECC71) : const Color(0xFF262A34),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.green.withValues(alpha: 0.8) : const Color(0xFF4A505A),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today_rounded, size: 14, color: active ? AppColors.green : Colors.white),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppText.style(12, weight: FontWeight.w800, color: active ? AppColors.green : Colors.white, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveFilterChip extends StatelessWidget {
  final bool active;
  final int count;
  final VoidCallback onTap;

  const _LiveFilterChip({required this.active, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0x26FF5C5C) : const Color(0xFF262A34),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.red.withValues(alpha: 0.8) : const Color(0xFF4A505A),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.only(right: 8), child: PulseDot()),
            Text(
              'EN VIVO · $count',
              style: AppText.style(12, weight: FontWeight.w800, color: active ? AppColors.red : Colors.white, letterSpacing: 0.3),
            ),
          ],
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
  bool _pastExpanded = false;
  final Set<String> _expandedDates = {};
  late final PageController _heroController;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroController = PageController(viewportFraction: 1);
    // Con la navegación por enum, Home se reconstruye desde cero cada vez
    // que vuelves de otra pantalla — si ya había picks en AppState (de
    // segundos antes), se muestran de inmediato y se refresca en silencio,
    // en vez de bloquear con el spinner otra vez por una recarga completa.
    if (context.read<AppState>().allPicks.isEmpty) {
      _load();
    } else {
      _loading = false;
      _refreshQuietly();
    }
  }

  Future<void> _refreshQuietly() async {
    await context.read<AppState>().loadPicks();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    final ok = kSimulateNetworkError
        ? false
        : await context.read<AppState>().loadPicks();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasError = !ok;
    });
  }

  Future<void> _onRefresh() async {
    final ok = await context.read<AppState>().loadPicks();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar. Intenta de nuevo.'),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  void _openPick(Pick pick, AppState state) {
    if (state.isLocked(pick)) {
      state.go(AppScreen.paywall);
      return;
    }
    state.openDetail(pick.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var allPicksForDay = state.homeLeagueFilter == null
        ? state.filteredPicks
        : state.filteredPicks
              .where((p) => p.league == state.homeLeagueFilter)
              .toList();
    if (state.showLiveOnly) {
      allPicksForDay = allPicksForDay.where((p) => p.isLive).toList();
    }
    // Fechas disponibles para los chips — de los partidos que aún faltan
    // por jugarse (o en vivo), antes de aplicar el filtro de fecha mismo.
    final availableDates = (allPicksForDay.where((p) => !_isPastPick(p)).map((p) => p.matchDate).whereType<String>().toSet().toList()..sort());
    if (state.homeDateFilter != null) {
      allPicksForDay = allPicksForDay.where((p) => p.matchDate == state.homeDateFilter).toList();
    }
    final liveCount = state.filteredPicks.where((p) => p.isLive).map((p) => p.fixtureId).toSet().length;
    // Un partido real genera varios picks (1X2, doble oportunidad, etc.) —
    // en Home se muestra 1 fila por partido (el mercado 1X2/free), el resto
    // de mercados solo se ven al abrir el detalle → pestaña Mercados.
    final Map<int, Pick> byFixture = {};
    for (final p in allPicksForDay) {
      final fixtureId = p.fixtureId;
      if (fixtureId == null) continue;
      final existing = byFixture[fixtureId];
      if (existing == null || (!p.premium && existing.premium)) {
        byFixture[fixtureId] = p;
      }
    }
    final picks = byFixture.values.toList();
    // "Partido del día" es el más interesante por venir/en vivo (nunca uno
    // ya jugado hace días) y siempre un mercado premium — es el gancho
    // hacia Premium, no debe regalar el pick completo.
    final Map<int, Pick> premiumByFixture = {};
    for (final p in allPicksForDay) {
      if (!p.premium || _isPastPick(p)) continue;
      final fixtureId = p.fixtureId;
      if (fixtureId == null) continue;
      final existing = premiumByFixture[fixtureId];
      if (existing == null || p.prob > existing.prob) premiumByFixture[fixtureId] = p;
    }
    final featuredPicks = premiumByFixture.values.toList()..sort((a, b) => b.prob.compareTo(a.prob));
    final heroCandidates = [
      ...featuredPicks.where(
        (p) => p.teamALogoUrl != null && p.teamBLogoUrl != null,
      ),
      ...featuredPicks.where(
        (p) => p.teamALogoUrl != null || p.teamBLogoUrl != null,
      ),
      ...featuredPicks.where(
        (p) => p.teamALogoUrl == null && p.teamBLogoUrl == null,
      ),
    ];
    final heroPicks = <Pick>[];
    for (final pick in heroCandidates) {
      if (heroPicks.any((p) => p.id == pick.id)) continue;
      heroPicks.add(pick);
      if (heroPicks.length == 3) break;
    }
    final leagueIds = <String, int?>{
      for (final p in state.allPicks) p.league: p.leagueId,
    };
    final leagues = state.favoriteLeagueIds.isEmpty
        ? leagueIds.keys.toList()
        : leagueIds.keys
              .where((l) => state.favoriteLeagueIds.contains(leagueIds[l]))
              .toList();
    final upcomingPicks = picks.where((p) => !_isPastPick(p)).toList()
      ..sort((a, b) => (_kickoff(a) ?? DateTime(9999)).compareTo(_kickoff(b) ?? DateTime(9999)));
    final pastPicks = picks.where(_isPastPick).toList()
      ..sort((a, b) => (_kickoff(b) ?? DateTime(0)).compareTo(_kickoff(a) ?? DateTime(0)));

    return Stack(
      children: [
        const Positioned.fill(child: _HomeBackground()),
        RefreshIndicator(
          color: AppColors.green,
          backgroundColor: AppColors.card,
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 22),
            children: [
              const _BrandHeader(),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 228,
                  child: PageView.builder(
                    controller: _heroController,
                    clipBehavior: Clip.none,
                    itemCount: heroPicks.isEmpty ? 1 : heroPicks.length,
                    onPageChanged: (index) {
                      if (_heroIndex == index) return;
                      setState(() => _heroIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final featured = heroPicks.isEmpty
                          ? null
                          : heroPicks[index];
                      return _HeroCard(
                        featured: featured,
                        locked: featured != null && state.isLocked(featured),
                        onTap: featured == null
                            ? null
                            : () => _openPick(featured, state),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _HeroDots(
                count: heroPicks.isEmpty ? 1 : heroPicks.length,
                activeIndex: _heroIndex.clamp(
                  0,
                  heroPicks.isEmpty ? 0 : heroPicks.length - 1,
                ),
                onTap: (index) {
                  _heroController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (liveCount > 0) ...[
                      _LiveFilterChip(
                        active: state.showLiveOnly,
                        count: liveCount,
                        onTap: () => context.read<AppState>().toggleLiveOnly(),
                      ),
                      const SizedBox(width: 10),
                    ],
                    for (final d in availableDates) ...[
                      _DateFilterChip(
                        label: _dateLabel(d),
                        active: state.homeDateFilter == d,
                        onTap: () => context.read<AppState>().setHomeDateFilter(d),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              if (leagues.isNotEmpty) ...[
                const SizedBox(height: 16),
                _LeagueScroller(
                  leagues: leagues,
                  leagueIds: leagueIds,
                  selected: state.homeLeagueFilter,
                  onSelect: (league) {
                    context.read<AppState>().setHomeLeagueFilter(
                      state.homeLeagueFilter == league ? null : league,
                    );
                  },
                ),
              ],
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Picks destacados',
                  style: AppText.style(16, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              _buildBody(state, upcomingPicks, pastPicks),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AppState state, List<Pick> upcomingPicks, List<Pick> pastPicks) {
    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 100),
        child: NetworkErrorView(onRetry: _load),
      );
    }

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: PickCardSkeleton(),
            ),
          ),
        ),
      );
    }

    if (upcomingPicks.isEmpty && pastPicks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50, bottom: 100),
        child: EmptyState(
          icon: Icons.sports_soccer_rounded,
          title: 'Sin picks en esta categoría',
          message:
              'Por ahora no tenemos picks para este deporte. Prueba con otra pestaña o vuelve más tarde.',
        ),
      );
    }

    Widget cardFor(Pick pick) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _TopPickCard(
            pick: pick,
            locked: state.isLocked(pick) || state.isPickQuotaLocked(pick),
            onTap: () => _openPick(pick, state),
          ),
        );

    // Agrupa por fecha manteniendo el orden ya cronológico de upcomingPicks
    // — "Hoy" siempre abierto (es lo que se quiere ver de entrada), el
    // resto colapsado igual que "Partidos pasados", para no aventar de
    // golpe todos los partidos futuros que tengamos.
    final byDate = <String, List<Pick>>{};
    for (final p in upcomingPicks) {
      (byDate[p.matchDate ?? ''] ??= []).add(p);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          for (final entry in byDate.entries) ...[
            Builder(builder: (context) {
              final label = _dateLabel(entry.key);
              final isToday = label == 'Hoy';
              final expanded = isToday || _expandedDates.contains(entry.key);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isToday
                        ? null
                        : () => setState(() {
                              if (_expandedDates.contains(entry.key)) {
                                _expandedDates.remove(entry.key);
                              } else {
                                _expandedDates.add(entry.key);
                              }
                            }),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '$label · ${entry.value.length}',
                            style: AppText.style(13, weight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          if (!isToday)
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: expanded
                        ? Column(children: entry.value.map(cardFor).toList())
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              );
            }),
          ],
          if (pastPicks.isNotEmpty) ...[
            GestureDetector(
              onTap: () => setState(() => _pastExpanded = !_pastExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Partidos pasados · ${pastPicks.length}',
                      style: AppText.style(13, weight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _pastExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _pastExpanded
                  ? Column(children: pastPicks.map(cardFor).toList())
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1512), Color(0xFF090D0B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 230,
              height: 230,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x331EF0A2), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 130,
            left: -120,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 220,
                height: 360,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(160),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x121EF0A2), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -110,
            bottom: 60,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 250,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(180),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x101EF0A2), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppText.style(
            23,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
          children: const [
            TextSpan(text: 'Tipster'),
            TextSpan(
              text: 'IA',
              style: TextStyle(color: AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Pick? featured;
  final bool locked;
  final VoidCallback? onTap;

  const _HeroCard({
    required this.featured,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final ringSize = compact ? 120.0 : 136.0;
        final crestSize = compact ? 62.0 : 72.0;
        final titleSize = compact ? 13.5 : 15.5;
        final vsSize = compact ? 34.0 : 40.0;
        final tipSize = compact ? 14.8 : 16.8;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 20,
              compact ? 16 : 20,
              compact ? 14 : 18,
              compact ? 14 : 18,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.88),
                width: 1.6,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16221B), Color(0xFF09100D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.14),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.08),
                  blurRadius: 42,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.14),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 34,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: compact ? -10 : -2,
                  top: compact ? 58 : 52,
                  child: Container(
                    width: compact ? 120 : 144,
                    height: compact ? 120 : 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                ),
                Positioned(
                  right: compact ? -8 : -4,
                  top: compact ? 18 : 14,
                  child: Container(
                    width: compact ? 120 : 138,
                    height: compact ? 120 : 138,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(compact ? 30 : 36),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.green.withValues(alpha: 0.16),
                          AppColors.green.withValues(alpha: 0.04),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.20),
                          blurRadius: 34,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                if (featured == null)
                  SizedBox(
                    height: 152,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sports_soccer_rounded, size: 28, color: AppColors.textFaint),
                          const SizedBox(height: 10),
                          Text('Sin partidos destacados', style: AppText.style(13.5, weight: FontWeight.w600, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partido destacado',
                        style: AppText.style(
                          titleSize,
                          weight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _CrestBubble(
                                      name: featured!.teamA,
                                      logoUrl: featured!.teamALogoUrl,
                                      size: crestSize,
                                      teamId: featured!.teamAId,
                                      leagueId: featured!.leagueId,
                                    ),
                                    Container(
                                      width: vsSize,
                                      height: vsSize,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: compact ? 8 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2A332F),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        featured!.liveScore != null ? featured!.liveScore!.replaceAll('-', ' - ') : 'VS',
                                        style: AppText.style(
                                          featured!.liveScore != null ? (compact ? 13 : 14.5) : (compact ? 12 : 13.5),
                                          weight: FontWeight.w900,
                                          color: featured!.liveScore != null ? Colors.white : const Color(0xFF95A09A),
                                        ),
                                      ),
                                    ),
                                    _CrestBubble(
                                      name: featured!.teamB,
                                      logoUrl: featured!.teamBLogoUrl,
                                      size: crestSize,
                                      teamId: featured!.teamBId,
                                      leagueId: featured!.leagueId,
                                    ),
                                  ],
                                ),
                                SizedBox(height: compact ? 8 : 10),
                                featured!.isLive
                                    ? LiveMinuteText(
                                        pick: featured!,
                                        style: AppText.style(compact ? 11 : 11.5, weight: FontWeight.w600, color: AppColors.red),
                                      )
                                    : Text(
                                        featured!.liveScore != null
                                            ? 'Finalizado · ${_shortDate(featured!.matchDate)} · ${featured!.liveScore}'
                                            : '${_shortDate(featured!.matchDate)} · ${featured!.time}',
                                        style: AppText.style(
                                          compact ? 11 : 11.5,
                                          weight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                SizedBox(height: compact ? 10 : 12),
                                RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: AppText.style(
                                      tipSize,
                                      weight: FontWeight.w800,
                                      color: AppColors.green,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Tip: '),
                                      TextSpan(
                                        text: locked
                                            ? 'Pick premium bloqueado'
                                            : featured!.pick,
                                        style: AppText.style(
                                          tipSize,
                                          weight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: compact ? 6 : 8),
                          SizedBox(
                            width: ringSize,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ProbRing(
                                pct: featured!.prob,
                                size: ringSize,
                                strokeWidth: compact ? 7 : 8,
                                fontSize: compact ? 24 : 28,
                                label: 'CONFIANZA',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 18 : 20),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _HeroDots({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: index == count - 1 ? 0 : 8),
          child: GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.green : const Color(0xFF59615E),
                borderRadius: BorderRadius.circular(99),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.55),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LeagueScroller extends StatelessWidget {
  final List<String> leagues;
  final Map<String, int?> leagueIds;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _LeagueScroller({
    required this.leagues,
    required this.leagueIds,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: leagues.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final league = leagues[index];
          final active = selected == league;
          return GestureDetector(
            onTap: () => onSelect(league),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 94,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF262A34),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? AppColors.green.withValues(alpha: 0.84)
                      : const Color(0xFF4A505A),
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.18),
                          blurRadius: 10,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: TeamCrest(
                      name: league,
                      size: 34,
                      logoUrl: leagueIds[league] == null
                          ? null
                          : 'https://media.api-sports.io/football/leagues/${leagueIds[league]}.png',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _leaguePrimary(league),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.style(10, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _leagueSecondary(league),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.style(9.5, color: const Color(0xFFBFC3CA)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _leaguePrimary(String league) {
    if (league == 'Premier League') return 'Premier';
    if (league == 'La Liga') return 'LaLiga';
    return league.split(' ').first;
  }

  String _leagueSecondary(String league) {
    if (league == 'Premier League') return 'League';
    if (league == 'La Liga') return 'La Liga';
    final words = league.split(' ');
    return words.length > 1 ? words.skip(1).join(' ') : league;
  }
}

class _TopPickCard extends StatelessWidget {
  final Pick pick;
  final bool locked;
  final VoidCallback onTap;

  const _TopPickCard({
    required this.pick,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeIsPremium = pick.premium;
    final card = _buildCard(context, badgeIsPremium);
    if (!locked) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
    }
    // Cuota diaria agotada — mismo trato visual que un mercado premium
    // bloqueado, para no prometer "FREE" en algo que ya no se puede abrir hoy.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: card),
            Positioned.fill(
              child: Container(
                color: const Color(0x8C111214),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'Ya viste tus gratis de hoy',
                      style: AppText.style(11.5, weight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Ver con Premium',
                        style: AppText.style(11.5, weight: FontWeight.w600, color: const Color(0xFF111111)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool badgeIsPremium) {
    return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF374239), width: 1.2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF343842), Color(0xFF171C19)],
            stops: [0, 0.62],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.07),
              blurRadius: 18,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -50,
              top: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.green.withValues(alpha: 0.16), AppColors.green.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 20,
              child: Container(
                width: 56,
                height: 1.2,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CrestBubble(
                            name: pick.teamA,
                            logoUrl: pick.teamALogoUrl,
                            size: 52,
                            teamId: pick.teamAId,
                            leagueId: pick.leagueId,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              pick.liveScore != null ? pick.liveScore!.replaceAll('-', ' - ') : 'VS.',
                              style: AppText.style(
                                pick.liveScore != null ? 17 : 14,
                                weight: FontWeight.w900,
                                color: pick.liveScore != null ? Colors.white : const Color(0xFFE7EAEE),
                              ),
                            ),
                          ),
                          _CrestBubble(
                            name: pick.teamB,
                            logoUrl: pick.teamBLogoUrl,
                            size: 52,
                            teamId: pick.teamBId,
                            leagueId: pick.leagueId,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (pick.isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x26FF5C5C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(padding: EdgeInsets.only(right: 6), child: PulseDot()),
                              LiveMinuteText(
                                pick: pick,
                                style: AppText.style(10.5, weight: FontWeight.w800, color: AppColors.red, letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        )
                      else if (pick.liveScore != null)
                        Text(
                          'Finalizado · ${_shortDate(pick.matchDate)} · ${pick.liveScore}',
                          style: AppText.style(12.4, weight: FontWeight.w700, color: AppColors.textMuted),
                        )
                      else
                        Text(
                          '${pick.teamA} vs. ${pick.teamB}\n${_shortDate(pick.matchDate)} · ${pick.time}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(
                            12.4,
                            color: const Color(0xFFD7DBE0),
                            weight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!(pick.liveScore != null && !pick.isLive))
                      GestureDetector(
                        onTap: () => context.read<AppState>().toggleFollow(pick),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Icon(
                            context.watch<AppState>().isFollowing(pick) ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                            size: 19,
                            color: context.watch<AppState>().isFollowing(pick) ? AppColors.green : AppColors.textFaint,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeIsPremium
                            ? const Color(0xFFF6D86B)
                            : AppColors.green,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (badgeIsPremium
                                        ? const Color(0xFFF6D86B)
                                        : AppColors.green)
                                    .withValues(alpha: 0.25),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        badgeIsPremium ? 'PREMIUM' : 'FREE',
                        style: AppText.style(
                          10.5,
                          weight: FontWeight.w900,
                          color: badgeIsPremium
                              ? const Color(0xFF493500)
                              : const Color(0xFF0B311F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    pick.hasNoPrediction
                        ? const Icon(Icons.help_outline_rounded, size: 34, color: AppColors.textFaint)
                        : ProbRing(
                            pct: pick.prob,
                            size: 64,
                            strokeWidth: 5,
                            fontSize: 14,
                            color: AppColors.green,
                          ),
                  ],
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _CrestBubble extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final double size;
  final int? teamId;
  final int? leagueId;

  const _CrestBubble({
    required this.name,
    required this.logoUrl,
    required this.size,
    this.teamId,
    this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF26302A),
        border: Border.all(color: const Color(0xFF435049), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: -3,
          ),
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.10),
            blurRadius: 12,
            spreadRadius: -6,
          ),
        ],
      ),
      child: TeamCrest(name: name, logoUrl: logoUrl, size: size * 0.68),
    );
    if (teamId == null) return bubble;
    return GestureDetector(
      onTap: () => context.read<AppState>().openTeamHistory(teamId!, name, leagueId),
      child: bubble,
    );
  }
}
