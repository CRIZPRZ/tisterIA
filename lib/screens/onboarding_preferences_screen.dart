import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/leagues.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/league_badge_card.dart';

class OnboardingPreferencesScreen extends StatelessWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 40, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elige tus ligas favoritas', style: AppText.style(22, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Te mostraremos primero los picks de estas ligas. Puedes cambiarlo después desde tu perfil.',
            style: AppText.style(13, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 32),
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
                  );
                }).toList(),
              ),
            ),
          ),
          PrimaryButton(
            label: state.favoriteLeagueIds.isEmpty ? 'Omitir por ahora' : 'Continuar',
            onTap: () => state.go(AppScreen.home),
          ),
        ],
      ),
    );
  }
}
