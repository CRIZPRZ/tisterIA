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

  static const String productionUrl = 'https://api.tipsterias.online';
  // IP LAN de la Mac de desarrollo — cambia si tu red/IP cambia.
  static const String localUrl = 'http://192.168.100.69:8000';

  static ApiEnvironment _current = ApiEnvironment.production;
  static ApiEnvironment get current => _current;

  static String get baseUrl => _current == ApiEnvironment.local ? localUrl : productionUrl;

  /// Debe correr antes de runApp — los servicios (Dio) leen `baseUrl` una
  /// sola vez, al construirse.
  static Future<void> load() async {
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
