import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

const kPlanNames = {'free': 'Free', 'premium': 'Premium', 'pro': 'Pro'};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Text('Tu perfil', style: AppText.style(19, weight: FontWeight.w600)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
            children: [
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan actual', style: AppText.style(11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(kPlanNames[state.plan]!, style: AppText.style(15, weight: FontWeight.w700)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.read<AppState>().go(AppScreen.paywall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(8)),
                        child: Text('Gestionar', style: AppText.style(11.5, weight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (summary != null && summary.overallTotal > 0) ...[
                AppCard(
                  padding: const EdgeInsets.all(18),
                  onTap: () => context.read<AppState>().go(AppScreen.accuracyHistory),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(size: const Size(72, 72), painter: _MiniDonut(summary.overallPct / 100)),
                            Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                              child: Center(
                                child: Text('${summary.overallPct}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Accuracy del modelo', style: AppText.style(13.5, weight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text('${summary.overallPct}% de aciertos sobre ${summary.overallTotal} picks calificados.',
                                style: AppText.style(11.5, color: AppColors.textMuted, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('HISTORIAL DE PICKS',
                        style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().go(AppScreen.accuracyHistory),
                      child: Text('Ver todo', style: AppText.style(11.5, weight: FontWeight.w600, color: AppColors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...summary.picks.take(4).map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${h.teamA} vs ${h.teamB}', style: AppText.style(12.5, weight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(h.pick, style: AppText.style(10.5, color: AppColors.textMuted)),
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
                const SizedBox(height: 12),
              ],
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => context.read<AppState>().go(AppScreen.leaguePreferences),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ligas favoritas', style: AppText.style(13.5, weight: FontWeight.w500)),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => context.read<AppState>().go(AppScreen.notifications),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notificaciones', style: AppText.style(13.5, weight: FontWeight.w500)),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => context.read<AppState>().go(AppScreen.settings),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ajustes de cuenta', style: AppText.style(13.5, weight: FontWeight.w500)),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniDonut extends CustomPainter {
  final double percent;
  _MiniDonut(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final arc = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final center = rect.center;
    final radius = size.width / 2 - 3.5;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 2 * 3.14159265 * percent, false, arc);
  }

  @override
  bool shouldRepaint(covariant _MiniDonut oldDelegate) => oldDelegate.percent != percent;
}
