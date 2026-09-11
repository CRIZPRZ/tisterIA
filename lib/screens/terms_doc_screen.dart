import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class TermsDocScreen extends StatelessWidget {
  const TermsDocScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.termsGate),
          title: 'Términos y condiciones',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Texto de ejemplo — reemplazar por los términos y condiciones revisados por un abogado antes de publicar en tiendas.',
                  style: AppText.style(11.5, color: AppColors.yellow, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              Text('USO DEL SERVICIO', style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              Text(
                'Tipster IA es un servicio de análisis estadístico deportivo con fines informativos. No operamos apuestas, no procesamos pagos de juego ni garantizamos resultados. El uso del servicio implica que eres mayor de edad en tu jurisdicción.',
                style: AppText.style(13, color: AppColors.textBody, height: 1.6),
              ),
              const SizedBox(height: 20),
              Text('CUENTA Y SUSCRIPCIÓN', style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              Text(
                'Los planes Premium y Pro se cobran a través de Google Play y se renuevan automáticamente salvo cancelación. Puedes cancelar en cualquier momento desde tu cuenta de Google Play.',
                style: AppText.style(13, color: AppColors.textBody, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
