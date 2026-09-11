import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/league_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/league_badge_card.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<LeagueInfo>? _leagues;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final leagues = await LeagueService.instance.fetchActiveLeagues();
      if (mounted) setState(() => _leagues = leagues);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
          child: Text('Ligas', style: AppText.style(19, weight: FontWeight.w600)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toca una liga para ver solo sus picks en Home.',
                  style: AppText.style(12.5, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _error
                      ? Center(
                          child: TextButton(
                            onPressed: _load,
                            child: Text('No se pudo cargar — toca para reintentar', style: AppText.style(12.5, color: AppColors.textMuted)),
                          ),
                        )
                      : _leagues == null
                          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: 14,
                                runSpacing: 30,
                                children: _leagues!.map((league) {
                                  final active = state.homeLeagueFilter == league.name;
                                  return LeagueBadgeCard(
                                    league: league.name,
                                    logoUrl: league.logoUrl,
                                    active: active,
                                    onTap: () {
                                      context.read<AppState>().setHomeLeagueFilter(active ? null : league.name);
                                      context.read<AppState>().go(AppScreen.home);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
