import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _kCrestPalette = [
  Color(0xFFF4A61D),
  Color(0xFF2F6FB5),
  Color(0xFFB23B3B),
  Color(0xFF2C2C6B),
  Color(0xFF1F5C3F),
  Color(0xFFC9862F),
  Color(0xFF6B4FA0),
  Color(0xFF3C4A6B),
];

Color teamColor(String name) => _kCrestPalette[name.hashCode.abs() % _kCrestPalette.length];

String teamInitial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';

String leagueInitials(String league) {
  final words = league.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.length == 1) return words.first.substring(0, words.first.length.clamp(0, 3)).toUpperCase();
  return words.map((w) => w[0]).take(3).join().toUpperCase();
}

/// Círculo de "escudo": logo real de API-Football si hay [logoUrl], y si
/// no (o si falla la carga) cae a un círculo de color con la inicial.
class TeamCrest extends StatelessWidget {
  final String name;
  final double size;
  final String? logoUrl;
  const TeamCrest({super.key, required this.name, this.size = 24, this.logoUrl});

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: teamColor(name), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          teamInitial(name),
          style: AppText.style(size * 0.42, weight: FontWeight.w700, color: Colors.white),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null) return _fallback();
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: EdgeInsets.all(size * 0.1),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      ),
    );
  }
}
