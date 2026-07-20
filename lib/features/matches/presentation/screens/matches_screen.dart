import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/football_config.dart';
import '../../../../services/football_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'live_screen.dart';
import 'standings_screen.dart';
import 'teams_screen.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../predictions_dashboard/presentation/screens/world_cup_hub_screen.dart';
import '../../../predictions_dashboard/data/dashboard_prediction_repository.dart';
import '../../../predictions_dashboard/services/prediction_dashboard_service.dart';
import '../../../competitions/presentation/widgets/league_challenge_banner.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  late Future<List<FixtureModel>> _fixturesFuture;

  @override
  void initState() {
    super.initState();
    _fixturesFuture = FootballApiService.getFixtures(
      league: FootballConfig.defaultLeagueId,
      season: FootballConfig.currentSeason(),
      status: 'NS',
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _fixturesFuture = FootballApiService.getFixtures(
        league: FootballConfig.defaultLeagueId,
        season: FootballConfig.currentSeason(),
        status: 'NS',
      );
    });
    await _fixturesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predict Matches'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Live',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveScreen()),
            ),
            icon: const Icon(Icons.sports_soccer_rounded),
          ),
          IconButton(
            tooltip: 'Standings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StandingsScreen()),
            ),
            icon: const Icon(Icons.leaderboard_rounded),
          ),
          IconButton(
            tooltip: 'Teams',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeamsScreen()),
            ),
            icon: const Icon(Icons.groups_rounded),
          ),
          IconButton(
            onPressed: () => themeNotifier.toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.darkHeroGradient : AppColors.heroGradient,
            ),
            child: Text(
              'Hi, ${user?.username ?? "Player"} - upcoming fixtures only',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: LeagueChallengeBanner(),
          ),
          Expanded(
            child: FutureBuilder<List<FixtureModel>>(
              future: _fixturesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Failed to load upcoming fixtures.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final fixtures = snapshot.data ?? [];
                if (fixtures.isEmpty) {
                  return const Center(
                    child: Text('No upcoming matches found right now.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: fixtures.length,
                    itemBuilder: (context, index) {
                      final fixture = fixtures[index];
                      final now = DateTime.now();
                      final canPredict =
                          fixture.date != null && fixture.date!.isAfter(now);
                      return _FixturePredictionCard(
                        fixture: fixture,
                        canPredict: canPredict,
                        onPredict: canPredict
                            ? () => _openPredictDialog(context, fixture, user?.id)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPredictDialog(
    BuildContext context,
    FixtureModel fixture,
    int? userId,
  ) async {
    if (fixture.date == null || !fixture.date!.isAfter(DateTime.now())) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prediction closed. Kickoff already started.'),
        ),
      );
      return;
    }

    int homeScore = 0;
    int awayScore = 0;

    String predictedWinner() {
      if (homeScore == awayScore) return 'Draw';
      return homeScore > awayScore ? fixture.homeTeam : fixture.awayTeam;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Predict Score'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${fixture.homeTeam} vs ${fixture.awayTeam}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: homeScore,
                        items: List.generate(
                          11,
                          (i) => DropdownMenuItem(value: i, child: Text('$i')),
                        ),
                        onChanged: (v) => setDialogState(() => homeScore = v ?? 0),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('-'),
                      ),
                      DropdownButton<int>(
                        value: awayScore,
                        items: List.generate(
                          11,
                          (i) => DropdownMenuItem(value: i, child: Text('$i')),
                        ),
                        onChanged: (v) => setDialogState(() => awayScore = v ?? 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Predicted winner: ${predictedWinner()}',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('predictions').add({
                      'fixture_id': fixture.id,
                      'league': fixture.leagueName ?? 'Premier League',
                      'home_team': fixture.homeTeam,
                      'away_team': fixture.awayTeam,
                      'home_score': homeScore,
                      'away_score': awayScore,
                      'winner': predictedWinner(),
                      'kickoff_time': fixture.date?.toIso8601String(),
                      'user_id': userId,
                      'created_at': FieldValue.serverTimestamp(),
                    });

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prediction saved')),
                    );
                  },
                  child: const Text('Save Prediction'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FixturePredictionCard extends StatelessWidget {
  final FixtureModel fixture;
  final VoidCallback? onPredict;
  final bool canPredict;

  const _FixturePredictionCard({
    required this.fixture,
    required this.canPredict,
    required this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • HH:mm');
    final kickoff = fixture.date != null ? dateFormat.format(fixture.date!.toLocal()) : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fixture.leagueName ?? 'Premier League',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TeamInfo(
                    name: fixture.homeTeam,
                    logoUrl: fixture.homeLogo,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: _TeamInfo(
                    name: fixture.awayTeam,
                    logoUrl: fixture.awayLogo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kickoff,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!canPredict)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Prediction closed',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onPredict,
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  label: const Text('Predict', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final String name;
  final String? logoUrl;

  const _TeamInfo({
    required this.name,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: logoUrl == null || logoUrl!.isEmpty
              ? Container(
                  width: 34,
                  height: 34,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.shield_outlined, size: 18),
                )
              : Image.network(
                  logoUrl!,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 34,
                    height: 34,
                    color: Colors.grey.withOpacity(0.2),
                    child: const Icon(Icons.shield_outlined, size: 18),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
