import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BackButtonCircle extends StatelessWidget {
  final VoidCallback onTap;
  const BackButtonCircle({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  const ScreenHeader({super.key, required this.onBack, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          BackButtonCircle(onTap: onBack),
          const SizedBox(width: 14),
          Text(title, style: AppText.style(16, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.style(14.5, weight: FontWeight.w700, color: const Color(0xFF111111)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final double strokeWidth;
  _RingPainter(this.percent, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final center = rect.center;
    final radius = size.width / 2 - strokeWidth / 2;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 2 * 3.14159265 * percent, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}

/// Anillo de confianza con glow neón — usado en el hero de Home, en las
/// tarjetas de pick y en Análisis IA.
class ProbRing extends StatelessWidget {
  final int pct;
  final double size;
  final double strokeWidth;
  final Color color;
  final double fontSize;
  final String? label;

  const ProbRing({
    super.key,
    required this.pct,
    this.size = 56,
    this.strokeWidth = 5,
    this.color = AppColors.green,
    this.fontSize = 13,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: size * 0.28, spreadRadius: 0.5)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _RingPainter(pct / 100, color, strokeWidth)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$pct%', style: AppText.style(fontSize, weight: FontWeight.w800, color: color)),
              if (label != null)
                Text(label!, style: AppText.style(fontSize * 0.32, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final bool uppercase;

  const Pill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: background != null
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
          : EdgeInsets.zero,
      decoration: background != null
          ? BoxDecoration(color: background, borderRadius: BorderRadius.circular(5))
          : null,
      child: Text(
        uppercase ? label.toUpperCase() : label,
        style: AppText.style(
          uppercase ? 9.5 : 10,
          weight: FontWeight.w700,
          color: color,
          letterSpacing: uppercase ? 0.4 : null,
        ),
      ),
    );
  }
}
