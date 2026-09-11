import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match_stream.dart';
import '../models/pick.dart';
import '../models/player_prop_pick.dart';
import '../services/events_service.dart';
import '../services/lineup_service.dart';
import '../services/player_props_service.dart';
import '../services/standings_service.dart';
import '../services/stats_service.dart';
import '../services/stream_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/common.dart';
import '../widgets/live_minute_text.dart';
import '../widgets/match_stream_player.dart';
import '../widgets/pick_card.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Timer? _liveTimer;

  // Finalizado = ya tiene marcador Y no está en vivo. Antes el refresco
  // periódico solo corría si `isLive` YA era true — eso es un candado que
  // nunca se abre solo: si entras ANTES del kickoff, jamás refresca, así
  // que nunca detecta el cambio a en vivo (te quedabas pegado hasta salir
  // a Home y volver a entrar, que sí dispara su propio refresh). Refresca
  // mientras el resultado no esté cerrado, no solo cuando ya está en vivo.
  bool _isFinished(Pick p) => p.liveScore != null && !p.isLive;

  @override
  void initState() {
    super.initState();
    if (!_isFinished(context.read<AppState>().selectedPick)) {
      context.read<AppState>().loadPicks(); // refresco inmediato al abrir, no esperar 20s
    }
    _liveTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_isFinished(context.read<AppState>().selectedPick)) {
        context.read<AppState>().loadPicks();
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pick = state.selectedPick;
    final locked = state.isLocked(pick);

    return Stack(
      children: [
        const Positioned.fill(child: _DetailBackground()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<AppState>().go(AppScreen.home),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Análisis IA del partido',
                      textAlign: TextAlign.center,
                      style: AppText.style(18, weight: FontWeight.w800),
                    ),
                  ),
                  if (pick.liveScore != null && !pick.isLive)
                    const SizedBox(width: 36)
                  else
                    GestureDetector(
                      onTap: () => context.read<AppState>().toggleFollow(pick),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          state.isFollowing(pick) ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 20,
                          color: state.isFollowing(pick) ? AppColors.green : Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: locked
                  ? const _LockedBody()
                  : _UnlockedTabs(pick: pick, initialTabIndex: state.pendingDetailTabIndex),
            ),
          ],
        ),
      ],
    );
  }
}


// Desglose real de local/empate/visitante del mercado 1X2 — de la fuente
// que de verdad se usó (ml/dixon_coles/api), no siempre lo mismo, así que
// nunca se muestra en franco desacuerdo con el pick de arriba.
class _ProbBreakdownBar extends StatelessWidget {
  final Pick pick;
  const _ProbBreakdownBar({required this.pick});

  @override
  Widget build(BuildContext context) {
    final home = pick.market0ProbHome ?? 0;
    final draw = pick.market0ProbDraw ?? 0;
    final away = pick.market0ProbAway ?? 0;
    if (home + draw + away <= 0) return const SizedBox.shrink();

    Widget seg(int value, Color color) => Expanded(
          flex: value.clamp(1, 1000),
          child: Container(height: 6, color: color),
        );

    Widget stat(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text('$value%', style: AppText.style(13, weight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(9.5, color: AppColors.textMuted),
              ),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          if (pick.scoreProbabilities.isNotEmpty) ...[
            Text('MARCADORES PROBABLES', style: AppText.style(9.5, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pick.scoreProbabilities.length; i++) ...[
                  if (i > 0) const SizedBox(width: 20),
                  Column(
                    children: [
                      Text(
                        '${pick.scoreProbabilities[i].home} - ${pick.scoreProbabilities[i].away}',
                        style: AppText.style(i == 0 ? 18 : 14, weight: i == 0 ? FontWeight.w800 : FontWeight.w700, color: i == 0 ? Colors.white : AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text('${pick.scoreProbabilities[i].pct}%', style: AppText.style(10.5, weight: FontWeight.w600, color: AppColors.textFaint)),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ] else if (pick.predictedScoreHome != null && pick.predictedScoreAway != null) ...[
            Text('MARCADOR PROBABLE', style: AppText.style(9.5, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(
              '${pick.predictedScoreHome} - ${pick.predictedScoreAway}',
              style: AppText.style(18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(children: [seg(home, AppColors.green), seg(draw, AppColors.textFaint), seg(away, AppColors.blue)]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat(pick.teamA, home, AppColors.green),
              stat('Empate', draw, AppColors.textFaint),
              stat(pick.teamB, away, AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardCount extends StatelessWidget {
  final int yellow;
  final int red;
  const _CardCount({required this.yellow, required this.red});

  @override
  Widget build(BuildContext context) {
    if (yellow == 0 && red == 0) return const SizedBox(width: 22);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (yellow > 0) ...[
          Container(width: 12, height: 16, color: const Color(0xFFF2C94C)),
          const SizedBox(width: 4),
          Text('$yellow', style: AppText.style(12, weight: FontWeight.w700, color: const Color(0xFFF2C94C))),
        ],
        if (yellow > 0 && red > 0) const SizedBox(width: 10),
        if (red > 0) ...[
          Container(width: 12, height: 16, color: AppColors.red),
          const SizedBox(width: 4),
          Text('$red', style: AppText.style(12, weight: FontWeight.w700, color: AppColors.red)),
        ],
      ],
    );
  }
}

// Goleadores debajo del marcador, como un scoreboard real — más útil de
// un vistazo que tener que entrar a la pestaña "Eventos" para ver quién
// anotó. Se calla del todo (sin spinner ni estado vacío) si no hay goles
// o si el fetch falla — es un adorno del header, no algo crítico.
class _GoalScorersRow extends StatefulWidget {
  final Pick pick;
  const _GoalScorersRow({required this.pick});

  @override
  State<_GoalScorersRow> createState() => _GoalScorersRowState();
}

class _GoalScorersRowState extends State<_GoalScorersRow> {
  List<MatchEvent> _goals = [];
  Timer? _liveRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.pick.isLive) {
      _liveRefresh = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    }
  }

  @override
  void dispose() {
    _liveRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final events = await EventsService.instance.fetchEvents(widget.pick.id);
      final goals = events.where((e) => e.isGoal).toList()..sort((a, b) => a.minute.compareTo(b.minute));
      if (mounted) setState(() => _goals = goals);
    } catch (_) {
      // silencioso — es un adorno, no un dato crítico que amerite reintentar
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_goals.isEmpty) return const SizedBox.shrink();
    final pick = widget.pick;
    final homeGoals = _goals.where((e) => e.teamId == pick.teamAId).toList();
    final awayGoals = _goals.where((e) => e.teamId == pick.teamBId).toList();

    Widget scorerLine(MatchEvent e, TextAlign align) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${e.player} ${e.minuteLabel}',
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(11.5, color: AppColors.textMuted),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (final e in homeGoals) scorerLine(e, TextAlign.right)],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.sports_soccer_rounded, size: 14, color: AppColors.textFaint),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final e in awayGoals) scorerLine(e, TextAlign.left)],
          ),
        ),
      ],
    );
  }
}

// "Ver partido" — solo se muestra si el backend confirma que hay una
// transmisión disponible para este pick (nunca se asume, nunca hardcodeado).
class _MatchStreamSection extends StatefulWidget {
  final Pick pick;
  const _MatchStreamSection({required this.pick});

  @override
  State<_MatchStreamSection> createState() => _MatchStreamSectionState();
}

class _MatchStreamSectionState extends State<_MatchStreamSection> {
  MatchStream? _stream;
  bool _checked = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    StreamService.instance.fetchStream(widget.pick.id).then((stream) {
      if (mounted) {
        setState(() {
          _stream = stream;
          _checked = true;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _checked = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _stream == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _expanded ? AppColors.card : AppColors.green,
                borderRadius: BorderRadius.circular(14),
                border: _expanded ? Border.all(color: AppColors.cardBorder) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.play_circle_fill_rounded,
                    size: 19,
                    color: _expanded ? Colors.white : const Color(0xFF0A0A0B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _expanded ? 'Ocultar transmisión' : 'Ver partido',
                    style: AppText.style(
                      13.5,
                      weight: FontWeight.w800,
                      color: _expanded ? Colors.white : const Color(0xFF0A0A0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: MatchStreamPlayer(stream: _stream!),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _DetailBackground extends StatelessWidget {
  const _DetailBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF09120D), Color(0xFF060A08)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x221EF0A2), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -120,
            bottom: 220,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 220,
                height: 360,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(180),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x101EF0A2), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBody extends StatelessWidget {
  const _LockedBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 26, color: Colors.white),
          const SizedBox(height: 14),
          Text(
            'Pick premium bloqueado',
            style: AppText.style(15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            'Desbloquea el análisis completo, el gráfico de probabilidad y el historial de precisión del modelo.',
            textAlign: TextAlign.center,
            style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Desbloquear con Premium',
            fullWidth: false,
            onTap: () => context.read<AppState>().go(AppScreen.paywall),
          ),
        ],
      ),
    );
  }
}

class _UnlockedTabs extends StatelessWidget {
  final Pick pick;
  final int? initialTabIndex;
  const _UnlockedTabs({required this.pick, this.initialTabIndex});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      initialIndex: initialTabIndex ?? 0,
      child: Column(
        children: [
          if (pick.isLive) _MatchStreamSection(pick: pick),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF111B15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.12),
                ),
              ),
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  scrollbars: false,
                  overscroll: false,
                ),
                child: TabBar(
                  isScrollable: true,
                  physics: const BouncingScrollPhysics(),
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF29CB67),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF29CB67).withValues(alpha: 0.22),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 2),
                  labelColor: Colors.black,
                  unselectedLabelColor: const Color(0xFFA7AFB6),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  labelStyle: AppText.style(12.5, weight: FontWeight.w800),
                  unselectedLabelStyle: AppText.style(
                    12.5,
                    weight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Análisis'),
                    Tab(text: 'Chat'),
                    Tab(text: 'Mercados'),
                    Tab(text: 'Eventos'),
                    Tab(text: 'Estadísticas'),
                    Tab(text: 'Alineación'),
                    Tab(text: 'Tabla'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AnalysisTab(pick: pick),
                _MatchChatTab(pick: pick),
                _MarketsTab(pick: pick),
                _EventsTab(pick: pick),
                _StatsTab(pick: pick),
                _LineupTab(pick: pick),
                _StandingsTab(pick: pick),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _monthAbbr = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _shortDate(String? matchDate) {
  if (matchDate == null) return '';
  final parts = matchDate.split('-');
  if (parts.length != 3) return matchDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return matchDate;
  return '$day ${_monthAbbr[month - 1]}';
}

class _AnalysisTab extends StatelessWidget {
  final Pick pick;
  const _AnalysisTab({required this.pick});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1F14),
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            children: [
              if (pick.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x26FF5C5C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(padding: EdgeInsets.only(right: 8), child: PulseDot()),
                      LiveMinuteText(
                        pick: pick,
                        style: AppText.style(12.5, weight: FontWeight.w800, color: AppColors.red, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  pick.liveScore != null
                      ? '${pick.league} · ${_shortDate(pick.matchDate)} · Finalizado'
                      : '${pick.league} · ${_shortDate(pick.matchDate)} · ${pick.time}',
                  textAlign: TextAlign.center,
                  style: AppText.style(
                    13,
                    weight: FontWeight.w600,
                    color: const Color(0xFFA5AFB4),
                  ),
                ),
              if (pick.venue != null) ...[
                const SizedBox(height: 4),
                Text(
                  pick.venueCity != null ? '${pick.venue} · ${pick.venueCity}' : pick.venue!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(11, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            pick.teamA,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: AppText.style(17, weight: FontWeight.w800),
                          ),
                        ),
                        Text('Local', style: AppText.style(10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TeamCrest(name: pick.teamA, size: 30, logoUrl: pick.teamALogoUrl),
                  const SizedBox(width: 14),
                  if (pick.liveScore != null)
                    Text(pick.liveScore!.replaceAll('-', ' - '), style: AppText.style(26, weight: FontWeight.w800, color: Colors.white))
                  else
                    Text('vs', style: AppText.style(14, weight: FontWeight.w700, color: AppColors.textFaint)),
                  const SizedBox(width: 14),
                  TeamCrest(name: pick.teamB, size: 30, logoUrl: pick.teamBLogoUrl),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            pick.teamB,
                            maxLines: 1,
                            style: AppText.style(17, weight: FontWeight.w800),
                          ),
                        ),
                        Text('Visitante', style: AppText.style(10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              if (pick.isLive && (pick.liveYellowA + pick.liveRedA + pick.liveYellowB + pick.liveRedB) > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CardCount(yellow: pick.liveYellowA, red: pick.liveRedA),
                    const SizedBox(width: 24),
                    _CardCount(yellow: pick.liveYellowB, red: pick.liveRedB),
                  ],
                ),
              ],
              if (pick.liveScore != null) ...[
                const SizedBox(height: 12),
                _GoalScorersRow(pick: pick),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
            children: [
              if (pick.hasNoPrediction) ...[
                Center(
                  child: Icon(Icons.help_outline_rounded, size: 72, color: AppColors.textFaint),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Sin datos suficientes todavía para predecir este cruce con confianza — no inventamos un número.',
                      textAlign: TextAlign.center,
                      style: AppText.style(13.5, weight: FontWeight.w500, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
              Center(
          child: ProbRing(
            pct: pick.prob,
            size: 156,
            strokeWidth: 11,
            fontSize: 32,
            label: null,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppText.style(
                  13.5,
                  weight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                children: [
                  const TextSpan(text: 'Probabilidad de victoria: '),
                  TextSpan(
                    text: _probabilityLabel(pick),
                    style: AppText.style(13.5, weight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
        const SizedBox(height: 26),
        _InsightPanel(
          title: 'FORMA RECIENTE',
          trailing: null,
          child: Column(
            children: [
              _RecentFormRow(name: pick.teamA, form: pick.formA),
              const SizedBox(height: 18),
              _RecentFormRow(name: pick.teamB, form: pick.formB),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'ANÁLISIS IA',
          trailing: _GhostAiButton(
            icon: Icons.refresh_rounded,
            label: 'Actualizar IA',
            onTap: () {},
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._insightParagraphs(pick).expand(
                (p) => [
                  Text(
                    p,
                    style: AppText.style(15, color: const Color(0xFFE1E7E3), weight: FontWeight.w500, height: 1.55),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 1,
                color: AppColors.green.withValues(alpha: 0.14),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => DefaultTabController.of(context).animateTo(1),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13C57A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF13C57A).withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.black,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Preguntar a la IA sobre este partido',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(
                            14.5,
                            weight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
            ],
          ),
        ),
      ],
    );
  }

  String _probabilityLabel(Pick pick) {
    if (pick.market0ProbHome != null && pick.market0ProbAway != null) {
      if (pick.market0ProbHome! >= pick.market0ProbAway!) return pick.teamA;
      return pick.teamB;
    }
    // Sin desglose 1X2 (picks viejos): usa solo la parte del resultado,
    // sin el prefijo del mercado (ej. "Atlas o empate", no "Doble
    // oportunidad: Atlas o empate") para que quepa en una línea.
    final parts = pick.pick.split(':');
    return parts.length > 1 ? parts.last.trim() : pick.pick;
  }

  List<String> _insightParagraphs(Pick pick) {
    final paragraphs = [pick.analysisP1.trim(), pick.analysisP2.trim()].where((t) => t.isNotEmpty).toList();
    if (paragraphs.isNotEmpty) return paragraphs;
    return ['El modelo asigna ${pick.prob}% de confianza a ${pick.pick}, apoyado por la forma reciente, el comportamiento ofensivo y el contexto competitivo de este partido.'];
  }
}

class _InsightPanel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _InsightPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2115),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.style(
                    11.5,
                    weight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GhostAiButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostAiButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2A1D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF00E6A0)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.style(
                13,
                weight: FontWeight.w800,
                color: const Color(0xFF00E6A0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentFormRow extends StatelessWidget {
  final String name;
  final List<String> form;

  const _RecentFormRow({required this.name, required this.form});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$name:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(13, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
        ...form.take(5).map(
              (result) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _FormBadge(result: result),
              ),
            ),
      ],
    );
  }
}

class _FormBadge extends StatelessWidget {
  final String result;

  const _FormBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final bg = switch (result) {
      'W' => const Color(0xFF11A86A),
      'D' => const Color(0xFF666675),
      _ => const Color(0xFFE9004D),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      alignment: Alignment.center,
      child: Text(
        formLetterEs(result),
        style: AppText.style(13, weight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  static const _dark = Color(0xFF1E4526);
  static const _light = Color(0xFF255A2E);

  @override
  void paint(Canvas canvas, Size size) {
    // Franjas de "pasto cortado" — 8 bandas horizontales alternando tono.
    const stripes = 8;
    final stripeH = size.height / stripes;
    for (var i = 0; i < stripes; i++) {
      final paint = Paint()..color = i.isEven ? _light : _dark;
      canvas.drawRect(Rect.fromLTWH(0, stripeH * i, size.width, stripeH), paint);
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final w = size.width;
    final h = size.height;
    final margin = w * 0.03;
    final field = Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2);

    canvas.drawRect(field, line);
    canvas.drawLine(Offset(field.left, h / 2), Offset(field.right, h / 2), line);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.16, line);
    canvas.drawCircle(Offset(w / 2, h / 2), 2, line..style = PaintingStyle.fill);
    line.style = PaintingStyle.stroke;

    final boxW = field.width * 0.62;
    final sixYardW = field.width * 0.32;

    // Área grande + chica, arriba.
    canvas.drawRect(Rect.fromLTWH(field.left + (field.width - boxW) / 2, field.top, boxW, h * 0.15), line);
    canvas.drawRect(Rect.fromLTWH(field.left + (field.width - sixYardW) / 2, field.top, sixYardW, h * 0.06), line);
    // Medio círculo exacto (0 a π): el centro está sobre la línea del área,
    // así los dos extremos del arco quedan pegados a esa línea sin flotar.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w / 2, field.top + h * 0.15), radius: w * 0.14),
      0,
      3.14159,
      false,
      line,
    );

    // Área grande + chica, abajo.
    canvas.drawRect(Rect.fromLTWH(field.left + (field.width - boxW) / 2, field.bottom - h * 0.15, boxW, h * 0.15), line);
    canvas.drawRect(Rect.fromLTWH(field.left + (field.width - sixYardW) / 2, field.bottom - h * 0.06, sixYardW, h * 0.06), line);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w / 2, field.bottom - h * 0.15), radius: w * 0.14),
      3.14159,
      3.14159,
      false,
      line,
    );

    // Arcos de esquina — solo el cuarto de círculo que cae dentro de la cancha.
    final cornerR = w * 0.04;
    const halfPi = 1.5708;
    final corners = [
      (field.topLeft, 0.0),
      (field.topRight, halfPi),
      (field.bottomRight, 2 * halfPi),
      (field.bottomLeft, 3 * halfPi),
    ];
    for (final (center, startAngle) in corners) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: cornerR), startAngle, halfPi, false, line);
    }
  }

  @override
  bool shouldRepaint(covariant _PitchLinesPainter oldDelegate) => false;
}

class _PitchLineup extends StatelessWidget {
  final RealTeamLineup lineup;
  const _PitchLineup({required this.lineup});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            lineup.formation,
            style: AppText.style(20, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 0.68,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E4526),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _PitchLinesPainter()),
                  ),
                  Column(
                    children: lineup.rows
                        .map(
                          (row) => Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: row
                                  .map((p) => _PlayerDot(player: p))
                                  .toList(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerDot extends StatelessWidget {
  final RealLineupPlayer player;
  const _PlayerDot({required this.player});

  bool get _isPlaceholder => player.id == 0 && player.number == 0 && player.name.isEmpty;

  @override
  Widget build(BuildContext context) {
    final placeholder = _isPlaceholder;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  child: placeholder
                      ? const Icon(Icons.person_rounded, size: 22, color: Colors.black38)
                      : CachedNetworkImage(
                          imageUrl: player.photoUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person_rounded,
                            size: 22,
                            color: Colors.black38,
                          ),
                        ),
                ),
              ),
              if (!placeholder)
                Positioned(
                  bottom: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E4526),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Text(
                      '${player.number}',
                      style: AppText.style(9.5, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!placeholder)
          Text(
            player.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(
              9.5,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
      ],
    );
  }
}

class _LineupTab extends StatefulWidget {
  final Pick pick;
  const _LineupTab({required this.pick});

  @override
  State<_LineupTab> createState() => _LineupTabState();
}

class _LineupTabState extends State<_LineupTab> {
  bool showTeamA = true;
  List<RealTeamLineup>? _lineups;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lineups = await LineupService.instance.fetchLineups(widget.pick.id);
      if (mounted) setState(() => _lineups = lineups);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return NetworkErrorView(
        onRetry: () {
          setState(() => _error = false);
          _load();
        },
      );
    }

    if (_lineups == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    final hasLineups = _lineups!.length >= 2;
    final lineupA = hasLineups
        ? _lineups!.firstWhere((l) => l.team == widget.pick.teamA, orElse: () => _lineups![0])
        : _placeholderLineup(widget.pick.teamA);
    final lineupB = hasLineups
        ? _lineups!.firstWhere((l) => l.team == widget.pick.teamB, orElse: () => _lineups![1])
        : _placeholderLineup(widget.pick.teamB);
    final active = showTeamA ? lineupA : lineupB;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        if (!hasLineups) ...[
          Text(
            'Alineación aún no confirmada — formación estimada.',
            textAlign: TextAlign.center,
            style: AppText.style(11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
        ],
        _PitchLineup(lineup: active),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TeamSwitchChip(
                label: lineupA.team,
                active: showTeamA,
                onTap: () => setState(() => showTeamA = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TeamSwitchChip(
                label: lineupB.team,
                active: !showTeamA,
                onTap: () => setState(() => showTeamA = false),
              ),
            ),
          ],
        ),
        if (hasLineups) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 40,
                    height: 40,
                    color: AppColors.cardBorder,
                    child: active.coachPhotoUrl == null
                        ? const Icon(
                            Icons.sports_rounded,
                            size: 20,
                            color: Colors.white70,
                          )
                        : CachedNetworkImage(
                            imageUrl: active.coachPhotoUrl!,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            errorWidget: (context, url, error) =>
                                const Icon(
                                  Icons.sports_rounded,
                                  size: 20,
                                  color: Colors.white70,
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.coach,
                      style: AppText.style(13, weight: FontWeight.w600),
                    ),
                    Text(
                      'Entrenador · ${active.formation}',
                      style: AppText.style(11, color: AppColors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (active.substitutes.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'SUPLENTES',
            style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in _groupByPosition(active.substitutes)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 2),
                    child: Text(
                      group.$1,
                      style: AppText.style(10.5, weight: FontWeight.w700, color: AppColors.blue, letterSpacing: 0.3),
                    ),
                  ),
                  ...group.$2.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Container(
                                width: 34,
                                height: 34,
                                color: AppColors.cardBorder,
                                child: CachedNetworkImage(
                                  imageUrl: p.photoUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration: Duration.zero,
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${p.number}',
                                style: AppText.style(12, weight: FontWeight.w700, color: AppColors.textMuted),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.style(13, weight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
        if (active.injuries.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'BAJAS CONFIRMADAS',
            style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: active.injuries
                  .map((inj) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.local_hospital_rounded, size: 16, color: AppColors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(inj.name, style: AppText.style(12.5, weight: FontWeight.w600)),
                            ),
                            Text(inj.reason, style: AppText.style(11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// Agrupa suplentes por posición (G/D/M/F que manda la API) en el orden
// habitual portero → defensa → medio → delantero.
const _posOrder = ['G', 'D', 'M', 'F'];
const _posLabels = {'G': 'PORTEROS', 'D': 'DEFENSAS', 'M': 'MEDIOCAMPISTAS', 'F': 'DELANTEROS'};

List<(String, List<RealLineupPlayer>)> _groupByPosition(List<RealLineupPlayer> players) {
  final byPos = <String, List<RealLineupPlayer>>{};
  for (final p in players) {
    byPos.putIfAbsent(p.pos, () => []).add(p);
  }
  final groups = <(String, List<RealLineupPlayer>)>[];
  for (final code in _posOrder) {
    final list = byPos.remove(code);
    if (list != null && list.isNotEmpty) groups.add((_posLabels[code]!, list));
  }
  for (final entry in byPos.entries) {
    if (entry.value.isNotEmpty) groups.add(('OTROS', entry.value));
  }
  return groups;
}

// Silueta genérica (4-3-3) cuando la API todavía no publicó la alineación
// real — muestra la cancha con iconos vacíos en vez de dejarla en blanco.
RealTeamLineup _placeholderLineup(String team) {
  RealLineupPlayer p() => const RealLineupPlayer(id: 0, number: 0, name: '', pos: '');
  return RealTeamLineup(
    teamId: 0,
    team: team,
    formation: '4-3-3',
    coach: '',
    coachId: null,
    rows: [
      [p()],
      List.generate(4, (_) => p()),
      List.generate(3, (_) => p()),
      List.generate(3, (_) => p()),
    ],
  );
}

class _TeamSwitchChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TeamSwitchChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.green : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.style(
            12,
            weight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: SizedBox(
          width: 20,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (i) => Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchChatTab extends StatefulWidget {
  final Pick pick;
  const _MatchChatTab({required this.pick});

  @override
  State<_MatchChatTab> createState() => _MatchChatTabState();
}

class _MatchChatTabState extends State<_MatchChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AppState>()
          .loadMatchChatHistory(widget.pick)
          .then((_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _matchFinished => widget.pick.liveScore != null && !widget.pick.isLive;

  void _send() {
    if (_matchFinished) return;
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context
        .read<AppState>()
        .sendMatchChatMessage(widget.pick, text)
        .then((_) => _scrollToBottom());
    _controller.clear();
    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    if (_matchFinished) return;
    context
        .read<AppState>()
        .sendMatchChatMessage(widget.pick, text)
        .then((_) => _scrollToBottom());
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.matchChatFor(widget.pick);
    final isLoading = state.isMatchChatLoading(widget.pick);
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Center(
                    child: Text(
                      'Pregunta lo que quieras sobre ${widget.pick.teamA} vs ${widget.pick.teamB} — la IA responde con datos reales de este partido: forma, H2H, goles, over/under, BTTS.',
                      textAlign: TextAlign.center,
                      style: AppText.style(
                        12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i >= messages.length) {
                      return const _TypingBubble();
                    }
                    final isLast = i == messages.length - 1 && !isLoading;
                    return ChatBubble(
                      message: messages[i],
                      onSuggestionTap: isLast && !_matchFinished ? _sendSuggestion : null,
                    );
                  },
                ),
        ),
        ChatInputBar(
          controller: _controller,
          onSend: _send,
          enabled: !_matchFinished,
          hint: _matchFinished ? 'El partido ya terminó — chat cerrado' : 'Pregunta sobre este partido...',
        ),
      ],
    );
  }
}

class _StatRowBar extends StatelessWidget {
  final MatchStatRow stat;
  const _StatRowBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.valueA,
                style: AppText.style(
                  22,
                  weight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              Text(
                stat.label,
                style: AppText.style(14, color: AppColors.textMuted, weight: FontWeight.w600),
              ),
              Text(
                stat.valueB,
                style: AppText.style(
                  22,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (stat.fractionA * 100).round().clamp(1, 99),
                  child: Container(height: 9, color: AppColors.green),
                ),
                Expanded(
                  flex: (100 - (stat.fractionA * 100).round()).clamp(1, 99),
                  child: Container(height: 9, color: AppColors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsTab extends StatefulWidget {
  final Pick pick;
  const _EventsTab({required this.pick});

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  List<MatchEvent>? _events;
  bool _error = false;
  Timer? _liveRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    // en vivo, los eventos cambian partido a partido — se refresca solo,
    // sin que el usuario tenga que salir y volver a entrar a la pestaña.
    if (widget.pick.isLive) {
      _liveRefresh = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
    }
  }

  @override
  void dispose() {
    _liveRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _error = false);
    try {
      final events = await EventsService.instance.fetchEvents(widget.pick.id);
      if (mounted) setState(() => _events = events);
    } catch (_) {
      if (mounted && !silent) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;

    if (_error) {
      return NetworkErrorView(onRetry: () => _load());
    }

    if (_events == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (_events!.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline_rounded,
        title: 'Sin eventos todavía',
        message: 'Los goles y tarjetas del partido van a aparecer aquí en cuanto arranque.',
      );
    }

    // más reciente arriba — lo más relevante en un partido en vivo es lo
    // que acaba de pasar, no lo que pasó hace una hora.
    final events = [...(_events!)]..sort((a, b) {
        final aTotal = a.minute * 100 + (a.extraMinute ?? 0);
        final bTotal = b.minute * 100 + (b.extraMinute ?? 0);
        return bTotal.compareTo(aTotal);
      });

    Widget iconFor(MatchEvent e) {
      if (e.isGoal) return const Icon(Icons.sports_soccer_rounded, size: 18, color: AppColors.green);
      if (e.isRedCard) return Container(width: 12, height: 16, color: AppColors.red);
      return Container(width: 12, height: 16, color: const Color(0xFFE8C13B));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = events[i];
        final isTeamA = e.teamId == pick.teamAId;
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  e.minuteLabel,
                  style: AppText.style(13, weight: FontWeight.w800, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 4),
              iconFor(e),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.isGoal ? '¡Gol! ${e.player}' : '${e.player} — ${e.isRedCard ? "tarjeta roja" : "tarjeta amarilla"}',
                      style: AppText.style(13, weight: FontWeight.w700),
                    ),
                    if (e.assist != null) ...[
                      const SizedBox(height: 2),
                      Text('Asistencia: ${e.assist}', style: AppText.style(11.5, color: AppColors.textMuted)),
                    ],
                    const SizedBox(height: 2),
                    Text(e.team, style: AppText.style(11.5, color: isTeamA ? AppColors.green : AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsTab extends StatefulWidget {
  final Pick pick;
  const _StatsTab({required this.pick});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

// Mismas 7 filas que devuelve el backend (app/routes/stats.py), en 0 —
// se muestran cuando el partido aún no arranca y la API no tiene datos.
final _placeholderStatRows = [
  const MatchStatRow(label: 'Posesión de balón', valueA: '0%', valueB: '0%', fractionA: 0),
  const MatchStatRow(label: 'Tiros totales', valueA: '0', valueB: '0', fractionA: 0.5),
  const MatchStatRow(label: 'Tiros a puerta', valueA: '0', valueB: '0', fractionA: 0.5),
  const MatchStatRow(label: 'Precisión de pases', valueA: '0%', valueB: '0%', fractionA: 0),
  const MatchStatRow(label: 'Faltas', valueA: '0', valueB: '0', fractionA: 0.5),
  const MatchStatRow(label: 'Tarjetas amarillas', valueA: '0', valueB: '0', fractionA: 0.5),
  const MatchStatRow(label: 'Saques de esquina', valueA: '0', valueB: '0', fractionA: 0.5),
];

class _StatsTabState extends State<_StatsTab> {
  List<MatchStatRow>? _stats;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final stats = await StatsService.instance.fetchStats(widget.pick.id);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;

    if (_error) {
      return NetworkErrorView(onRetry: _load);
    }

    if (_stats == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    final rows = _stats!.isNotEmpty ? _stats! : _placeholderStatRows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  TeamCrest(name: pick.teamA, size: 40, logoUrl: pick.teamALogoUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pick.teamA, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(14, weight: FontWeight.w700)),
                        Text('Local', style: AppText.style(11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(pick.teamB, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(14, weight: FontWeight.w700)),
                      Text('Visitante', style: AppText.style(11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  TeamCrest(name: pick.teamB, size: 40, logoUrl: pick.teamBLogoUrl),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 14),
              ...rows.map((s) => _StatRowBar(stat: s)),
            ],
          ),
        ),
      ],
    );
  }
}

// Máximo de mercados premium bloqueados que se muestran de entrada — el
// resto queda resumido en una sola tarjeta "+N mercados más", para no
// saturar la pantalla con puras tarjetas difuminadas.
const _kMaxLockedPreviews = 2;

class _MarketsTab extends StatelessWidget {
  final Pick pick;
  const _MarketsTab({required this.pick});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matchPicks = state.picksForMatch(pick.teamA, pick.teamB, pick.time);
    final isPremiumUser = !matchPicks.any((p) => state.isLocked(p));

    final free = matchPicks.where((p) => !p.premium).toList();
    final premium = matchPicks.where((p) => p.premium).toList()
      ..sort((a, b) {
        final byConfidence = a.confidence.index.compareTo(b.confidence.index);
        if (byConfidence != 0) return byConfidence;
        return b.prob.compareTo(a.prob);
      });

    // Con Premium ya pagado no tiene caso resumir nada — se ven todos.
    final shownPremium = isPremiumUser ? premium : premium.take(_kMaxLockedPreviews).toList();
    final hiddenCount = premium.length - shownPremium.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text(
          'TODOS LOS MERCADOS DEL PARTIDO',
          style: AppText.style(
            12,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        ...[...free, ...shownPremium].map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PickCard(
                  pick: p,
                  locked: state.isLocked(p),
                  onOpen: () => context.read<AppState>().openDetail(p.id),
                  onUnlock: () => context.read<AppState>().go(AppScreen.paywall),
                  revealFreePick: true,
                ),
                if (p.id.endsWith('-0') && p.market0ProbHome != null && !state.isLocked(p)) ...[
                  const SizedBox(height: 8),
                  _ProbBreakdownBar(pick: p),
                ],
              ],
            ),
          ),
        ),
        if (hiddenCount > 0)
          GestureDetector(
            onTap: () => context.read<AppState>().go(AppScreen.paywall),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.yellow),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '+$hiddenCount mercado${hiddenCount == 1 ? '' : 's'} más con Premium',
                      style: AppText.style(13, weight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        if (isPremiumUser && pick.fixtureId != null) ...[
          const SizedBox(height: 20),
          _PlayerPropsSection(fixtureId: pick.fixtureId!),
        ],
      ],
    );
  }
}

class _PlayerPropsSection extends StatefulWidget {
  final int fixtureId;
  const _PlayerPropsSection({required this.fixtureId});

  @override
  State<_PlayerPropsSection> createState() => _PlayerPropsSectionState();
}

class _PlayerPropsSectionState extends State<_PlayerPropsSection> {
  List<PlayerPropPick>? _props;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final props = await PlayerPropsService.instance.fetchForFixture(widget.fixtureId);
      if (mounted) setState(() => _props = props);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Color _barColor(int pct) {
    if (pct >= 60) return AppColors.green;
    if (pct >= 45) return const Color(0xFFE0A72E);
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Silencioso si falla o no hay nada — la alineación puede no estar
    // confirmada todavía, eso es lo normal, no un error que mostrar.
    if (_error || (_props != null && _props!.isEmpty)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIROS AL ARCO POR JUGADOR',
          style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4),
        ),
        const SizedBox(height: 4),
        Text(
          'Solo titulares con alineación ya confirmada — muestra chica, confianza siempre baja.',
          style: AppText.style(11, color: AppColors.textFaint, height: 1.4),
        ),
        const SizedBox(height: 10),
        if (_props == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)),
          )
        else
          ..._props!.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.playerName, style: AppText.style(13, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(p.pick, style: AppText.style(12, color: AppColors.textBody)),
                            const SizedBox(height: 2),
                            Text('Muestra: ${p.sampleMatches} partidos',
                                style: AppText.style(10, color: AppColors.textFaint)),
                          ],
                        ),
                      ),
                      Text('${p.displayPct}%',
                          style: AppText.style(16, weight: FontWeight.w800, color: _barColor(p.displayPct))),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

/// Nombre de ronda tal cual lo da la API -> etiqueta en español. Lo que no
/// esté aquí se muestra tal cual (mejor una ronda en inglés que nada).
String _roundLabel(String round) {
  const known = {
    'round of 32': 'Dieciseisavos de final',
    'round of 16': 'Octavos de final',
    'quarter-finals': 'Cuartos de final',
    'quarterfinals': 'Cuartos de final',
    'semi-finals': 'Semifinales',
    'semifinals': 'Semifinales',
    'final': 'Final',
    'play-offs': 'Playoffs',
    'playoffs': 'Playoffs',
    '3rd place final': 'Tercer lugar',
  };
  return known[round.toLowerCase()] ?? round;
}

class _StandingsTab extends StatefulWidget {
  final Pick pick;
  const _StandingsTab({required this.pick});

  @override
  State<_StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends State<_StandingsTab> {
  List<StandingRow>? _rows;
  List<BracketRound> _bracket = [];
  bool _error = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final highlight = {widget.pick.teamA, widget.pick.teamB};
    try {
      final rows = await StandingsService.instance.fetchStandings(widget.pick.league, highlightTeams: highlight);
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _error = true);
      return;
    }
    // el bracket es secundario — si falla, se queda vacío y solo se oculta
    // la pestaña, no se rompe la tabla de posiciones que ya cargó bien
    try {
      final bracket = await StandingsService.instance.fetchBracket(widget.pick.league, highlightTeams: highlight);
      if (mounted) setState(() => _bracket = bracket);
    } catch (_) {
      // silencioso a propósito
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;

    if (_error) {
      return NetworkErrorView(
        onRetry: () {
          setState(() => _error = false);
          _load();
        },
      );
    }

    if (_rows == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    final rows = _rows!;
    final hasTable = rows.isNotEmpty;
    // fase de grupos: round-robin, no elimina 1-a-1 — no tiene "padres" que
    // conectar con líneas (y torneos como Leagues Cup ni siquiera publican
    // tabla de posiciones para ella), así que es su PROPIA pestaña, no un
    // bloque más dentro de "Eliminatorias" (si no, hay que hacer scroll por
    // decenas de partidos de grupo solo para llegar al bracket real).
    final hasGroupStage = _bracket.isNotEmpty && _bracket.first.round.toLowerCase() == 'group stage';
    final groupMatches = hasGroupStage ? _bracket.first.matches : const <BracketMatch>[];
    final knockoutRounds = hasGroupStage ? _bracket.sublist(1) : _bracket;

    if (!hasTable && groupMatches.isEmpty && knockoutRounds.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'Sin clasificación disponible',
        message: 'Todavía no tenemos la tabla de posiciones para esta liga.',
      );
    }

    final sections = <(String, Widget)>[
      if (hasTable) ('General', _StandingsTable(rows: rows)),
      if (groupMatches.isNotEmpty) ('Fase de grupos', _GroupStageList(matches: groupMatches)),
      if (knockoutRounds.isNotEmpty) ('Eliminatorias', _BracketTree(rounds: knockoutRounds)),
    ];
    final selected = _selectedTab.clamp(0, sections.length - 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text(
          pick.league.toUpperCase(),
          style: AppText.style(
            12,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        if (sections.length > 1) ...[
          _StandingsSubTabs(
            labels: [for (final s in sections) s.$1],
            selected: selected,
            onChanged: (i) => setState(() => _selectedTab = i),
          ),
          const SizedBox(height: 14),
        ],
        sections[selected].$2,
      ],
    );
  }
}

class _StandingsSubTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _StandingsSubTabs({required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, bool isSelected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(
                12.5,
                weight: FontWeight.w700,
                color: isSelected ? Colors.black : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) pill(labels[i], i == selected, () => onChanged(i)),
        ],
      ),
    );
  }
}

class _GroupStageList extends StatelessWidget {
  final List<BracketMatch> matches;
  const _GroupStageList({required this.matches});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in matches) ...[
          _BracketCard(match: m),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<StandingRow> rows;
  const _StandingsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '#',
                        style: AppText.style(11, color: AppColors.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Equipo',
                        style: AppText.style(11, color: AppColors.textMuted),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        'PJ',
                        textAlign: TextAlign.right,
                        style: AppText.style(11, color: AppColors.textMuted),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        'DG',
                        textAlign: TextAlign.right,
                        style: AppText.style(11, color: AppColors.textMuted),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        'Pts',
                        textAlign: TextAlign.right,
                        style: AppText.style(11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 1),
              ...rows.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${r.pos}',
                          style: AppText.style(
                            12.5,
                            weight: FontWeight.w600,
                            color: r.highlighted
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.team,
                          style: AppText.style(
                            12.5,
                            weight: r.highlighted
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: r.highlighted
                                ? Colors.white
                                : AppColors.textBody,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${r.played}',
                          textAlign: TextAlign.right,
                          style: AppText.style(12.5, color: AppColors.textBody),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          r.goalDiff >= 0 ? '+${r.goalDiff}' : '${r.goalDiff}',
                          textAlign: TextAlign.right,
                          style: AppText.style(
                            12.5,
                            weight: FontWeight.w600,
                            color: r.goalDiff >= 0
                                ? AppColors.green
                                : AppColors.red,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${r.points}',
                          textAlign: TextAlign.right,
                          style: AppText.style(12.5, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

// Árbol de eliminatorias clásico: una columna por ronda, líneas conectando
// cada par de partidos de una ronda con el partido de la siguiente. El
// alto de cada "slot" se duplica por ronda (fórmula estándar de bracket) —
// así el partido de semis queda centrado exactamente entre sus 2 cuartos.
const double _kBracketCardWidth = 208;
const double _kBracketCardHeight = 78;
const double _kBracketColumnGap = 44;
const double _kBracketBaseSlot = 96;
const double _kBracketColumnWidth = _kBracketCardWidth + _kBracketColumnGap;

/// La API devuelve los partidos de una ronda en orden de fixture (fecha/id),
/// NO en orden de cruce — no dice qué cuarto de final alimenta qué semifinal.
/// Lo reconstruimos por identidad real: el equipo que gana un cruce
/// reaparece con el mismo nombre en la siguiente ronda, así que cada
/// partido "hijo" revela cuáles son sus 2 partidos "padre". Reordenamos las
/// rondas anteriores para que cada par de padres quede adyacente a su hijo
/// — sin esto, las líneas del bracket conectarían partidos que en la
/// realidad no tienen relación.
List<List<BracketMatch>> _reorderForBracket(List<BracketRound> rounds) {
  final byRound = [for (final r in rounds) List<BracketMatch>.from(r.matches)];
  for (var r = byRound.length - 2; r >= 0; r--) {
    final prev = byRound[r];
    final next = byRound[r + 1];
    final used = <int>{};
    final reordered = <BracketMatch>[];
    for (final child in next) {
      for (var i = 0; i < prev.length; i++) {
        if (used.contains(i)) continue;
        final pm = prev[i];
        final feedsChild = pm.teamHome == child.teamHome ||
            pm.teamAway == child.teamHome ||
            pm.teamHome == child.teamAway ||
            pm.teamAway == child.teamAway;
        if (feedsChild) {
          used.add(i);
          reordered.add(pm);
        }
      }
    }
    // partidos que no matchearon con ningún hijo (nombre distinto, dato
    // incompleto) van al final — sin conector, pero sin inventar nada
    for (var i = 0; i < prev.length; i++) {
      if (!used.contains(i)) reordered.add(prev[i]);
    }
    byRound[r] = reordered;
  }
  return byRound;
}

class _BracketTree extends StatelessWidget {
  final List<BracketRound> rounds;
  const _BracketTree({required this.rounds});

  double _centerY(int roundIndex, int matchIndex) {
    final slot = _kBracketBaseSlot * (1 << roundIndex);
    return slot * (matchIndex + 0.5);
  }

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) return const SizedBox.shrink();
    final ordered = _reorderForBracket(rounds);
    final roundLabels = [for (final r in rounds) _roundLabel(r.round)];

    // si la última ronda conocida ya tiene solo 2 partidos, lo único que
    // falta es la Final — la API no la publica hasta tener finalistas
    // definidos, así que se completa con un placeholder en vez de dejar
    // el bracket cortado a la mitad
    if (ordered.last.length == 2) {
      ordered.add(const [
        BracketMatch(
          teamHome: 'Por definir',
          teamAway: 'Por definir',
          teamHomeId: null,
          teamAwayId: null,
          goalsHome: null,
          goalsAway: null,
          status: null,
          date: null,
          isPlaceholder: true,
        ),
      ]);
      roundLabels.add('Final');
    }

    final firstRoundCount = ordered.first.length;
    final totalHeight = _kBracketBaseSlot * firstRoundCount;
    final totalWidth = ordered.length * _kBracketColumnWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final label in roundLabels)
                  SizedBox(
                    width: _kBracketColumnWidth,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppText.style(12, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _BracketConnectorPainter(rounds: ordered, centerY: _centerY)),
                  ),
                  for (var r = 0; r < ordered.length; r++)
                    for (var m = 0; m < ordered[r].length; m++)
                      Positioned(
                        left: r * _kBracketColumnWidth,
                        top: _centerY(r, m) - _kBracketCardHeight / 2,
                        width: _kBracketCardWidth,
                        height: _kBracketCardHeight,
                        child: _BracketCard(match: ordered[r][m]),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketConnectorPainter extends CustomPainter {
  final List<List<BracketMatch>> rounds;
  final double Function(int roundIndex, int matchIndex) centerY;
  _BracketConnectorPainter({required this.rounds, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var r = 1; r < rounds.length; r++) {
      final feederRight = (r - 1) * _kBracketColumnWidth + _kBracketCardWidth;
      final targetLeft = r * _kBracketColumnWidth;
      final midX = feederRight + _kBracketColumnGap / 2;

      for (var m = 0; m < rounds[r].length; m++) {
        final feederA = 2 * m;
        final feederB = 2 * m + 1;
        if (feederB >= rounds[r - 1].length) continue; // sin par completo (bye) — no se dibuja
        final yA = centerY(r - 1, feederA);
        final yB = centerY(r - 1, feederB);
        final yTarget = centerY(r, m);

        final path = Path()
          ..moveTo(feederRight, yA)
          ..lineTo(midX, yA)
          ..moveTo(feederRight, yB)
          ..lineTo(midX, yB)
          ..moveTo(midX, yA)
          ..lineTo(midX, yB)
          ..moveTo(midX, yTarget)
          ..lineTo(targetLeft, yTarget);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) => oldDelegate.rounds != rounds;
}

class _BracketCard extends StatelessWidget {
  final BracketMatch match;
  const _BracketCard({required this.match});

  Widget _placeholderRow() {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(color: Color(0xFF3A4048), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Text('?', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Text('Por definir', style: AppText.style(12, weight: FontWeight.w500, color: AppColors.textFaint)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: match.highlighted ? AppColors.green : AppColors.cardBorder),
    );

    if (match.isPlaceholder) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: decoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_placeholderRow(), const SizedBox(height: 6), _placeholderRow()],
        ),
      );
    }

    final homeWins = match.isFinished && (match.goalsHome ?? 0) > (match.goalsAway ?? 0);
    final awayWins = match.isFinished && (match.goalsAway ?? 0) > (match.goalsHome ?? 0);

    Widget teamRow(String name, String? logoUrl, int? goals, bool wins) {
      return Row(
        children: [
          TeamCrest(name: name, logoUrl: logoUrl, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(
                12,
                weight: wins ? FontWeight.w700 : FontWeight.w500,
                color: wins ? Colors.white : AppColors.textBody,
              ),
            ),
          ),
          Text(
            match.isFinished ? '${goals ?? 0}' : '',
            style: AppText.style(12.5, weight: FontWeight.w800, color: wins ? AppColors.green : AppColors.textMuted),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (match.date != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                match.time != null ? '${_shortDate(match.date)} · ${match.time}' : _shortDate(match.date),
                style: AppText.style(9.5, weight: FontWeight.w600, color: AppColors.textFaint),
              ),
            ),
          teamRow(match.teamHome, match.teamHomeLogoUrl, match.goalsHome, homeWins),
          const SizedBox(height: 5),
          teamRow(match.teamAway, match.teamAwayLogoUrl, match.goalsAway, awayWins),
        ],
      ),
    );
  }
}
