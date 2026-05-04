import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/football_config.dart';
import '../../../../services/football_api_service.dart';
import '../../models/competition.dart';
import '../widgets/competition_card.dart';
import '../../../matches/presentation/screens/prediction_fixtures_screen.dart';
import '../../../matches/presentation/screens/live_screen.dart';
import '../../../matches/presentation/screens/standings_screen.dart';

class CompetitionSelectionScreen extends StatefulWidget {
  final String title;
  final void Function(BuildContext context, Competition competition)? onSelect;
  final bool showTopActions;

  const CompetitionSelectionScreen({
    super.key,
    this.title = 'Pick a Competition',
    this.onSelect,
    this.showTopActions = true,
  });

  @override
  State<CompetitionSelectionScreen> createState() =>
      _CompetitionSelectionScreenState();
}

class _CompetitionSelectionScreenState extends State<CompetitionSelectionScreen> {
  late final List<Competition> _competitions;
  late Future<Map<int, int>> _countsFuture;

  @override
  void initState() {
    super.initState();

    _competitions = const [
      Competition(
        name: 'Premier League',
        subtitle: 'English Premier League',
        leagueId: 39,
        emoji: '🏴',
        isEnabled: true,
      ),
      Competition(
        name: 'La Liga',
        subtitle: 'Spanish Primera División',
        leagueId: 140,
        emoji: '🇪🇸',
        isEnabled: true,
      ),
      Competition(
        name: 'Serie A',
        subtitle: 'Italian Serie A',
        leagueId: 135,
        emoji: '🇮🇹',
        isEnabled: true,
      ),
      Competition(
        name: 'Bundesliga',
        subtitle: 'German Bundesliga',
        leagueId: 78,
        emoji: '🇩🇪',
        isEnabled: true,
      ),
      Competition(
        name: 'Ligue 1',
        subtitle: 'French Ligue 1',
        leagueId: 61,
        emoji: '🇫🇷',
        isEnabled: true,
      ),
      Competition(
        name: 'Egyptian Premier League',
        subtitle: 'Egyptian League',
        leagueId: 233,
        emoji: '🇪🇬',
        isEnabled: true,
      ),
      Competition(
        name: 'Primeira Liga',
        subtitle: 'Portugal Primeira Liga',
        leagueId: 94,
        emoji: '🇵🇹',
        isEnabled: true,
      ),
      Competition(
        name: 'FIFA World Cup',
        subtitle: 'FIFA World Cup',
        leagueId: 1,
        emoji: '🏆',
        isEnabled: true,
      ),
      Competition(
        name: 'UEFA Champions League',
        subtitle: 'UEFA Champions League',
        leagueId: 2,
        emoji: '⭐',
        isEnabled: true,
      ),
      Competition(
        name: 'UEFA Europa League',
        subtitle: 'UEFA Europa League',
        leagueId: 3,
        emoji: '🏅',
        isEnabled: true,
      ),
      Competition(
        name: 'AFCON',
        subtitle: 'Africa Cup of Nations',
        leagueId: 6,
        emoji: '🌍',
        isEnabled: true,
      ),
      Competition(
        name: 'Copa America',
        subtitle: 'CONMEBOL Copa América',
        leagueId: 9,
        emoji: '🌎',
        isEnabled: true,
      ),
      Competition(
        name: 'Saudi Pro League',
        subtitle: 'Roshn Saudi League',
        leagueId: 307,
        emoji: '🇸🇦',
        isEnabled: true,
      ),
      Competition(
        name: 'Qatar Stars League',
        subtitle: 'QSL',
        leagueId: 305,
        emoji: '🇶🇦',
        isEnabled: true,
      ),
      Competition(
        name: 'Jordanian Pro League',
        subtitle: 'Jordan League',
        leagueId: 387,
        emoji: '🇯🇴',
        isEnabled: true,
      ),
    ];

    _countsFuture = _loadCounts();
  }

  Future<Map<int, int>> _loadCounts() async {
    final season = FootballConfig.currentSeason();
    final enabled = _competitions.where((c) => c.isEnabled).toList();

    final entries = await Future.wait(
      enabled.map((c) async {
        final count = await FootballApiService.getUpcomingCount(
          league: c.leagueId,
          season: season,
        );
        return MapEntry(c.leagueId, count);
      }),
    );

    return {for (final e in entries) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (widget.showTopActions) ...[
            IconButton(
              tooltip: 'Live',
              onPressed: () => context.go('/home/live'),
              icon: const Icon(Icons.sports_soccer_rounded),
            ),
            IconButton(
              tooltip: 'Standings',
              onPressed: () => context.go('/home/standings'),
              icon: const Icon(Icons.leaderboard_rounded),
            ),
          ],
          IconButton(
            onPressed: () => setState(() {
              _countsFuture = _loadCounts();
            }),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<int, int>>(
        future: _countsFuture,
        builder: (context, snapshot) {
          final counts = snapshot.data ?? const <int, int>{};
          final loading = snapshot.connectionState == ConnectionState.waiting;

          return LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final cols = w < 560
                  ? 2
                  : w < 900
                      ? 3
                      : 4;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _competitions.length,
                itemBuilder: (context, index) {
                  final comp = _competitions[index];
                  return CompetitionCard(
                    competition: comp,
                    gradientColors: _gradientFor(comp.leagueId),
                    upcomingCount: counts[comp.leagueId],
                    isLoadingCount: loading,
                    onTap: () {
                      final onSelect = widget.onSelect;
                      if (onSelect != null) {
                        onSelect(context, comp);
                        return;
                      }
                      context.go(
                        '/home/fixtures?leagueId=${comp.leagueId}&leagueName=${Uri.encodeComponent(comp.name)}',
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Color> _gradientFor(int leagueId) {
    switch (leagueId) {
      case 39: // Premier League
        return const [Color(0xFF8B5CF6), Color(0xFFEC4899)];
      case 140: // La Liga
        return const [Color(0xFFEF4444), Color(0xFFF97316)];
      case 135: // Serie A
        return const [Color(0xFF3B82F6), Color(0xFF60A5FA)];
      case 78: // Bundesliga
        return const [Color(0xFFB91C1C), Color(0xFFFB7185)];
      case 61: // Ligue 1
        return const [Color(0xFF06B6D4), Color(0xFF3B82F6)];
      case 233: // Egypt
        return const [Color(0xFFF59E0B), Color(0xFF10B981)];
      case 94: // Portugal
        return const [Color(0xFF22C55E), Color(0xFF16A34A)];
      case 1: // World Cup
        return const [Color(0xFFF59E0B), Color(0xFFF97316)];
      case 2: // UCL
        return const [Color(0xFF7C3AED), Color(0xFF60A5FA)];
      case 3: // UEL
        return const [Color(0xFFFB923C), Color(0xFFFDE047)];
      case 6: // AFCON
        return const [Color(0xFF10B981), Color(0xFF22C55E)];
      case 9: // Copa America
        return const [Color(0xFF0EA5E9), Color(0xFF22C55E)];
      case 307: // Saudi Pro League
        return const [Color(0xFF1D4ED8), Color(0xFF0F766E)];
      case 305: // Qatar Stars League
        return const [Color(0xFF9D174D), Color(0xFFBE185D)];
      default:
        return const [Color(0xFF0EA5E9), Color(0xFF3B82F6)];
    }
  }
}

