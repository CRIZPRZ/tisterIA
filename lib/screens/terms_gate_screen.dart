import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class TermsGateScreen extends StatelessWidget {
  const TermsGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenHeader(onBack: () => state.go(AppScreen.onboarding), title: 'Términos y condiciones'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PASO 1 DE 2', style: AppText.style(12, weight: FontWeight.w800, color: AppColors.green, letterSpacing: 0.6)),
                const SizedBox(height: 14),
                Text('Políticas y términos', style: AppText.style(22, weight: FontWeight.w800)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    'Al continuar confirmas que has leído y aceptas los términos, la política de privacidad y que eres mayor de edad.',
                    style: AppText.style(13, color: AppColors.textBody, height: 1.5),
                  ),
                ),
                const SizedBox(height: 22),
                Text('DOCUMENTOS', style: AppText.style(11.5, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                _DocRow(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.green,
                  label: 'Términos y condiciones',
                  onTap: () => state.go(AppScreen.termsDoc),
                ),
                const SizedBox(height: 10),
                _DocRow(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.blue,
                  label: 'Política de privacidad',
                  onTap: () => state.go(AppScreen.privacyDoc),
                ),
                const SizedBox(height: 22),
                Text('CONFIRMACIONES', style: AppText.style(11.5, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                _CheckRow(
                  value: state.ageConfirmed,
                  onChanged: (v) => context.read<AppState>().setAgeConfirmed(v),
                  label: 'Confirmo que soy mayor de edad',
                ),
                const SizedBox(height: 8),
                _CheckRow(
                  value: state.marketingOptIn,
                  onChanged: (v) => context.read<AppState>().setMarketingOptIn(v),
                  label: 'Acepto recibir correos sobre promociones y novedades (opcional).',
                ),
                const Spacer(),
                Opacity(
                  opacity: state.ageConfirmed ? 1 : 0.4,
                  child: IgnorePointer(
                    ignoring: !state.ageConfirmed,
                    child: PrimaryButton(
                      label: 'Aceptar y continuar →',
                      onTap: () => context.read<AppState>().completeOnboardingGate(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'El siguiente paso es iniciar sesión.',
                  textAlign: TextAlign.center,
                  style: AppText.style(11.5, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _DocRow({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.style(13.5, weight: FontWeight.w600))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const _CheckRow({required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? AppColors.green : Colors.transparent,
              border: Border.all(color: value ? AppColors.green : AppColors.cardBorder, width: 1.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: value ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF0B0F0C)) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppText.style(13, height: 1.35))),
        ],
      ),
    );
  }
}
