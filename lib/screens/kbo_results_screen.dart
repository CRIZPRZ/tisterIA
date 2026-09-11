import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/baseball_game.dart';
import '../services/baseball_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

// KBO — resultados ya jugados y partidos programados (scraping de
// koreabaseball.com, ver app/services/kbo_scraper.py del backend).

enum _KboFilter { todos, ayer, hoy, manana }

const _monthAbbr = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _shortDate(String matchDate) {
  final parts = matchDate.split('-');
  if (parts.length != 3) return matchDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return matchDate;
  return '$day ${_monthAbbr[month - 1]}';
}

class KboResultsScreen extends StatefulWidget {
  const KboResultsScreen({super.key});

  @override
  State<KboResultsScreen> createState() => _KboResultsScreenState();
}

class _KboResultsScreenState extends State<KboResultsScreen> {
  List<BaseballGame>? _games;
  Map<int, KboBatchPrediction> _predictions = {};
  bool _error = false;
  _KboFilter _filter = _KboFilter.hoy;

  // Coreano (KST) va 15h adelante de México — comparar contra el reloj
  // del celular directo haría que "HOY"/"MAÑANA" agarraran el día
  // incorrecto según la hora en que se revise. Se calcula la fecha real
  // en KST (UTC+9) sin depender de la zona horaria del dispositivo.
  DateTime get _kstNow => DateTime.now().toUtc().add(const Duration(hours: 9));
  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String get _todayStr => _fmtDate(_kstNow);
  String get _tomorrowStr => _fmtDate(_kstNow.add(const Duration(days: 1)));
  String get _yesterdayStr => _fmtDate(_kstNow.subtract(const Duration(days: 1)));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final games = await BaseballService.instance.fetchResults(leagueId: 5);
      if (mounted) setState(() => _games = games);
    } catch (_) {
      if (mounted) setState(() => _error = true);
      return;
    }
    // Falla silenciosa a propósito: si /predict/batch truena (ej. sin
    // muestra todavía), la lista de resultados igual debe verse.
    try {
      final predictions = await BaseballService.instance.fetchPredictionBatch(leagueId: 5);
      if (mounted) setState(() => _predictions = {for (final p in predictions) p.gameId: p});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    List<BaseballGame>? filtered = _games;
    if (filtered != null) {
      switch (_filter) {
        case _KboFilter.todos:
          break;
        case _KboFilter.ayer:
          filtered = filtered.where((g) => g.matchDate == _yesterdayStr).toList();
        case _KboFilter.hoy:
          filtered = filtered.where((g) => g.matchDate == _todayStr).toList();
        case _KboFilter.manana:
          filtered = filtered.where((g) => g.matchDate == _tomorrowStr).toList();
      }
    }
    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.profile),
          title: 'KBO',
        ),
        if (_games != null && _games!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _KboFilterChip(label: 'TODOS', active: _filter == _KboFilter.todos, onTap: () => setState(() => _filter = _KboFilter.todos)),
                const SizedBox(width: 8),
                _KboFilterChip(label: 'AYER', active: _filter == _KboFilter.ayer, onTap: () => setState(() => _filter = _KboFilter.ayer)),
                const SizedBox(width: 8),
                _KboFilterChip(label: 'HOY', active: _filter == _KboFilter.hoy, onTap: () => setState(() => _filter = _KboFilter.hoy)),
                const SizedBox(width: 8),
                _KboFilterChip(label: 'MAÑANA', active: _filter == _KboFilter.manana, onTap: () => setState(() => _filter = _KboFilter.manana)),
              ],
            ),
          ),
        Expanded(
          child: _error
              ? NetworkErrorView(onRetry: _load)
              : _games == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _games!.isEmpty
                      ? const EmptyState(
                          icon: Icons.sports_baseball_rounded,
                          title: 'Sin partidos todavía',
                          message: 'Cuando se sincronicen partidos de KBO, aparecerán aquí.',
                        )
                      : filtered!.isEmpty
                          ? EmptyState(
                              icon: Icons.sports_baseball_rounded,
                              title: switch (_filter) {
                                _KboFilter.manana => 'Sin partidos mañana',
                                _KboFilter.ayer => 'Sin partidos ayer',
                                _ => 'Sin partidos hoy',
                              },
                              message: 'Todavía no hay partidos de KBO para ese día.',
                            )
                          : RefreshIndicator(
                              color: AppColors.green,
                              backgroundColor: AppColors.card,
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                                children: [
                                  ...filtered.map(_gameCard),
                                ],
                              ),
                            ),
        ),
      ],
    );
  }

  Widget _gameCard(BaseballGame g) {
    final isFinished = g.status == 'FT';
    final homeWon = isFinished && (g.homeScore ?? 0) > (g.awayScore ?? 0);
    final awayWon = isFinished && (g.awayScore ?? 0) > (g.homeScore ?? 0);
    final prediction = _predictions[g.gameId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.read<AppState>().openKboDetail(g),
        child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${_shortDate(g.matchDate)} · ${g.time}', style: AppText.style(11, color: AppColors.textFaint)),
                const Spacer(),
                isFinished
                    ? Pill(label: 'FINAL', color: AppColors.textMuted, background: AppColors.greyTint)
                    : Pill(label: 'PROGRAMADO', color: AppColors.yellow, background: AppColors.yellow.withValues(alpha: 0.16)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TeamCrest(name: g.teamA, size: 30, logoUrl: g.teamALogoUrl),
                          const SizedBox(width: 8),
                          Text('VS', style: AppText.style(11.5, weight: FontWeight.w800, color: AppColors.textFaint, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          TeamCrest(name: g.teamB, size: 30, logoUrl: g.teamBLogoUrl),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(g.teamA,
                          style: AppText.style(12.5, weight: homeWon ? FontWeight.w800 : FontWeight.w500, color: homeWon ? Colors.white : AppColors.textMuted)),
                      Text(g.teamB,
                          style: AppText.style(12.5, weight: awayWon ? FontWeight.w800 : FontWeight.w500, color: awayWon ? Colors.white : AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(isFinished ? '${g.homeScore} - ${g.awayScore}' : 'VS',
                    style: AppText.style(24, weight: FontWeight.w800)),
              ],
            ),
            if (prediction != null) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.greyTint),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.insights_rounded, size: 14, color: AppColors.textFaint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${prediction.favorite} · ${(prediction.probFavorite * 100).round()}%',
                      style: AppText.style(12, weight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                  if (prediction.hit != null)
                    Pill(
                      label: prediction.hit! ? 'ACIERTO' : 'FALLO',
                      color: prediction.hit! ? AppColors.green : AppColors.red,
                      background: (prediction.hit! ? AppColors.green : AppColors.red).withValues(alpha: 0.16),
                    ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _KboFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _KboFilterChip({required this.label, required this.active, required this.onTap});

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
        child: Text(
          label,
          style: AppText.style(12, weight: FontWeight.w800, color: active ? AppColors.green : Colors.white, letterSpacing: 0.3),
        ),
      ),
    );
  }
}
