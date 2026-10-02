import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pick.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

DateTime? _chatKickoff(Pick pick) {
  final date = pick.matchDate?.split('-');
  final time = pick.time.split(':');
  if (date == null || date.length != 3 || time.length != 2) {
    return null;
  }
  final year = int.tryParse(date[0]);
  final month = int.tryParse(date[1]);
  final day = int.tryParse(date[2]);
  final hour = int.tryParse(time[0]);
  final minute = int.tryParse(time[1]);
  if (year == null ||
      month == null ||
      day == null ||
      hour == null ||
      minute == null) {
    return null;
  }
  return DateTime(year, month, day, hour, minute);
}

/// Es final cuando el backend ya tiene marcador, o cuando el kickoff quedó
/// suficientemente atrás como para no ofrecer un chat predictivo desfasado.
bool _chatMatchFinished(Pick pick) {
  if (pick.liveScore != null && !pick.isLive) return true;
  if (pick.isLive) return false;
  final kickoff = _chatKickoff(pick);
  return kickoff != null &&
      DateTime.now().difference(kickoff) > const Duration(hours: 3);
}

class ChatPickerScreen extends StatefulWidget {
  const ChatPickerScreen({super.key});

  @override
  State<ChatPickerScreen> createState() => _ChatPickerScreenState();
}

class _ChatPickerScreenState extends State<ChatPickerScreen> {
  String? _expandedLeague;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final picksForSelectedLeagues = state.homeLeagueFilter.isEmpty
        ? state.filteredPicks
        : state.filteredPicks
              .where(
                (pick) =>
                    pick.leagueId != null &&
                    state.homeLeagueFilter.contains(pick.leagueId),
              )
              .toList();

    // Un fixture puede tener varios mercados. Chat IA se elige por partido,
    // por lo que debe aparecer una sola vez aunque tenga varios picks.
    final matchesByFixture = <String, Pick>{};
    for (final pick in picksForSelectedLeagues) {
      matchesByFixture.putIfAbsent(
        pick.fixtureId?.toString() ?? pick.id,
        () => pick,
      );
    }
    final matches = matchesByFixture.values.toList();

    // leagueId es la llave: el nombre solo se usa para presentarlo y no
    // mezcla competiciones que puedan compartir un nombre parecido.
    final byLeague = <String, List<Pick>>{};
    for (final pick in matches) {
      final key = pick.leagueId?.toString() ?? 'name:${pick.league}';
      (byLeague[key] ??= []).add(pick);
    }
    final expandedLeague = byLeague.containsKey(_expandedLeague)
        ? _expandedLeague
        : null;
    final selectedMatches = expandedLeague == null
        ? const <Pick>[]
        : byLeague[expandedLeague] ?? const <Pick>[];
    final upcomingMatches = selectedMatches
        .where((pick) => !_chatMatchFinished(pick))
        .toList();
    final finishedMatches = selectedMatches.where(_chatMatchFinished).toList();
    final hasLeagueFilter = state.homeLeagueFilter.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Text(
            'Chat IA',
            style: AppText.style(19, weight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: matches.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: hasLeagueFilter
                        ? 'No hay encuentros para tus ligas'
                        : 'Sin partidos hoy',
                    message: hasLeagueFilter
                        ? 'Por ahora no hay picks disponibles para las ligas que seleccionaste.'
                        : 'Cuando haya picks disponibles podrás preguntarle a la IA sobre cualquier partido.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
                  children: [
                    Text(
                      hasLeagueFilter
                          ? 'Elige una de tus ligas y después un encuentro para hablar con la IA.'
                          : 'Elige una liga y después un encuentro para hablar con la IA.',
                      style: AppText.style(
                        12.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: byLeague.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final entry = byLeague.entries.elementAt(index);
                          final sample = entry.value.first;
                          return _LeagueLogoFilter(
                            league: sample.league,
                            logoUrl: sample.leagueLogoUrl,
                            active: expandedLeague == entry.key,
                            count: entry.value.length,
                            onTap: () => setState(() {
                              _expandedLeague = _expandedLeague == entry.key
                                  ? null
                                  : entry.key;
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (expandedLeague == null)
                      _ChatLeaguePrompt(hasLeagueFilter: hasLeagueFilter)
                    else ...[
                      if (upcomingMatches.isNotEmpty) ...[
                        Text(
                          'Por jugar · ${upcomingMatches.length}',
                          style: AppText.style(13, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ...upcomingMatches.map(
                        (pick) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChatMatchCard(
                            pick: pick,
                            finished: false,
                            onTap: () => _openMatchChat(context, pick),
                          ),
                        ),
                      ),
                      if (finishedMatches.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Partidos terminados · ${finishedMatches.length}',
                          style: AppText.style(
                            13,
                            weight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Puedes consultar su resultado, pero el chat IA ya está cerrado.',
                          style: AppText.style(
                            11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...finishedMatches.map(
                          (pick) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChatMatchCard(
                              pick: pick,
                              finished: true,
                              onTap: () => context.read<AppState>().openDetail(
                                pick.id,
                                returnScreen: AppScreen.chatPicker,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

void _openMatchChat(BuildContext context, Pick pick) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _MatchChatSheet(pick: pick),
    ),
  );
}

class _MatchChatSheet extends StatefulWidget {
  const _MatchChatSheet({required this.pick});

  final Pick pick;

  @override
  State<_MatchChatSheet> createState() => _MatchChatSheetState();
}

class _MatchChatSheetState extends State<_MatchChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool get _finished => context.read<AppState>().isMatchFinished(widget.pick);

  List<String> get _quickPrompts => [
    '¿Quién tiene más probabilidad de ganar?',
    'Marcador probable',
    '¿Ambos equipos anotan?',
    '¿Habrá más de 2.5 goles?',
  ];

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

  void _send([String? suggestion]) {
    if (_finished) return;
    final text = suggestion ?? _controller.text;
    if (text.trim().isEmpty) return;
    context
        .read<AppState>()
        .sendMatchChatMessage(widget.pick, text)
        .then((_) => _scrollToBottom());
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.matchChatFor(widget.pick);
    final loading = state.isMatchChatLoading(widget.pick);
    final pick = widget.pick;

    return Material(
      color: AppColors.screenBg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TeamCrest(
                        name: pick.teamA,
                        size: 30,
                        logoUrl: pick.teamALogoUrl,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pick.teamA} vs ${pick.teamB}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.style(15, weight: FontWeight.w800),
                            ),
                            Text(
                              _finished
                                  ? 'Finalizado · solo lectura'
                                  : pick.isLive
                                      ? 'EN VIVO${pick.liveScore == null ? '' : ' · ${pick.liveScore!.replaceAll('-', ' - ')}'}'
                                      : '${pick.league} · ${pick.time}',
                              style: AppText.style(
                                11.5,
                                color: pick.isLive
                                    ? AppColors.green
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textMuted,
                        tooltip: 'Cerrar chat',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _finished
                                  ? Icons.emoji_events_outlined
                                  : Icons.auto_awesome_rounded,
                              size: 32,
                              color: AppColors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _finished
                                  ? 'Este partido ya terminó'
                                  : 'Análisis IA del partido',
                              style: AppText.style(16, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _finished
                                  ? 'Puedes revisar el resultado desde el detalle del partido. El chat predictivo se cerró al finalizar.'
                                  : 'Pregunta sobre forma, probabilidades, goles o ambos equipos anotan.',
                              textAlign: TextAlign.center,
                              style: AppText.style(
                                12.5,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                            if (!_finished) ...[
                              const SizedBox(height: 18),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: _quickPrompts
                                    .map(
                                      (prompt) => ActionChip(
                                        label: Text(prompt),
                                        onPressed: () => _send(prompt),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      itemCount: messages.length + (loading ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= messages.length) {
                          return const _ChatLoadingIndicator();
                        }
                        final isLast = index == messages.length - 1 && !loading;
                        return ChatBubble(
                          message: messages[index],
                          onSuggestionTap: isLast && !_finished ? _send : null,
                        );
                      },
                    ),
            ),
            ChatInputBar(
              controller: _controller,
              onSend: _send,
              enabled: !_finished,
              hint: _finished
                  ? 'El partido ya terminó — chat cerrado'
                  : 'Pregunta sobre este partido...',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatLoadingIndicator extends StatelessWidget {
  const _ChatLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.green,
          ),
        ),
      ),
    );
  }
}

class _ChatLeaguePrompt extends StatelessWidget {
  const _ChatLeaguePrompt({required this.hasLeagueFilter});

  final bool hasLeagueFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.touch_app_outlined,
            color: AppColors.green,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona una liga',
            style: AppText.style(14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            hasLeagueFilter
                ? 'Aquí aparecen únicamente las ligas que elegiste en Ligas.'
                : 'Puedes personalizar las ligas visibles desde la pestaña Ligas.',
            textAlign: TextAlign.center,
            style: AppText.style(12, color: AppColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ChatMatchCard extends StatelessWidget {
  const _ChatMatchCard({
    required this.pick,
    required this.finished,
    required this.onTap,
  });

  final Pick pick;
  final bool finished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: finished
              ? AppColors.card.withValues(alpha: 0.72)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            TeamCrest(name: pick.teamA, size: 26, logoUrl: pick.teamALogoUrl),
            const SizedBox(width: 4),
            TeamCrest(name: pick.teamB, size: 26, logoUrl: pick.teamBLogoUrl),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pick.teamA} vs ${pick.teamB}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.style(13, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    finished
                        ? pick.liveScore == null
                              ? 'Finalizado · resultado pendiente'
                              : 'Finalizado · ${pick.liveScore!.replaceAll('-', ' - ')}'
                        : pick.time,
                    style: AppText.style(11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              finished
                  ? Icons.emoji_events_outlined
                  : Icons.chat_bubble_outline_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueLogoFilter extends StatelessWidget {
  const _LeagueLogoFilter({
    required this.league,
    required this.logoUrl,
    required this.active,
    required this.count,
    required this.onTap,
  });

  final String league;
  final String? logoUrl;
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '$league, $count encuentros',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 74,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppColors.green
                        : AppColors.textMuted.withValues(alpha: 0.35),
                    width: active ? 3 : 1.5,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: TeamCrest(name: league, size: 52, logoUrl: logoUrl),
              ),
              const SizedBox(height: 6),
              Text(
                league,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.style(
                  10.5,
                  weight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppColors.green : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
