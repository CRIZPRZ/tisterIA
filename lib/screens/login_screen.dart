import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _EnvOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _EnvOption({required this.label, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.green : AppColors.cardBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.green : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.style(13, weight: FontWeight.w700)),
                  Text(subtitle, style: AppText.style(10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Mantén presionado el logo para elegir a qué backend habla la app —
  // útil solo en desarrollo (probar contra la Mac antes de subir al server).
  void _showEnvironmentPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Conexión', style: AppText.style(15, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnvOption(
              label: 'Producción',
              subtitle: ApiConfig.productionUrl,
              selected: ApiConfig.current == ApiEnvironment.production,
              onTap: () => Navigator.of(dialogContext).pop(ApiEnvironment.production),
            ),
            const SizedBox(height: 10),
            _EnvOption(
              label: 'Local',
              subtitle: ApiConfig.localUrl,
              selected: ApiConfig.current == ApiEnvironment.local,
              onTap: () => Navigator.of(dialogContext).pop(ApiEnvironment.local),
            ),
          ],
        ),
      ),
    ).then((selected) async {
      if (selected == null || !mounted) return;
      await ApiConfig.setEnvironment(selected as ApiEnvironment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardado — cierra y vuelve a abrir la app para aplicarlo.'),
          backgroundColor: AppColors.card,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 8),
          child: BackButtonCircle(onTap: () {
            context.read<AppState>().clearAuthError();
            context.read<AppState>().go(AppScreen.onboarding);
          }),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onLongPress: () => _showEnvironmentPicker(context),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 28, color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Inicia sesión', style: AppText.style(22, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Accede para ver tus picks del día',
                    style: AppText.style(13, color: AppColors.textMuted)),
                const SizedBox(height: 22),
                AppTextField(
                  controller: _emailController,
                  placeholder: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _passwordController, placeholder: 'Contraseña', obscure: true),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.read<AppState>().go(AppScreen.forgot),
                  child: Text('¿Olvidaste tu contraseña?',
                      textAlign: TextAlign.right,
                      style: AppText.style(12, weight: FontWeight.w500, color: AppColors.textMuted)),
                ),
                if (state.authError != null) ...[
                  const SizedBox(height: 12),
                  Text(state.authError!, style: AppText.style(12, color: AppColors.red)),
                ],
                const SizedBox(height: 22),
                state.authLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                    : PrimaryButton(
                        label: 'Iniciar sesión',
                        onTap: () => context.read<AppState>().login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ),
                      ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta? ', style: AppText.style(12.5, color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().go(AppScreen.signup),
                      child: Text('Crear cuenta',
                          style: AppText.style(12.5, weight: FontWeight.w600, color: AppColors.blue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
