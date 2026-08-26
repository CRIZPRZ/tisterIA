import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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
