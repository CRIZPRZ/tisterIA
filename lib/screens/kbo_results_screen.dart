import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/baseball_game.dart';
import '../services/baseball_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

// Fase 1 de KBO: solo partidos ya jugados, con marcador real — sin
// predicción todavía (API-Baseball en plan free no da la temporada en
// curso, ver app/services/baseball_sync.py del backend).

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
  bool _error = false;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.profile),
          title: 'KBO — Resultados',
        ),
        Expanded(
          child: _error
              ? NetworkErrorView(onRetry: _load)
              : _games == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _games!.isEmpty
                      ? const EmptyState(
                          icon: Icons.sports_baseball_rounded,
                          title: 'Sin resultados todavía',
                          message: 'Cuando se sincronicen partidos de KBO, aparecerán aquí.',
                        )
                      : RefreshIndicator(
                          color: AppColors.green,
                          backgroundColor: AppColors.card,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                            children: [
                              Text(
                                'Solo partidos ya jugados, sin pronóstico todavía — es una prueba para ver si vale la pena construir el modelo de KBO.',
                                style: AppText.style(12, color: AppColors.textMuted, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              ..._games!.map(_gameCard),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _gameCard(BaseballGame g) {
    final homeWon = (g.homeScore ?? 0) > (g.awayScore ?? 0);
    final awayWon = (g.awayScore ?? 0) > (g.homeScore ?? 0);
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
                Pill(label: 'FINAL', color: AppColors.textMuted, background: AppColors.greyTint),
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
                Text('${g.homeScore ?? '-'} - ${g.awayScore ?? '-'}',
                    style: AppText.style(24, weight: FontWeight.w800)),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
