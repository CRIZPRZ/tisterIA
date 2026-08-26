import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/chat_picker_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/forgot_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leagues_screen.dart';
import 'screens/login_screen.dart';
import 'screens/accuracy_history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/league_preferences_screen.dart';
import 'screens/onboarding_preferences_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const TipsterApp(),
    ),
  );
}

class TipsterApp extends StatelessWidget {
  const TipsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tipster IA',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.isBootstrapping) {
      return const Scaffold(
        backgroundColor: AppColors.screenBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    const navScreens = {AppScreen.home, AppScreen.leagues, AppScreen.chatPicker, AppScreen.profile};
    final showNav = navScreens.contains(state.screen);
    final backTarget = backTargetFor(state.screen);

    return PopScope(
      canPop: backTarget == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && backTarget != null) {
          state.go(backTarget);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _currentScreen(state.screen)),
              if (showNav) const BottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.onboarding:
        return const OnboardingScreen();
      case AppScreen.login:
        return const LoginScreen();
      case AppScreen.signup:
        return const SignupScreen();
      case AppScreen.forgot:
        return const ForgotScreen();
      case AppScreen.home:
        return const HomeScreen();
      case AppScreen.detail:
        return const DetailScreen();
      case AppScreen.paywall:
        return const PaywallScreen();
      case AppScreen.profile:
        return const ProfileScreen();
      case AppScreen.notifications:
        return const NotificationsScreen();
      case AppScreen.settings:
        return const SettingsScreen();
      case AppScreen.onboardingPreferences:
        return const OnboardingPreferencesScreen();
      case AppScreen.accuracyHistory:
        return const AccuracyHistoryScreen();
      case AppScreen.privacy:
        return const PrivacyScreen();
      case AppScreen.leaguePreferences:
        return const LeaguePreferencesScreen();
      case AppScreen.leagues:
        return const LeaguesScreen();
      case AppScreen.chatPicker:
        return const ChatPickerScreen();
    }
  }
}
