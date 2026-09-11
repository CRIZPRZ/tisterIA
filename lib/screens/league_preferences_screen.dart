import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/leagues.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/league_badge_card.dart';

class LeaguePreferencesScreen extends StatelessWidget {
  const LeaguePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenHeader(onBack: () => state.go(AppScreen.profile), title: 'Ligas favoritas'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige las ligas que quieres ver primero en tu feed. Toca la estrella para elegir tus equipos favoritos de esa liga — sus partidos avisan solos, jueguen el torneo que jueguen.',
                  style: AppText.style(12.5, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 30,
                      children: kLeagueIds.entries.map((entry) {
                        final active = state.favoriteLeagueIds.contains(entry.value);
                        return LeagueBadgeCard(
                          league: entry.key,
                          active: active,
                          onTap: () => context.read<AppState>().toggleFavoriteLeague(entry.value),
                          onPickTeam: () => context.read<AppState>().openTeamPicker(entry.value, entry.key),
                        );
                      }).toList(),
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
