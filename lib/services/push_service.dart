import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../state/app_state.dart';
import 'notifications_service.dart';

/// Pide permiso de notificaciones, obtiene el token de FCM del dispositivo
/// y lo manda al backend. Si Firebase no está configurado todavía
/// (faltan google-services.json / GoogleService-Info.plist), falla en
/// silencio — la app funciona igual, solo sin push.
class PushService {
  PushService._internal();
  static final PushService instance = PushService._internal();

  bool _initialized = false;

  Future<void> registerForPush(AppState appState) async {
    try {
      if (!_initialized) {
        await Firebase.initializeApp();
        _initialized = true;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await NotificationsService.instance.registerToken(token, Platform.isIOS ? 'ios' : 'android');
      }

      messaging.onTokenRefresh.listen((newToken) {
        NotificationsService.instance.registerToken(newToken, Platform.isIOS ? 'ios' : 'android');
      });

      _wireNotificationTaps(appState);
    } catch (e) {
      // Firebase todavía no configurado, o sin permiso — no rompe la app.
    }
  }

  void _handleTap(AppState appState, RemoteMessage message) {
    final pickId = message.data['pick_id'];
    if (pickId == null) return;
    appState.openFromNotification(pickId, type: message.data['type']);
  }

  /// App en segundo plano (no terminada) y el usuario toca la notificación,
  /// y app terminada por completo — este segundo caso solo se resuelve UNA
  /// vez por arranque, por eso getInitialMessage se llama aquí y no antes.
  Future<void> _wireNotificationTaps(AppState appState) async {
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(appState, message));

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleTap(appState, initialMessage);
    }
  }
}
