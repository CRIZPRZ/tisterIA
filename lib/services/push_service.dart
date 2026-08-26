import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notifications_service.dart';

/// Pide permiso de notificaciones, obtiene el token de FCM del dispositivo
/// y lo manda al backend. Si Firebase no está configurado todavía
/// (faltan google-services.json / GoogleService-Info.plist), falla en
/// silencio — la app funciona igual, solo sin push.
class PushService {
  PushService._internal();
  static final PushService instance = PushService._internal();

  bool _initialized = false;

  Future<void> registerForPush() async {
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
    } catch (e) {
      // Firebase todavía no configurado, o sin permiso — no rompe la app.
    }
  }
}
