import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/leagues.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/league_badge_card.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
          child: Text('Ligas', style: AppText.style(19, weight: FontWeight.w600)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toca una liga para ver solo sus picks en Home.',
                  style: AppText.style(12.5, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 30,
                      children: kLeagueIds.keys.map((league) {
                        final active = state.homeLeagueFilter == league;
                        return LeagueBadgeCard(
                          league: league,
                          active: active,
                          onTap: () {
                            context.read<AppState>().setHomeLeagueFilter(active ? null : league);
                            context.read<AppState>().go(AppScreen.home);
                          },
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
