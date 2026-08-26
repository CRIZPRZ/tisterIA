import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.screenBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: state.screen == AppScreen.home,
            onTap: () => context.read<AppState>().go(AppScreen.home),
          ),
          _NavItem(
            icon: Icons.emoji_events_outlined,
            label: 'Ligas',
            active: state.screen == AppScreen.leagues,
            onTap: () => context.read<AppState>().go(AppScreen.leagues),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat IA',
            active: state.screen == AppScreen.chatPicker,
            onTap: () => context.read<AppState>().go(AppScreen.chatPicker),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            active: state.screen == AppScreen.profile,
            onTap: () => context.read<AppState>().go(AppScreen.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.green : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 4),
          Text(label, style: AppText.style(10, weight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
