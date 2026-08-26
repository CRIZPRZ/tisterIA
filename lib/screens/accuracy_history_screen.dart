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

class AccuracyHistoryScreen extends StatefulWidget {
  const AccuracyHistoryScreen({super.key});

  @override
  State<AccuracyHistoryScreen> createState() => _AccuracyHistoryScreenState();
}

class _AccuracyHistoryScreenState extends State<AccuracyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.accuracy == null) state.loadAccuracy();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.accuracy;

    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.profile),
          title: 'Historial y precisión',
        ),
        Expanded(
          child: state.accuracyError
              ? NetworkErrorView(onRetry: () => state.loadAccuracy())
              : summary == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : summary.overallTotal == 0
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
                            AppCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Text('${summary.overallPct}%', style: AppText.style(38, weight: FontWeight.w300)),
                                  const SizedBox(height: 4),
                                  Text('${summary.overallHits} de ${summary.overallTotal} picks acertados',
                                      style: AppText.style(12, color: AppColors.textMuted)),
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
                                        Text('${b.pct}%', style: AppText.style(15, weight: FontWeight.w700, color: confColor(b.confidence))),
                                      ],
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 20),
                            Text('TODOS LOS PICKS CALIFICADOS',
                                style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                            const SizedBox(height: 10),
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
                        ),
        ),
      ],
    );
  }
}
