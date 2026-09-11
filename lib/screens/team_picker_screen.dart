import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

class TeamPickerScreen extends StatelessWidget {
  const TeamPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final leagueId = state.teamPickerLeagueId;

    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.leaguePreferences),
          title: 'Equipo de ${state.teamPickerLeagueName}',
        ),
        Expanded(
          child: state.teamPickerError
              ? NetworkErrorView(
                  onRetry: () {
                    if (leagueId != null) context.read<AppState>().openTeamPicker(leagueId, state.teamPickerLeagueName);
                  },
                )
              : state.teamPickerLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : state.teamPickerOptions.isEmpty
                      ? const EmptyState(
                          icon: Icons.shield_outlined,
                          title: 'Sin equipos disponibles',
                          message: 'No pudimos traer el roster de esta liga todavía.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: state.teamPickerOptions.length,
                          itemBuilder: (context, i) {
                            final team = state.teamPickerOptions[i];
                            final selected = state.isFavoriteTeam(team.teamId);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                borderColor: selected ? AppColors.green : null,
                                onTap: () {
                                  context.read<AppState>().setFavoriteTeam(
                                        team.teamId,
                                        !selected,
                                        teamName: team.name,
                                      );
                                },
                                child: Row(
                                  children: [
                                    TeamCrest(name: team.name, logoUrl: team.logo, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        team.name,
                                        style: AppText.style(
                                          13.5,
                                          weight: selected ? FontWeight.w700 : FontWeight.w500,
                                          color: selected ? Colors.white : AppColors.textBody,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      selected ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: selected ? AppColors.green : AppColors.textFaint,
                                      size: 22,
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
