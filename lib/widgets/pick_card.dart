import 'package:flutter/material.dart';
import 'dart:ui';

import '../models/pick.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'team_crest.dart';

Color confColor(Confidence c) {
  switch (c) {
    case Confidence.alta:
      return AppColors.green;
    case Confidence.media:
      return AppColors.yellow;
    case Confidence.baja:
      return AppColors.red;
  }
}

String confLabel(Confidence c) {
  switch (c) {
    case Confidence.alta:
      return 'Alta confianza';
    case Confidence.media:
      return 'Confianza media';
    case Confidence.baja:
      return 'Confianza baja';
  }
}

String formLetterEs(String letter) {
  switch (letter) {
    case 'W':
      return 'G';
    case 'L':
      return 'P';
    default:
      return 'E';
  }
}

Color formBg(String letter) {
  switch (letter) {
    case 'W':
      return AppColors.greenTint;
    case 'L':
      return AppColors.redTint;
    default:
      return AppColors.greyTint;
  }
}

Color formColor(String letter) {
  switch (letter) {
    case 'W':
      return AppColors.green;
    case 'L':
      return AppColors.red;
    default:
      return AppColors.navMuted;
  }
}

class PickCard extends StatelessWidget {
  final Pick pick;
  final bool locked;
  final VoidCallback onOpen;
  final VoidCallback onUnlock;
  /// Muestra el pick free sin el teaser "Toca para ver el pick" — para
  /// cuando la tarjeta ya vive dentro del detalle de ese mismo partido
  /// (pestaña Mercados), donde ocultarlo no suma fricción, solo confunde.
  final bool revealFreePick;

  const PickCard({
    super.key,
    required this.pick,
    required this.locked,
    required this.onOpen,
    required this.onUnlock,
    this.revealFreePick = false,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _cardBody(showTier: false),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: onUnlock,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: const Color(0x8C111214),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Desbloquear con Premium',
                            style: AppText.style(11.5, weight: FontWeight.w600, color: const Color(0xFF111111)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(onTap: onOpen, child: _cardBody(showTier: true));
  }

  Widget _cardBody({required bool showTier}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (pick.isLive)
              LiveBadge(minute: pick.liveMinute)
            else
              Text('${pick.league} · ${pick.time}', style: AppText.style(11, color: AppColors.textMuted)),
            if (showTier)
              Pill(
                label: pick.premium ? 'PREMIUM' : 'FREE',
                color: pick.premium ? AppColors.yellow : AppColors.green,
                background: pick.premium ? const Color(0x26EAB308) : AppColors.greenTint,
              ),
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
                      TeamCrest(name: pick.teamA, size: 30, logoUrl: pick.teamALogoUrl),
                      const SizedBox(width: 8),
                      Text('VS', style: AppText.style(11.5, weight: FontWeight.w800, color: AppColors.textFaint, letterSpacing: 0.5)),
                      const SizedBox(width: 8),
                      TeamCrest(name: pick.teamB, size: 30, logoUrl: pick.teamBLogoUrl),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pick.teamA} vs ${pick.teamB}',
                    style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pick.isLive && pick.liveScore != null) ...[
                    const SizedBox(height: 4),
                    Text(pick.liveScore!, style: AppText.style(13, weight: FontWeight.w700, color: AppColors.red)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            pick.hasNoPrediction
                ? const Icon(Icons.help_outline_rounded, size: 28, color: AppColors.textFaint)
                : ProbRing(pct: pick.prob, size: 52, strokeWidth: 4.5, fontSize: 14),
          ],
        ),
        const SizedBox(height: 12),
        (pick.premium || revealFreePick)
            ? Text(
                pick.pick,
                style: AppText.style(12, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 13, color: AppColors.textFaint),
                  const SizedBox(width: 5),
                  Text(
                    'Toca para ver el pick',
                    style: AppText.style(12, color: AppColors.textFaint, weight: FontWeight.w600),
                  ),
                ],
              ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: pick.hit != null
              ? Pill(
                  label: pick.hit! ? 'Acierto' : 'Fallo',
                  color: pick.hit! ? AppColors.green : AppColors.red,
                  background: (pick.hit! ? AppColors.green : AppColors.red).withValues(alpha: 0.16),
                  uppercase: true,
                )
              : Pill(
                  label: confLabel(pick.confidence),
                  color: confColor(pick.confidence),
                  background: confColor(pick.confidence).withValues(alpha: 0.16),
                  uppercase: true,
                ),
        ),
      ],
    );
  }
}

class LiveBadge extends StatefulWidget {
  final int? minute;
  const LiveBadge({super.key, this.minute});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          widget.minute != null ? 'EN VIVO · ${widget.minute}\'' : 'EN VIVO',
          style: AppText.style(11, weight: FontWeight.w700, color: AppColors.red),
        ),
      ],
    );
  }
}
