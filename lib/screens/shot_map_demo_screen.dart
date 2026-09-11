import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// Pantalla DEMO — datos 100% simulados, para revisar el diseño antes de
// contratar un proveedor con coordenadas de tiro reales (API-Football no
// las tiene). No se conecta a ningún backend ni se muestra a usuarios
// reales; solo alcanzable desde Perfil mientras se decide.

class _MockShot {
  final String player;
  final int minute;
  final double xg;
  final double? xgot;
  final String result; // 'Gol' | 'Fallado' | 'Atajado' | 'Bloqueado'
  final String situation;
  final String shotType;
  final String goalZone;
  final double x; // 0..1 sobre el ANCHO de la tarjeta
  final double y; // 0..1 sobre el ALTO de la tarjeta (0 = arriba del todo)
  // Dónde terminó el tiro respecto a la portería: 0..1 entre postes y entre
  // travesaño (0) y suelo (1). Fuera de ese rango = desviado o por encima.
  final double goalX;
  final double goalY;

  const _MockShot({
    required this.player,
    required this.minute,
    required this.xg,
    this.xgot,
    required this.result,
    required this.situation,
    required this.shotType,
    required this.goalZone,
    required this.x,
    required this.y,
    required this.goalX,
    required this.goalY,
  });
}

const _teamColorA = Color(0xFFB8CCB4);
const _teamColorB = Color(0xFFB9C6E8);
const _teamRingA = Color(0xFF4E7A4A);
const _teamRingB = Color(0xFF3B4FA8);

const _mockShotsA = <_MockShot>[
  _MockShot(player: 'Á. Calatrava', minute: 49, xg: 0.08, result: 'Fallado', situation: 'Juego abierto', shotType: 'Zurdo', goalZone: 'Derecho', x: 0.76, y: 0.46, goalX: 1.55, goalY: 0.45),
  _MockShot(player: 'E. Expósito', minute: 26, xg: 0.02, result: 'Bloqueo', situation: 'Asistencia', shotType: 'Diestro', goalZone: '-', x: 0.50, y: 0.42, goalX: 0.60, goalY: -0.45),
  _MockShot(player: 'J. Puado', minute: 34, xg: 0.19, xgot: 0.31, result: 'Parada', situation: 'Contraataque', shotType: 'Diestro', goalZone: 'Centro bajo', x: 0.44, y: 0.46, goalX: 0.50, goalY: 0.80),
  _MockShot(player: 'P. Fernández', minute: 58, xg: 0.05, result: 'Bloqueo', situation: 'Balón parado', shotType: 'Cabeza', goalZone: '-', x: 0.36, y: 0.52, goalX: -0.50, goalY: 0.55),
  _MockShot(player: 'Á. Calatrava', minute: 71, xg: 0.34, xgot: 0.52, result: 'Gol', situation: 'Juego abierto', shotType: 'Diestro', goalZone: 'Esquina alta', x: 0.48, y: 0.40, goalX: 0.86, goalY: 0.18),
  _MockShot(player: 'J. Puado', minute: 80, xg: 0.12, result: 'Fallado', situation: 'Juego abierto', shotType: 'Diestro', goalZone: '-', x: 0.60, y: 0.55, goalX: 0.35, goalY: -0.55),
  _MockShot(player: 'R. Lozano', minute: 88, xg: 0.07, xgot: 0.11, result: 'Parada', situation: 'Córner', shotType: 'Cabeza', goalZone: 'Bajo derecha', x: 0.68, y: 0.49, goalX: 0.80, goalY: 0.84),
];

const _mockShotsB = <_MockShot>[
  _MockShot(player: 'K. Mbappé', minute: 82, xg: 0.05, result: 'Fallado', situation: 'Asistencia', shotType: 'Diestro', goalZone: 'Izquierdo', x: 0.22, y: 0.44, goalX: -0.60, goalY: 0.50),
  _MockShot(player: 'Vinícius Jr.', minute: 8, xg: 0.22, xgot: 0.41, result: 'Parada', situation: 'Juego abierto', shotType: 'Zurdo', goalZone: 'Esquina baja', x: 0.36, y: 0.37, goalX: 0.14, goalY: 0.86),
  _MockShot(player: 'J. Bellingham', minute: 27, xg: 0.11, result: 'Fallado', situation: 'Contraataque', shotType: 'Diestro', goalZone: '-', x: 0.52, y: 0.35, goalX: 0.45, goalY: -0.50),
  _MockShot(player: 'K. Mbappé', minute: 15, xg: 0.02, xgot: 0.03, result: 'Parada', situation: 'Asistencia', shotType: 'Diestro', goalZone: 'Bajo izquierda', x: 0.35, y: 0.48, goalX: 0.22, goalY: 0.84),
  _MockShot(player: 'K. Mbappé', minute: 38, xg: 0.09, xgot: 0.09, result: 'Parada', situation: 'Contraataque', shotType: 'Diestro', goalZone: 'Centro bajo', x: 0.50, y: 0.42, goalX: 0.50, goalY: 0.82),
  _MockShot(player: 'A. Güler', minute: 45, xg: 0.44, xgot: 0.68, result: 'Gol', situation: 'Juego abierto', shotType: 'Diestro', goalZone: 'Centro bajo', x: 0.54, y: 0.36, goalX: 0.55, goalY: 0.78),
  _MockShot(player: 'K. Mbappé', minute: 78, xg: 0.10, result: 'Fallado', situation: 'Contraataque', shotType: 'Diestro', goalZone: '-', x: 0.47, y: 0.53, goalX: 1.45, goalY: 0.30),
  _MockShot(player: 'F. Valverde', minute: 61, xg: 0.06, xgot: 0.08, result: 'Parada', situation: 'Juego abierto', shotType: 'Diestro', goalZone: 'Bajo derecha', x: 0.65, y: 0.43, goalX: 0.82, goalY: 0.85),
  _MockShot(player: 'D. Carvajal', minute: 70, xg: 0.04, result: 'Fallado', situation: 'Córner', shotType: 'Cabeza', goalZone: '-', x: 0.24, y: 0.49, goalX: -0.35, goalY: 0.20),
  _MockShot(player: 'E. Camavinga', minute: 55, xg: 0.03, result: 'Fallado', situation: 'Juego abierto', shotType: 'Zurdo', goalZone: '-', x: 0.60, y: 0.47, goalX: 0.70, goalY: -0.40),
];

class ShotMapDemoScreen extends StatefulWidget {
  const ShotMapDemoScreen({super.key});

  @override
  State<ShotMapDemoScreen> createState() => _ShotMapDemoScreenState();
}

class _ShotMapDemoScreenState extends State<ShotMapDemoScreen> {
  int _team = 1;
  int _half = 0;
  // null = nada seleccionado (estado al entrar y al cambiar de equipo): no
  // se dibuja línea ni destino hasta que el usuario toca un tiro.
  int? _shotIndex;

  List<_MockShot> get _shots => _team == 0 ? _mockShotsA : _mockShotsB;
  Color get _fill => _team == 0 ? _teamColorA : _teamColorB;
  Color get _ring => _team == 0 ? _teamRingA : _teamRingB;

  @override
  Widget build(BuildContext context) {
    final shots = _shots;
    final index = _shotIndex;
    final shot = index == null ? null : shots[index];

    return Column(
      children: [
        ScreenHeader(
          onBack: () => context.read<AppState>().go(AppScreen.profile),
          title: 'Mapa de disparos (demo)',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _HalfSelector(active: _half, onChanged: (v) => setState(() => _half = v)),
              ),
              const SizedBox(height: 12),
              Center(
                child: _TeamSegmentedTab(
                  active: _team,
                  onChanged: (v) => setState(() {
                    _team = v;
                    _shotIndex = null;
                  }),
                ),
              ),
              const SizedBox(height: 14),
              _PitchView(
                shots: shots,
                fill: _fill,
                ring: _ring,
                selectedIndex: _shotIndex,
                onSelect: (i) => setState(() => _shotIndex = i),
              ),
              const SizedBox(height: 12),
              if (shot == null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF111214), borderRadius: BorderRadius.circular(18)),
                  alignment: Alignment.center,
                  child: Text('Toca un tiro para ver su detalle',
                      style: AppText.style(14, color: AppColors.textMuted)),
                )
              else
                _ShotDetailCard(
                  shot: shot,
                  onPrev: () => setState(() => _shotIndex = (index! - 1 + shots.length) % shots.length),
                  onNext: () => setState(() => _shotIndex = (index! + 1) % shots.length),
                ),
              const SizedBox(height: 10),
              Text('Datos simulados — solo para revisar el diseño, no son reales.',
                  textAlign: TextAlign.center,
                  style: AppText.style(11, color: AppColors.textFaint, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HalfSelector extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;
  const _HalfSelector({required this.active, required this.onChanged});

  Widget _pill(String label, int value) {
    final isActive = active == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2B2F36) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: AppText.style(14, weight: FontWeight.w700, color: isActive ? Colors.white : AppColors.textMuted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF16181C), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [_pill('1°', 0), _pill('2°', 1)]),
    );
  }
}

class _TeamSegmentedTab extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;
  const _TeamSegmentedTab({required this.active, required this.onChanged});

  Widget _segment(Color crest, IconData icon, int value) {
    final isActive = active == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 72,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: crest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF16181C), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(const Color(0xFF0B4EA2), Icons.shield, 0),
          _segment(const Color(0xFFC9A227), Icons.workspace_premium, 1),
        ],
      ),
    );
  }
}

class _PitchView extends StatelessWidget {
  final List<_MockShot> shots;
  final Color fill;
  final Color ring;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  const _PitchView({
    required this.shots,
    required this.fill,
    required this.ring,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 0.82,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final idx = selectedIndex;
          final sel = idx == null ? null : shots[idx];
          // Dónde terminó el tiro seleccionado, sobre el marco de la
          // portería (puede caer fuera: desviado o por encima).
          final goalRect = _PitchPainter.goalRectFor(w, h);
          final endPoint = sel == null
              ? null
              : Offset(
                  goalRect.left + goalRect.width * sel.goalX,
                  goalRect.top + goalRect.height * sel.goalY,
                );
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
              if (sel != null && endPoint != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GuideLinePainter(
                      from: Offset(sel.x * w, sel.y.clamp(_PitchPainter.goalLineY + 0.02, 1.0) * h),
                      to: endPoint,
                    ),
                  ),
                ),
              // El origen de un tiro siempre está en la cancha — si el dato
              // viniera con una "y" arriba de la línea de meta, se pega a
              // ella en vez de quedar flotando en la tribuna.
              for (int i = 0; i < shots.length; i++)
                Positioned(
                  left: shots[i].x * w - 14,
                  top: (shots[i].y.clamp(_PitchPainter.goalLineY + 0.02, 1.0)) * h - 14,
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: _ShotMarker(
                      shot: shots[i],
                      fill: fill,
                      ring: ring,
                      selected: i == selectedIndex,
                    ),
                  ),
                ),
              // Marcador de destino en la portería (solo el seleccionado).
              if (sel != null && endPoint != null)
                Positioned(
                  left: endPoint.dx - 14,
                  top: endPoint.dy - 14,
                  child: IgnorePointer(
                    child: _ShotMarker(shot: sel, fill: fill, ring: ring, selected: true),
                  ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  // Fracciones verticales de la tarjeta.
  static const standBottom = 0.245; // fin de la zona negra detrás de la portería
  static const goalLineY = 0.305; // línea de meta (fin de la franja en perspectiva)

  static const _grassA = Color(0xFF6E8F62);
  static const _grassB = Color(0xFF658759);
  static const _behindGoal = Color(0xFF5E8253);
  static const _line = Color(0xFF1B2A17);

  /// Marco de la portería en coordenadas de la tarjeta — compartido con la
  /// capa de marcadores para poder ubicar dónde terminó cada tiro.
  static Rect goalRectFor(double w, double h) {
    final goalW = w * 0.29;
    final goalH = h * 0.105;
    return Rect.fromLTWH(w * 0.5 - goalW / 2, h * standBottom - goalH, goalW, goalH);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fondo negro (tribuna detrás de la portería).
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * standBottom), Paint()..color = const Color(0xFF0B0B0C));

    // Franja de pasto detrás de la meta (en perspectiva).
    canvas.drawRect(
      Rect.fromLTWH(0, h * standBottom, w, h * (goalLineY - standBottom)),
      Paint()..color = _behindGoal,
    );

    // Cancha con franjas de corte.
    final pitchTop = h * goalLineY;
    final stripe = (h - pitchTop) / 5;
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, pitchTop + stripe * i, w, stripe + 1),
        Paint()..color = i.isEven ? _grassA : _grassB,
      );
    }

    final line = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Líneas en perspectiva desde los postes hacia las esquinas.
    final postL = w * 0.355;
    final postR = w * 0.645;
    canvas.drawLine(Offset(postL, h * standBottom + 2), Offset(w * 0.10, h * goalLineY - 2), line);
    canvas.drawLine(Offset(postR, h * standBottom + 2), Offset(w * 0.90, h * goalLineY - 2), line);

    // Línea de meta.
    canvas.drawLine(Offset(0, pitchTop), Offset(w, pitchTop), line);

    // Marco de la cancha.
    final fieldL = w * 0.09;
    final fieldR = w * 0.91;
    canvas.drawRect(Rect.fromLTRB(fieldL, pitchTop, fieldR, h * 0.985), line);

    // Área grande.
    final boxL = w * 0.235;
    final boxR = w * 0.765;
    final boxBottom = pitchTop + (h - pitchTop) * 0.30;
    canvas.drawRect(Rect.fromLTRB(boxL, pitchTop, boxR, boxBottom), line);

    // Área chica.
    final smallL = w * 0.385;
    final smallR = w * 0.615;
    final smallBottom = pitchTop + (h - pitchTop) * 0.115;
    canvas.drawRect(Rect.fromLTRB(smallL, pitchTop, smallR, smallBottom), line);

    // Semicírculo del área.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, boxBottom), width: w * 0.30, height: (h - pitchTop) * 0.17),
      0,
      3.1416,
      false,
      line,
    );

    // Arcos de esquina.
    canvas.drawArc(Rect.fromCircle(center: Offset(fieldL, pitchTop), radius: w * 0.05), 0, 1.5708, false, line);
    canvas.drawArc(Rect.fromCircle(center: Offset(fieldR, pitchTop), radius: w * 0.05), 1.5708, 1.5708, false, line);

    // Círculo central (mitad superior visible).
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 1.02), width: w * 0.40, height: (h - pitchTop) * 0.45),
      3.1416,
      3.1416,
      false,
      line,
    );

    // Punto penal.
    canvas.drawCircle(Offset(w * 0.5, pitchTop + (h - pitchTop) * 0.185), 2.2, Paint()..color = _line);

    // Portería: red + marco blanco.
    final goalRect = goalRectFor(w, h);
    canvas.drawRect(goalRect, Paint()..color = const Color(0xFF121316));
    final net = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;
    const cols = 9;
    const rows = 5;
    for (int i = 1; i < cols; i++) {
      final x = goalRect.left + goalRect.width * i / cols;
      canvas.drawLine(Offset(x, goalRect.top), Offset(x, goalRect.bottom), net);
    }
    for (int i = 1; i < rows; i++) {
      final y = goalRect.top + goalRect.height * i / rows;
      canvas.drawLine(Offset(goalRect.left, y), Offset(goalRect.right, y), net);
    }
    canvas.drawRect(
      goalRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuideLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  const _GuideLinePainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    var covered = 0.0;
    var current = from;
    while (covered < total) {
      final next = current + dir * dash;
      canvas.drawLine(current, next, paint);
      current = next + dir * dash;
      covered += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _GuideLinePainter old) => old.from != from || old.to != to;
}

class _ShotMarker extends StatelessWidget {
  final _MockShot shot;
  final Color fill;
  final Color ring;
  final bool selected;
  const _ShotMarker({required this.shot, required this.fill, required this.ring, required this.selected});

  @override
  Widget build(BuildContext context) {
    // Gol = solo el balón (sin círculo detrás). Parada = círculo con punto
    // (fue a puerta). El resto, círculo liso. El seleccionado se rellena de
    // blanco.
    if (shot.result == 'Gol') {
      return SizedBox(
        width: 28,
        height: 28,
        child: Icon(Icons.sports_soccer, size: 26, color: selected ? Colors.white : fill),
      );
    }
    final onTarget = shot.result == 'Parada';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : fill,
        border: Border.all(color: ring, width: 1.6),
      ),
      child: onTarget
          ? Center(child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: ring)))
          : null,
    );
  }
}

class _ShotDetailCard extends StatelessWidget {
  final _MockShot shot;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _ShotDetailCard({required this.shot, required this.onPrev, required this.onNext});

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(label, style: AppText.style(13, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text(value, textAlign: TextAlign.center, style: AppText.style(14.5, weight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(color: const Color(0xFF111214), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onPrev,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left_rounded, color: Color(0xFF6C77F4), size: 30),
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF23262B),
                child: Icon(Icons.person, color: AppColors.textMuted, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(shot.player, style: AppText.style(17, weight: FontWeight.w600))),
              Text("${shot.minute}'", style: AppText.style(17, weight: FontWeight.w700)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onNext,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right_rounded, color: Color(0xFF6C77F4), size: 30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _stat('xG', shot.xg.toStringAsFixed(2)),
              _stat('xGOT', shot.xgot?.toStringAsFixed(2) ?? '-'),
              _stat('Resultado', shot.result),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _stat('Situación', shot.situation),
              _stat('Tipo de disparo', shot.shotType),
              _stat('Zona de gol', shot.goalZone),
            ],
          ),
        ],
      ),
    );
  }
}
