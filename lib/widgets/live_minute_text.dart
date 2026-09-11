import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pick.dart';
import '../state/app_state.dart';

/// Minuto:segundo en vivo que no salta al salir/entrar de una pantalla —
/// usa el ancla de AppState (vive a nivel app, no de este widget) y solo
/// "brinca" cuando el servidor de verdad reporta un minuto nuevo.
class LiveMinuteText extends StatefulWidget {
  final Pick pick;
  final TextStyle style;
  final String prefix;
  const LiveMinuteText({super.key, required this.pick, required this.style, this.prefix = 'EN VIVO · '});

  @override
  State<LiveMinuteText> createState() => _LiveMinuteTextState();
}

class _LiveMinuteTextState extends State<LiveMinuteText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;
    String text;
    if (pick.liveStatus == 'HT') {
      text = 'ENTRETIEMPO';
    } else {
      final anchor = context.watch<AppState>().liveAnchorFor(pick.id);
      if (anchor == null) {
        text = pick.liveMinute != null ? "${widget.prefix}${pick.liveMinute}'" : 'EN VIVO';
      } else {
        final elapsed = DateTime.now().difference(anchor.capturedAt).inSeconds;
        final totalSeconds = anchor.minute * 60 + elapsed;
        final minute = totalSeconds ~/ 60;
        final seconds = totalSeconds % 60;
        final extraText = (anchor.extra != null && anchor.extra! > 0) ? '+${anchor.extra}' : '';
        text = '${widget.prefix}$minute$extraText:${seconds.toString().padLeft(2, '0')}';
      }
    }
    return Text(text, style: widget.style);
  }
}
