import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// iOS simulator: localhost funciona directo.
/// Emulador Android: cambia a http://10.0.2.2:8000 (localhost del host, no del emulador).
/// Dispositivo físico: usa la IP LAN de tu máquina.
const String kApiBaseUrl = 'http://localhost:8000';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String plan;

  const AuthUser({required this.id, required this.name, required this.email, required this.plan});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        plan: json['plan'] as String,
      );
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AuthService {
  AuthService._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final isAuthCall = error.requestOptions.path.contains('/auth/');
          if (error.response?.statusCode == 401 && !isAuthCall) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              final token = await _storage.read(key: _accessKey);
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // cae al error original
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final AuthService instance = AuthService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessKey = 'tipster_access_token';
  static const _refreshKey = 'tipster_refresh_token';

  /// Header de autorización para llamadas autenticadas hechas por otros
  /// servicios (chat, etc). Refresca el access token si ya expiró.
  Future<Map<String, String>> authHeader() async {
    var token = await _storage.read(key: _accessKey);
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }

  String _readableError(DioException e) {
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
    if (detail is String) return detail;
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
      return 'No pudimos conectar con el servidor. Revisa tu conexión.';
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }

  Future<AuthUser> register({required String name, required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
      await _storeTokens(res.data);
      return me();
    } on DioException catch (e) {
      throw AuthException(_readableError(e));
    }
  }

  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      await _storeTokens(res.data);
      return me();
    } on DioException catch (e) {
      throw AuthException(_readableError(e));
    }
  }

  Future<AuthUser> me() async {
    final token = await _storage.read(key: _accessKey);
    final res = await _dio.get('/auth/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }

  /// Puente temporal mientras no hay IAP real (StoreKit/Play Billing).
  /// Cuando exista, el backend solo debe aceptar esto tras validar el
  /// recibo de compra — no confiar en que el cliente diga la verdad.
  Future<AuthUser> setPlan(String plan) async {
    final token = await _storage.read(key: _accessKey);
    final res = await _dio.put('/auth/plan', data: {'plan': plan}, options: Options(headers: {'Authorization': 'Bearer $token'}));
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }

  /// Intenta restaurar sesión al abrir la app. Null si no hay sesión válida.
  Future<AuthUser?> tryRestoreSession() async {
    final access = await _storage.read(key: _accessKey);
    if (access == null) return null;
    try {
      return await me();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          try {
            return await me();
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }
  }

  /// Expone el refresh para que otros servicios (chat, etc) puedan
  /// reintentar tras un 401 sin duplicar la lógica de refresh token.
  Future<bool> tryRefreshToken() => _tryRefresh();

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) return false;
    try {
      final res = await _dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      await _storeTokens(res.data);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    await _storage.write(key: _accessKey, value: data['access_token'] as String);
    await _storage.write(key: _refreshKey, value: data['refresh_token'] as String);
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
