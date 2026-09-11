enum StreamType { hls, embed }

StreamType? streamTypeFromString(String? s) {
  switch (s) {
    case 'hls':
      return StreamType.hls;
    case 'embed':
      return StreamType.embed;
    default:
      return null;
  }
}

/// Nunca se guarda una URL suelta en un widget — todo pasa por este modelo,
/// poblado por StreamService desde el backend. Deja lugar para lo que venga
/// después (URL firmada + expiración) sin romper el contrato con el cliente.
class MatchStream {
  final StreamType type;
  final String url;
  final bool isActive;
  final String? provider;
  final DateTime? expiresAt;

  const MatchStream({
    required this.type,
    required this.url,
    required this.isActive,
    this.provider,
    this.expiresAt,
  });

  /// null = no hay stream disponible ("available": false) — el llamador no
  /// debe mostrar el botón "Ver partido" en ese caso.
  static MatchStream? fromJson(Map<String, dynamic> json) {
    if (json['available'] != true) return null;
    final type = streamTypeFromString(json['type'] as String?);
    final url = json['url'] as String?;
    if (type == null || url == null || url.isEmpty) return null;
    return MatchStream(
      type: type,
      url: url,
      isActive: true,
      provider: json['provider'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
    );
  }
}
