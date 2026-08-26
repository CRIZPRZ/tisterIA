import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pick.dart';
import '../services/lineup_service.dart';
import '../services/standings_service.dart';
import '../services/stats_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/common.dart';
import '../widgets/pick_card.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pick = state.selectedPick;
    final locked = state.isLocked(pick);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<AppState>().go(AppScreen.home),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (pick.isLive)
                    LiveBadge(minute: pick.liveMinute)
                  else
                    Text(
                      '${pick.league.toUpperCase()} · ${pick.time}',
                      style: AppText.style(10.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  const Spacer(),
                  if (pick.isLive && pick.liveScore != null)
                    Text(pick.liveScore!, style: AppText.style(16, weight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Column(
                    children: [
                      TeamCrest(name: pick.teamA, size: 40, logoUrl: pick.teamALogoUrl),
                      const SizedBox(height: 8),
                      TeamCrest(name: pick.teamB, size: 40, logoUrl: pick.teamBLogoUrl),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pick.teamA, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(15, weight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 14),
                        Text(pick.teamB, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(15, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                  if (!locked)
                    Text('${pick.prob}%', style: AppText.style(28, weight: FontWeight.w800, color: AppColors.green)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: locked ? const _LockedBody() : _UnlockedTabs(pick: pick),
        ),
      ],
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
          Text('Pick premium bloqueado', style: AppText.style(15, weight: FontWeight.w600)),
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
  const _UnlockedTabs({required this.pick});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Container(
            color: AppColors.card,
            child: Stack(
              children: [
                TabBar(
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.green,
                  labelStyle: AppText.style(12.5, weight: FontWeight.w600),
                  unselectedLabelStyle: AppText.style(12.5, weight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Análisis IA'),
                    Tab(text: 'Chat IA'),
                    Tab(text: 'Mercados'),
                    Tab(text: 'Estadísticas'),
                    Tab(text: 'Alineación'),
                    Tab(text: 'Clasificación'),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.card.withValues(alpha: 0), AppColors.card],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AnalysisTab(pick: pick),
                _MatchChatTab(pick: pick),
                _MarketsTab(pick: pick),
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

class _OutcomeBar extends StatelessWidget {
  final String label;
  final int pct;
  const _OutcomeBar({required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.style(12.5, weight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text('$pct%', textAlign: TextAlign.right, style: AppText.style(12.5, weight: FontWeight.w700, color: AppColors.green)),
        ),
      ],
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final Pick pick;
  const _AnalysisTab({required this.pick});

  @override
  Widget build(BuildContext context) {
    final cColor = confColor(pick.confidence);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProbRing(pct: pick.prob, size: 128, strokeWidth: 10, color: cColor, fontSize: 30),
              const SizedBox(height: 12),
              Text(pick.pick, style: AppText.style(15, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Pill(label: confLabel(pick.confidence), color: cColor, uppercase: true),
            ],
          ),
        ),
        if (pick.probHome != null && pick.probDraw != null && pick.probAway != null) ...[
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROBABILIDAD 1X2',
                    style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                const SizedBox(height: 14),
                _OutcomeBar(label: pick.teamA, pct: pick.probHome!),
                const SizedBox(height: 10),
                _OutcomeBar(label: 'Empate', pct: pick.probDraw!),
                const SizedBox(height: 10),
                _OutcomeBar(label: pick.teamB, pct: pick.probAway!),
              ],
            ),
          ),
        ],
        if (goalsLineLabel(pick.goalsLine) != null) ...[
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LÍNEA DE GOLES SUGERIDA',
                        style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                    Text('según API-Football', style: AppText.style(10, color: AppColors.textFaint)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(goalsLineLabel(pick.goalsLine)!, style: AppText.style(15, weight: FontWeight.w700)),
                if (goalsLineLabel(pick.goalsExpectedHome) != null || goalsLineLabel(pick.goalsExpectedAway) != null) ...[
                  const SizedBox(height: 10),
                  if (goalsLineLabel(pick.goalsExpectedHome) != null)
                    Text('${pick.teamA}: ${goalsLineLabel(pick.goalsExpectedHome)}', style: AppText.style(12, color: AppColors.textMuted)),
                  if (goalsLineLabel(pick.goalsExpectedAway) != null)
                    Text('${pick.teamB}: ${goalsLineLabel(pick.goalsExpectedAway)}', style: AppText.style(12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('FORMA RECIENTE',
            style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FormColumn(name: pick.teamA, form: pick.formA),
            _FormColumn(name: pick.teamB, form: pick.formB),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HEAD TO HEAD (ÚLTIMOS 5)',
                  style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              Text(pick.h2h, style: AppText.style(13, weight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.blue),
            const SizedBox(width: 6),
            Text('ANÁLISIS IA',
                style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
          ],
        ),
        const SizedBox(height: 10),
        Text(pick.analysisP1, style: AppText.style(13, color: AppColors.textBody, height: 1.65)),
        const SizedBox(height: 10),
        Text(pick.analysisP2, style: AppText.style(13, color: AppColors.textBody, height: 1.65)),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PRECISIÓN DEL MODELO',
                      style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
                  Text('${pick.modelAccuracy}%',
                      style: AppText.style(13, weight: FontWeight.w700, color: AppColors.green)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pick.modelAccuracy / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                ),
              ),
              const SizedBox(height: 8),
              Text('Aciertos en picks de este tipo, últimos 90 días',
                  style: AppText.style(11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), line);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.15), size.width * 0.16, line);
    final boxW = size.width * 0.5;
    canvas.drawRect(Rect.fromLTWH((size.width - boxW) / 2, 0, boxW, size.height * 0.12), line);
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
        Row(
          children: [
            ClipOval(
              child: Container(
                width: 28,
                height: 28,
                color: AppColors.cardBorder,
                child: Image.network(
                  lineup.logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      lineup.team.isNotEmpty ? lineup.team[0] : '?',
                      style: AppText.style(12, weight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(lineup.team, style: AppText.style(14, weight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 4),
        Text(lineup.formation, style: AppText.style(11.5, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 0.68,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFF0d1710)),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _PitchLinesPainter())),
                  Column(
                    children: lineup.rows
                        .map((row) => Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: row.map((p) => _PlayerDot(player: p)).toList(),
                              ),
                            ))
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2E32),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: Image.network(
              player.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 20, color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${player.number} ${player.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.style(9.5, weight: FontWeight.w600, color: Colors.white),
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
      return NetworkErrorView(onRetry: () {
        setState(() => _error = false);
        _load();
      });
    }

    if (_lineups == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (_lineups!.length < 2) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'Alineación no disponible',
        message: 'Todavía no se publica la alineación probable de este partido.',
      );
    }

    final lineupA = _lineups!.firstWhere((l) => l.team == widget.pick.teamA, orElse: () => _lineups![0]);
    final lineupB = _lineups!.firstWhere((l) => l.team == widget.pick.teamB, orElse: () => _lineups![1]);
    final active = showTeamA ? lineupA : lineupB;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text('ALINEACIÓN PROBABLE',
            style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _TeamSwitchChip(label: lineupA.team, active: showTeamA, onTap: () => setState(() => showTeamA = true))),
            const SizedBox(width: 8),
            Expanded(child: _TeamSwitchChip(label: lineupB.team, active: !showTeamA, onTap: () => setState(() => showTeamA = false))),
          ],
        ),
        const SizedBox(height: 14),
        _PitchLineup(lineup: active),
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
                      ? const Icon(Icons.sports_rounded, size: 20, color: Colors.white70)
                      : Image.network(
                          active.coachPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.sports_rounded, size: 20, color: Colors.white70),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active.coach, style: AppText.style(13, weight: FontWeight.w600)),
                  Text('Entrenador · ${active.formation}', style: AppText.style(11, color: AppColors.blue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamSwitchChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TeamSwitchChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.green : AppColors.cardBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.style(12, weight: FontWeight.w600, color: active ? Colors.white : AppColors.textMuted),
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
              (i) => Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
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
      context.read<AppState>().loadMatchChatHistory(widget.pick).then((_) => _scrollToBottom());
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

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<AppState>().sendMatchChatMessage(widget.pick, text).then((_) => _scrollToBottom());
    _controller.clear();
    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    context.read<AppState>().sendMatchChatMessage(widget.pick, text).then((_) => _scrollToBottom());
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
                      style: AppText.style(12.5, color: AppColors.textMuted, height: 1.5),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i >= messages.length) {
                      return const _TypingBubble();
                    }
                    final isLast = i == messages.length - 1 && !isLoading;
                    return ChatBubble(message: messages[i], onSuggestionTap: isLast ? _sendSuggestion : null);
                  },
                ),
        ),
        ChatInputBar(
          controller: _controller,
          onSend: _send,
          hint: 'Pregunta sobre este partido...',
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stat.valueA, style: AppText.style(13, weight: FontWeight.w700, color: AppColors.green)),
              Text(stat.label, style: AppText.style(11.5, color: AppColors.textMuted)),
              Text(stat.valueB, style: AppText.style(13, weight: FontWeight.w700, color: AppColors.blue)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                Expanded(
                  flex: (stat.fractionA * 100).round().clamp(1, 99),
                  child: Container(height: 6, color: AppColors.green),
                ),
                Expanded(
                  flex: (100 - (stat.fractionA * 100).round()).clamp(1, 99),
                  child: Container(height: 6, color: AppColors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatefulWidget {
  final Pick pick;
  const _StatsTab({required this.pick});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

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
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (_stats!.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'Sin estadísticas disponibles',
        message: 'Todavía no hay estadísticas para este partido — suelen publicarse cuando arranca o termina.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(pick.teamA, style: AppText.style(12, weight: FontWeight.w700, color: AppColors.green)),
            ),
            Text('RESUMEN DEL PARTIDO',
                style: AppText.style(10.5, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
            Expanded(
              child: Text(pick.teamB,
                  textAlign: TextAlign.right, style: AppText.style(12, weight: FontWeight.w700, color: AppColors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(children: _stats!.map((s) => _StatRowBar(stat: s)).toList()),
        ),
      ],
    );
  }
}

class _MarketsTab extends StatelessWidget {
  final Pick pick;
  const _MarketsTab({required this.pick});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matchPicks = state.picksForMatch(pick.teamA, pick.teamB, pick.time);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text('TODOS LOS MERCADOS DEL PARTIDO',
            style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
        const SizedBox(height: 10),
        ...matchPicks.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PickCard(
                pick: p,
                locked: state.isLocked(p),
                onOpen: () => context.read<AppState>().openDetail(p.id),
                onUnlock: () => context.read<AppState>().go(AppScreen.paywall),
                revealFreePick: true,
              ),
            )),
      ],
    );
  }
}

class _StandingsTab extends StatefulWidget {
  final Pick pick;
  const _StandingsTab({required this.pick});

  @override
  State<_StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends State<_StandingsTab> {
  List<StandingRow>? _rows;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await StandingsService.instance.fetchStandings(
        widget.pick.league,
        highlightTeams: {widget.pick.teamA, widget.pick.teamB},
      );
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;

    if (_error) {
      return NetworkErrorView(onRetry: () {
        setState(() => _error = false);
        _load();
      });
    }

    if (_rows == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (_rows!.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'Sin clasificación disponible',
        message: 'Todavía no tenemos la tabla de posiciones para esta liga.',
      );
    }

    final rows = _rows!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text(pick.league.toUpperCase(),
            style: AppText.style(12, weight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4)),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('#', style: AppText.style(11, color: AppColors.textMuted))),
                    Expanded(child: Text('Equipo', style: AppText.style(11, color: AppColors.textMuted))),
                    SizedBox(width: 32, child: Text('PJ', textAlign: TextAlign.right, style: AppText.style(11, color: AppColors.textMuted))),
                    SizedBox(width: 36, child: Text('DG', textAlign: TextAlign.right, style: AppText.style(11, color: AppColors.textMuted))),
                    SizedBox(width: 32, child: Text('Pts', textAlign: TextAlign.right, style: AppText.style(11, color: AppColors.textMuted))),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 1),
              ...rows.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text('${r.pos}', style: AppText.style(12.5, weight: FontWeight.w600, color: r.highlighted ? Colors.white : AppColors.textMuted)),
                        ),
                        Expanded(
                          child: Text(
                            r.team,
                            style: AppText.style(12.5, weight: r.highlighted ? FontWeight.w700 : FontWeight.w500, color: r.highlighted ? Colors.white : AppColors.textBody),
                          ),
                        ),
                        SizedBox(width: 32, child: Text('${r.played}', textAlign: TextAlign.right, style: AppText.style(12.5, color: AppColors.textBody))),
                        SizedBox(
                          width: 36,
                          child: Text(
                            r.goalDiff >= 0 ? '+${r.goalDiff}' : '${r.goalDiff}',
                            textAlign: TextAlign.right,
                            style: AppText.style(12.5, weight: FontWeight.w600, color: r.goalDiff >= 0 ? AppColors.green : AppColors.red),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text('${r.points}', textAlign: TextAlign.right, style: AppText.style(12.5, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}


class _FormColumn extends StatelessWidget {
  final String name;
  final List<String> form;
  const _FormColumn({required this.name, required this.form});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name, style: AppText.style(12, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: form
              .map((f) => Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(color: formBg(f), borderRadius: BorderRadius.circular(5)),
                    child: Center(
                      child: Text(formLetterEs(f), style: AppText.style(10, weight: FontWeight.w700, color: formColor(f))),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
