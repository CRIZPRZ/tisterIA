import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(0, 8, 0, bottomInset > 0 ? bottomInset : 10),
      decoration: const BoxDecoration(
        color: Color(0xFF171C22),
        border: Border(top: BorderSide(color: Color(0xFF272D35))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
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
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: active ? 1 : 0,
              child: Container(
                width: 44,
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.55),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppText.style(10.5, weight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
