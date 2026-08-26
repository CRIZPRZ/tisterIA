import 'package:flutter/material.dart';

import '../data/leagues.dart';
import '../theme/app_theme.dart';
import 'team_crest.dart';

/// Card de liga con el escudo flotando mitad-arriba de una tarjeta sólida
/// (mismo patrón usado en onboarding y en "Ligas favoritas" del perfil).
class LeagueBadgeCard extends StatelessWidget {
  final String league;
  final bool active;
  final VoidCallback onTap;
  const LeagueBadgeCard({super.key, required this.league, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 152,
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 22,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 34, 10, 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.bottomCenter,
                child: Text(
                  league,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(13, weight: FontWeight.w700, height: 1.2),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.screenBg, width: 3),
                boxShadow: active ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.55), blurRadius: 12, spreadRadius: 1)] : null,
              ),
              child: TeamCrest(name: league, size: 56, logoUrl: leagueLogoUrl(league)),
            ),
            if (active)
              Positioned(
                top: 34,
                right: 34,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: AppColors.screenBg, width: 2)),
                  child: const Icon(Icons.check_rounded, size: 12, color: Color(0xFF0A0A0B)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
