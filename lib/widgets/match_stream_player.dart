import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/match_stream.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Reproductor de "Ver partido" — solo HLS (video_player), con controles
/// propios (no chewie) para que se vea nativo de Tipster IA. El modo embed
/// (iframe de terceros) no se implementa: sin un proveedor con licencia
/// real que autorice explícitamente redistribuir su señal, no hay nada
/// legítimo que embeber.
class MatchStreamPlayer extends StatelessWidget {
  final MatchStream stream;
  const MatchStreamPlayer({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: stream.type == StreamType.hls
            ? _HlsPlayerView(url: stream.url)
            : const _StreamUnsupportedView(),
      ),
    );
  }
}

class _StreamUnsupportedView extends StatelessWidget {
  const _StreamUnsupportedView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Text(
        'Transmisión no disponible',
        style: AppText.style(12.5, color: AppColors.textMuted),
      ),
    );
  }
}

class _HlsPlayerView extends StatefulWidget {
  final String url;
  const _HlsPlayerView({required this.url});

  @override
  State<_HlsPlayerView> createState() => _HlsPlayerViewState();
}

class _HlsPlayerViewState extends State<_HlsPlayerView> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(_onControllerUpdate);
      await controller.play();
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null) return;
    // señal caída a media transmisión: el controller reporta error después
    // de haber inicializado bien.
    if (c.value.hasError && !_error) {
      setState(() => _error = true);
    }
  }

  Future<void> _reload() async {
    final old = _controller;
    _controller = null;
    old?.removeListener(_onControllerUpdate);
    await old?.dispose();
    await _init();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  void _openFullscreen() {
    final c = _controller;
    if (c == null) return;
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _FullscreenHlsRoute(controller: c)))
        .then((_) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _StreamErrorView(onRetry: _reload);
    }
    if (_loading || _controller == null) {
      return const _StreamLoadingView();
    }
    final c = _controller!;
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
          if (c.value.isBuffering) const CircularProgressIndicator(color: AppColors.green),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _togglePlayPause,
              child: AnimatedOpacity(
                opacity: c.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_arrow_rounded, size: 56, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: _PlayerIconButton(icon: Icons.fullscreen_rounded, onTap: _openFullscreen),
          ),
        ],
      ),
    );
  }
}

class _FullscreenHlsRoute extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullscreenHlsRoute({required this.controller});

  @override
  State<_FullscreenHlsRoute> createState() => _FullscreenHlsRouteState();
}

class _FullscreenHlsRouteState extends State<_FullscreenHlsRoute> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
              child: Center(
                child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _PlayerIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _PlayerIconButton(icon: Icons.fullscreen_exit_rounded, onTap: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PlayerIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _StreamLoadingView extends StatelessWidget {
  const _StreamLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.green),
    );
  }
}

class _StreamErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _StreamErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signal_wifi_off_rounded, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 10),
          Text('No se pudo cargar la señal', style: AppText.style(12.5, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Recargar señal', onTap: onRetry, fullWidth: false),
        ],
      ),
    );
  }
}
