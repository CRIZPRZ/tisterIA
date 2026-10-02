import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A qué backend habla la app — Producción (el droplet real, con dominio y
/// HTTPS) o Local (la Mac de desarrollo, para probar cambios antes de subir
/// al servidor). Se guarda en el dispositivo y se aplica al reabrir la app
/// (los servicios ya en uso mantienen la URL con la que arrancaron).
enum ApiEnvironment { production, local }

class ApiConfig {
  ApiConfig._();

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'tipster_api_environment';
  // Solo para builds de desarrollo: `--dart-define=TIPSTER_FORCE_LOCAL_API=true`.
  // Así se puede probar el backend local sin borrar la sesión del teléfono.
  static const _forceLocalForDebug = bool.fromEnvironment('TIPSTER_FORCE_LOCAL_API');

  static const String productionUrl = 'https://api.tipsterias.online';
  // IP LAN actual del equipo de desarrollo. Permite que el teléfono físico
  // pruebe el backend local por Wi‑Fi sin usar producción.
  static const String localUrl = 'http://192.168.100.15:8085';

  static ApiEnvironment _current = ApiEnvironment.production;
  static ApiEnvironment get current => _current;

  static String get baseUrl => _current == ApiEnvironment.local ? localUrl : productionUrl;

  /// Debe correr antes de runApp — los servicios (Dio) leen `baseUrl` una
  /// sola vez, al construirse.
  static Future<void> load() async {
    if (_forceLocalForDebug) {
      _current = ApiEnvironment.local;
      return;
    }
    try {
      final saved = await _storage.read(key: _storageKey);
      _current = saved == 'local' ? ApiEnvironment.local : ApiEnvironment.production;
    } catch (_) {
      _current = ApiEnvironment.production;
    }
  }

  static Future<void> setEnvironment(ApiEnvironment env) async {
    _current = env;
    await _storage.write(key: _storageKey, value: env == ApiEnvironment.local ? 'local' : 'production');
  }
}
