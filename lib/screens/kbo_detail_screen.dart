import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/baseball_game.dart';
import '../services/baseball_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

// Detalle de un partido de KBO — marcador + predicción (moneyline y total
// de carreras) del modelo en app/services/kbo_predict.py. Solo para uso
// del dueño (pantalla admin-gated), sin lenguaje de apuestas: probabilidad,
// no cuota/momio.

class KboDetailScreen extends StatefulWidget {
  const KboDetailScreen({super.key});

  @override
  State<KboDetailScreen> createState() => _KboDetailScreenState();
}

class _KboDetailScreenState extends State<KboDetailScreen> {
  KboPrediction? _prediction;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final game = context.read<AppState>().kboSelectedGame;
    if (game == null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final prediction = await BaseballService.instance.fetchPrediction(teamA: game.teamA, teamB: game.teamB);
      if (mounted) setState(() => _prediction = prediction);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<AppState>().kboSelectedGame;
    if (game == null) {
      return Column(
        children: [
          ScreenHeader(onBack: () => context.read<AppState>().go(AppScreen.kboResults), title: 'KBO'),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    final homeWon = (game.homeScore ?? 0) > (game.awayScore ?? 0);
    final awayWon = (game.awayScore ?? 0) > (game.homeScore ?? 0);
    final isFinished = game.status == 'FT';

    return Column(
      children: [
        ScreenHeader(onBack: () => context.read<AppState>().go(AppScreen.kboResults), title: 'KBO — Detalle'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('${game.matchDate} · ${game.time}', style: AppText.style(12, color: AppColors.textFaint)),
                        const Spacer(),
                        Pill(
                          label: isFinished ? 'FINAL' : game.status,
                          color: AppColors.textMuted,
                          background: AppColors.greyTint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TeamCrest(name: game.teamA, size: 48, logoUrl: game.teamALogoUrl),
                              const SizedBox(height: 8),
                              Text(game.teamA,
                                  textAlign: TextAlign.center,
                                  style: AppText.style(13, weight: homeWon ? FontWeight.w800 : FontWeight.w500, color: homeWon ? Colors.white : AppColors.textMuted)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: Text(
                            isFinished ? '${game.homeScore} - ${game.awayScore}' : 'VS',
                            textAlign: TextAlign.center,
                            style: AppText.style(28, weight: FontWeight.w800),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              TeamCrest(name: game.teamB, size: 48, logoUrl: game.teamBLogoUrl),
                              const SizedBox(height: 8),
                              Text(game.teamB,
                                  textAlign: TextAlign.center,
                                  style: AppText.style(13, weight: awayWon ? FontWeight.w800 : FontWeight.w500, color: awayWon ? Colors.white : AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('PREDICCIÓN DEL MODELO', style: AppText.style(11.5, weight: FontWeight.w800, color: AppColors.textFaint, letterSpacing: 0.6)),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else if (_error)
                NetworkErrorView(onRetry: _load)
              else if (_prediction == null)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Todavía no hay muestra suficiente de alguno de los dos equipos (mínimo 5 partidos cada uno) para calcular una predicción confiable.',
                    style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5),
                  ),
                )
              else ...[
                _predictionRow(
                  label: 'Ganador probable',
                  value: _prediction!.favorite,
                  prob: _prediction!.probFavorite,
                ),
                const SizedBox(height: 10),
                _predictionRow(
                  label: 'Total de carreras',
                  value: 'Más de ${_prediction!.runLine}',
                  prob: _prediction!.probOver,
                ),
                const SizedBox(height: 10),
                Text(
                  'Basado en las últimas ${_prediction!.sampleMin} muestras de cada equipo — probabilidades, no apuestas.',
                  style: AppText.style(11, color: AppColors.textFaint, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _predictionRow({required String label, required String value, required double prob}) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.style(11.5, color: AppColors.textFaint)),
                const SizedBox(height: 4),
                Text(value, style: AppText.style(15, weight: FontWeight.w800)),
              ],
            ),
          ),
          Text('${(prob * 100).round()}%', style: AppText.style(20, weight: FontWeight.w800, color: AppColors.green)),
        ],
      ),
    );
  }
}
