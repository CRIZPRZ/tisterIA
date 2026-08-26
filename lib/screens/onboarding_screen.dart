import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.auto_awesome, size: 34, color: AppColors.green),
          ),
          const SizedBox(height: 22),
          Text('Tipster IA',
              textAlign: TextAlign.center,
              style: AppText.style(26, weight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Text('Picks con IA,\nprobabilidad real',
              textAlign: TextAlign.center,
              style: AppText.style(16, weight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 12),
          Text(
            'Analizamos miles de datos por partido y te damos el % de probabilidad de cada pick. Tú decides dónde jugarlo.',
            textAlign: TextAlign.center,
            style: AppText.style(13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 30),
          PrimaryButton(label: 'Comenzar', onTap: () => state.go(AppScreen.signup)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => state.go(AppScreen.login),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text('Ya tengo una cuenta',
                  textAlign: TextAlign.center,
                  style: AppText.style(13, weight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No apostamos dinero real. Solo te damos el análisis — tú decides dónde y si jugarlo.',
            textAlign: TextAlign.center,
            style: AppText.style(11, color: AppColors.textFaint, height: 1.5),
          ),
        ],
      ),
    );
  }
}
