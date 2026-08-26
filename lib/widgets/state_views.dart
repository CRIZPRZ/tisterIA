import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(title, style: AppText.style(14, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const NetworkErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 34, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('Sin conexión', style: AppText.style(14, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'No pudimos cargar los picks. Revisa tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Reintentar', fullWidth: false, onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class PickCardSkeleton extends StatefulWidget {
  const PickCardSkeleton({super.key});

  @override
  State<PickCardSkeleton> createState() => _PickCardSkeletonState();
}

class _PickCardSkeletonState extends State<PickCardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 0.85).animate(_controller),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 120, height: 11),
            const SizedBox(height: 12),
            _bar(width: 180, height: 14),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(width: 100, height: 14),
                _bar(width: 50, height: 26),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(4)),
    );
  }
}
