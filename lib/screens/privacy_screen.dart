import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.settings),
          title: 'Privacidad y términos',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Texto de ejemplo — reemplazar por la política de privacidad y términos de servicio revisados por un abogado antes de publicar en tiendas.',
                  style: AppText.style(11.5, color: AppColors.yellow, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              Text('DATOS QUE RECOPILAMOS',
                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              Text(
                'Nombre y correo al crear tu cuenta, ligas/equipos favoritos, picks que visitas, y estado de tu suscripción. No compartimos tus datos con casas de apuestas ni terceros con fines de marketing sin tu consentimiento explícito.',
                style: AppText.style(13, color: AppColors.textBody, height: 1.6),
              ),
              const SizedBox(height: 20),
              Text('APUESTA RESPONSABLE',
                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              Text(
                'Tipster IA no opera apuestas ni garantiza resultados. Los picks son análisis estadísticos con fines informativos. Ninguna predicción deportiva es 100% segura. Si decides apostar, hazlo de forma responsable y dentro de tus posibilidades. Servicio exclusivo para mayores de 18 años.',
                style: AppText.style(13, color: AppColors.textBody, height: 1.6),
              ),
              const SizedBox(height: 20),
              Text('CONTACTO',
                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              Text(
                'Para solicitudes de eliminación de cuenta o datos, escribe a soporte@tipsteria.app.',
                style: AppText.style(13, color: AppColors.textBody, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
