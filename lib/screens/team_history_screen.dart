import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pick.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
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

String _formLabel(String code) {
  switch (code) {
    case 'W':
      return 'G';
    case 'D':
      return 'E';
    case 'L':
      return 'P';
    default:
      return code;
  }
}

Color _formColor(String code) {
  switch (code) {
    case 'W':
      return AppColors.green;
    case 'D':
      return AppColors.textMuted;
    case 'L':
      return AppColors.red;
    default:
      return AppColors.textMuted;
  }
}

class _TeamStatsCard extends StatelessWidget {
  final TeamStats stats;
  const _TeamStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: AppText.style(16, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: AppText.style(10.5, color: AppColors.textMuted)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          children: [
            if (stats.form != null && stats.form!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('FORMA RECIENTE  ', style: AppText.style(10.5, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.3)),
                  ...stats.form!.split('').map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: _formColor(c).withValues(alpha: 0.18), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(_formLabel(c), style: AppText.style(10, weight: FontWeight.w800, color: _formColor(c))),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                stat('PJ', '${stats.played}'),
                stat('PG', '${stats.wins}'),
                stat('PE', '${stats.draws}'),
                stat('PP', '${stats.loses}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                stat('Goles a favor', '${stats.goalsFor}'),
                stat('Goles en contra', '${stats.goalsAgainst}'),
                stat('Vallas en cero', '${stats.cleanSheets}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TeamHistoryScreen extends StatelessWidget {
  const TeamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final teamId = state.teamHistoryId;
    final matches = state.teamHistoryMatches;

    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.home),
          title: state.teamHistoryName,
        ),
        if (state.teamHistoryStatsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)),
          )
        else if (state.teamHistoryStats != null)
          _TeamStatsCard(stats: state.teamHistoryStats!),
        Expanded(
          child: state.teamHistoryLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.green))
              : matches.isEmpty
                  ? const EmptyState(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Sin historial todavía',
                      message: 'Cuando este equipo tenga partidos con pick generado, aparecerán aquí.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final pick = matches[i];
                        final isTeamA = pick.teamAId == teamId;
                        final opponent = isTeamA ? pick.teamB : pick.teamA;
                        final opponentLogo = isTeamA ? pick.teamBLogoUrl : pick.teamALogoUrl;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              TeamCrest(name: opponent, logoUrl: opponentLogo, size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTeamA ? 'vs. $opponent' : '@ $opponent',
                                      style: AppText.style(13.5, weight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pick.league} · ${_shortDate(pick.matchDate)}',
                                      style: AppText.style(11.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                pick.liveScore ?? pick.time,
                                style: AppText.style(
                                  14,
                                  weight: FontWeight.w800,
                                  color: pick.liveScore != null ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
