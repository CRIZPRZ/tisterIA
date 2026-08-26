import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
                Text('Crea tu cuenta', style: AppText.style(22, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Empieza a recibir picks con IA',
                    style: AppText.style(13, color: AppColors.textMuted)),
                const SizedBox(height: 22),
                AppTextField(controller: _nameController, placeholder: 'Nombre'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _emailController,
                  placeholder: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _passwordController, placeholder: 'Contraseña (mín. 8 caracteres)', obscure: true),
                if (state.authError != null) ...[
                  const SizedBox(height: 12),
                  Text(state.authError!, style: AppText.style(12, color: AppColors.red)),
                ],
                const SizedBox(height: 22),
                state.authLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                    : PrimaryButton(
                        label: 'Crear cuenta',
                        onTap: () => context.read<AppState>().register(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ),
                      ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta? ', style: AppText.style(12.5, color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().go(AppScreen.login),
                      child: Text('Inicia sesión',
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
