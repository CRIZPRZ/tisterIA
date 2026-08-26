import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _SettingRow {
  final String label;
  final Color color;
  final VoidCallback onTap;
  _SettingRow({required this.label, required this.color, required this.onTap});
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature — próximamente', style: AppText.style(12.5, color: Colors.white)),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

void _confirmLogout(BuildContext context, AppState state) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('¿Cerrar sesión?', style: AppText.style(15, weight: FontWeight.w700)),
      content: Text('Vas a salir de tu cuenta en este dispositivo.', style: AppText.style(12.5, color: AppColors.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppText.style(13, weight: FontWeight.w600, color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            state.logout();
          },
          child: Text('Cerrar sesión', style: AppText.style(13, weight: FontWeight.w700, color: AppColors.red)),
        ),
      ],
    ),
  );
}

void _showLanguagePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      decoration: const BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Idioma', style: AppText.style(16, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          _LanguageRow(label: 'Español', selected: true, onTap: () => Navigator.of(context).pop()),
          _LanguageRow(
            label: 'English',
            selected: false,
            onTap: () {
              Navigator.of(context).pop();
              _showComingSoon(context, 'English');
            },
          ),
        ],
      ),
    ),
  );
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.style(14, weight: FontWeight.w500)),
            if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final rows = [
      _SettingRow(label: 'Editar perfil', color: Colors.white, onTap: () => _showComingSoon(context, 'Editar perfil')),
      _SettingRow(label: 'Método de pago', color: Colors.white, onTap: () => _showComingSoon(context, 'Método de pago')),
      _SettingRow(label: 'Idioma', color: Colors.white, onTap: () => _showLanguagePicker(context)),
      _SettingRow(label: 'Privacidad', color: Colors.white, onTap: () => state.go(AppScreen.privacy)),
      _SettingRow(label: 'Cerrar sesión', color: AppColors.red, onTap: () => _confirmLogout(context, state)),
    ];

    return Column(
      children: [
        ScreenHeader(
          onBack: () => state.go(AppScreen.profile),
          title: 'Ajustes de cuenta',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
            children: rows
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        onTap: r.onTap,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.label, style: AppText.style(13.5, weight: FontWeight.w500, color: r.color)),
                            Icon(Icons.chevron_right_rounded, size: 14, color: r.color),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
