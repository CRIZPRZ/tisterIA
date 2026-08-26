import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import '../widgets/team_crest.dart';

class ChatPickerScreen extends StatelessWidget {
  const ChatPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final picks = state.filteredPicks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
          child: Text('Chat IA', style: AppText.style(19, weight: FontWeight.w600)),
        ),
        Expanded(
          child: picks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Sin partidos hoy',
                    message: 'Cuando haya picks disponibles podrás preguntarle a la IA sobre cualquier partido.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
                  children: [
                    Text(
                      'Elige un partido para preguntarle a la IA.',
                      style: AppText.style(12.5, color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ...picks.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => context.read<AppState>().openDetail(p.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  TeamCrest(name: p.teamA, size: 26, logoUrl: p.teamALogoUrl),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: TeamCrest(name: p.teamB, size: 26, logoUrl: p.teamBLogoUrl),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p.teamA} vs ${p.teamB}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.style(13, weight: FontWeight.w600),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
        ),
      ],
    );
  }
}
