import 'package:dio/dio.dart';

import 'api_config.dart';

/// Un solo Dio compartido por TODA la app — antes cada servicio creaba el
/// suyo propio (15 archivos, 15 instancias), cada una con su propia
/// conexión TCP/TLS aislada sin compartir nada entre sí. Confirmado en
/// producción: la primera petición de cada servicio pagaba ~10s de
/// connectTimeout agotándose en el primer intento (algo tarda en
/// establecerse la primera conexión en ciertas redes/dispositivos), y el
/// reintento sí conectaba rápido porque la conexión ya existía — con un
/// Dio por servicio, CADA UNO pagaba ese costo por separado la primera
/// vez que se usaba. Con uno solo, basta con que la primera request de
/// toda la sesión (la que sea) caliente la conexión para el resto.
final Dio apiClient = Dio(BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  connectTimeout: const Duration(seconds: 8),
));
