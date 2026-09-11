import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pick.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pick_card.dart' show confColor, confLabel;
import '../widgets/state_views.dart';

String _confShort(Confidence c) {
  switch (c) {
    case Confidence.alta:
      return 'Alta';
    case Confidence.media:
      return 'Media';
    case Confidence.baja:
      return 'Baja';
  }
}

class _MarketStat {
  final String market;
  final int hits;
  final int total;
  const _MarketStat(this.market, this.hits, this.total);
  int get pct => total == 0 ? 0 : ((hits * 100) / total).round();
}

List<_MarketStat> _marketStatsFrom(List<HistoryEntry> picks) {
  final byMarket = <String, List<bool>>{};
  for (final h in picks) {
    byMarket.putIfAbsent(h.market, () => []).add(h.hit);
  }
  final stats = byMarket.entries
      .map((e) => _MarketStat(e.key, e.value.where((x) => x).length, e.value.length))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return stats;
}

class _MarketAccuracyChart extends StatelessWidget {
  final List<_MarketStat> stats;
  const _MarketAccuracyChart({required this.stats});

  Color _barColor(int pct) {
    if (pct >= 60) return AppColors.green;
    if (pct >= 45) return const Color(0xFFE0A72E);
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stats.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s.market, style: AppText.style(12.5, weight: FontWeight.w600)),
                    ),
                    Text('${s.hits}/${s.total}', style: AppText.style(11, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Text('${s.pct}%', style: AppText.style(13, weight: FontWeight.w700, color: _barColor(s.pct))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(height: 8, width: constraints.maxWidth, color: const Color(0xFF262A34)),
                        Container(
                          height: 8,
                          width: constraints.maxWidth * (s.pct / 100).clamp(0, 1),
                          color: _barColor(s.pct),
                        ),
                      ],
                    ),
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

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final String Function(String) display;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E323C)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: const Color(0xFF1A1D24),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 18),
          style: AppText.style(12.5, color: Colors.white, weight: FontWeight.w600),
          hint: Text(label, style: AppText.style(12.5, color: AppColors.textMuted)),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('Todas · $label', style: AppText.style(12.5, color: AppColors.textMuted))),
            ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(display(o), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AccuracyHistoryScreen extends StatefulWidget {
  const AccuracyHistoryScreen({super.key});

  @override
  State<AccuracyHistoryScreen> createState() => _AccuracyHistoryScreenState();
}

class _AccuracyHistoryScreenState extends State<AccuracyHistoryScreen> {
  String? _league; // null = todas
  String? _date; // null = todas, YYYY-MM-DD

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.accuracy == null) state.loadAccuracy();
    });
  }

  void _refetch() {
    context.read<AppState>().loadAccuracy(league: _league, date: _date);
  }

  String _fmtDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.accuracy;
    final filterActive = _league != null || _date != null;

    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.profile),
          title: 'Historial y precisión',
        ),
        Expanded(
          child: state.accuracyError
              ? NetworkErrorView(onRetry: _refetch)
              : summary == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : (summary.overallTotal == 0 && !filterActive)
                      ? const EmptyState(
                          icon: Icons.query_stats_rounded,
                          title: 'Todavía sin picks calificados',
                          message: 'En cuanto terminen los partidos con picks emitidos, aparecerán aquí con su resultado real.',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                          children: [
                            Text(
                              'Cada pick que emitimos queda registrado aquí, con su resultado real. Sin editar, sin esconder los fallos.',
                              style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _FilterDropdown(
                                    label: 'Liga',
                                    value: _league,
                                    options: summary.availableLeagues,
                                    display: (v) => v,
                                    onChanged: (v) {
                                      setState(() => _league = v);
                                      _refetch();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _FilterDropdown(
                                    label: 'Día',
                                    value: _date,
                                    options: summary.availableDates,
                                    display: _fmtDate,
                                    onChanged: (v) {
                                      setState(() => _date = v);
                                      _refetch();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (state.accuracyLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                              )
                            else ...[
                              AppCard(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  children: [
                                    Text('${summary.overallPct}%', style: AppText.style(38, weight: FontWeight.w300)),
                                    const SizedBox(height: 4),
                                    Text(
                                      filterActive
                                          ? '${summary.overallHits} de ${summary.overallTotal} picks acertados (filtro)'
                                          : '${summary.overallHits} de ${summary.overallTotal} picks acertados',
                                      style: AppText.style(12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text('PRECISIÓN POR NIVEL DE CONFIANZA',
                                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                              const SizedBox(height: 10),
                              ...summary.breakdown.where((b) => b.total > 0).map((b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: AppCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Pill(
                                            label: confLabel(b.confidence),
                                            color: confColor(b.confidence),
                                            background: confColor(b.confidence).withValues(alpha: 0.14),
                                          ),
                                          const Spacer(),
                                          Text('${b.hits}/${b.total}', style: AppText.style(12, color: AppColors.textMuted)),
                                          const SizedBox(width: 10),
                                          Text('${b.pct}%',
                                              style: AppText.style(15, weight: FontWeight.w700, color: confColor(b.confidence))),
                                        ],
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 20),
                              Text('PRECISIÓN POR MERCADO',
                                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                              const SizedBox(height: 10),
                              _MarketAccuracyChart(stats: _marketStatsFrom(summary.picks)),
                              const SizedBox(height: 20),
                              Text(filterActive ? 'PICKS FILTRADOS' : 'TODOS LOS PICKS CALIFICADOS',
                                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                              const SizedBox(height: 10),
                              if (summary.picks.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Text('Sin picks para este filtro.',
                                      style: AppText.style(12.5, color: AppColors.textMuted)),
                                ),
                              ...summary.picks.map((h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AppCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${h.teamA} vs ${h.teamB}', style: AppText.style(12.5, weight: FontWeight.w600)),
                                                const SizedBox(height: 2),
                                                Text(h.pick, style: AppText.style(11, color: AppColors.textBody)),
                                                const SizedBox(height: 2),
                                                Text('${h.league} · ${h.date} · ${_confShort(h.confidence)} confianza',
                                                    style: AppText.style(10, color: AppColors.textMuted)),
                                              ],
                                            ),
                                          ),
                                          Pill(
                                            label: h.hit ? 'ACIERTO' : 'FALLO',
                                            color: h.hit ? AppColors.green : AppColors.red,
                                            background: h.hit ? AppColors.greenTint : AppColors.redTint,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                          ],
                        ),
        ),
      ],
    );
  }
}
