/// Reintenta una llamada de red hasta [retries] veces antes de rendirse —
/// para no mostrar "error de servidor" al usuario por un solo hipo
/// pasajero (el servidor ocupado un instante, un timeout puntual).
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int retries = 2,
  Duration delay = const Duration(milliseconds: 600),
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } catch (_) {
      attempt++;
      if (attempt > retries) rethrow;
      await Future.delayed(delay * attempt);
    }
  }
}
