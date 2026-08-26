import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 8),
          child: BackButtonCircle(onTap: () => context.read<AppState>().go(AppScreen.login)),
        ),
        Expanded(
          child: state.forgotSent ? const _Sent() : const _NotSent(),
        ),
      ],
    );
  }
}

class _NotSent extends StatelessWidget {
  const _NotSent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recuperar contraseña', style: AppText.style(22, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Te enviamos un enlace para restablecerla',
              style: AppText.style(13, color: AppColors.textMuted)),
          const SizedBox(height: 22),
          const AppTextField(placeholder: 'Correo electrónico'),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Enviar enlace', onTap: () => state.sendForgot()),
        ],
      ),
    );
  }
}

class _Sent extends StatelessWidget {
  const _Sent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 26, color: AppColors.green),
          const SizedBox(height: 16),
          Text('Enlace enviado', style: AppText.style(15, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('Revisa tu correo para restablecer tu contraseña.',
              textAlign: TextAlign.center,
              style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Volver a inicio de sesión',
            fullWidth: false,
            onTap: () => state.go(AppScreen.login),
          ),
        ],
      ),
    );
  }
}
