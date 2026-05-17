import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/football_api_service.dart';
import '../../../fixture_predictions/data/prediction_repository.dart';
import '../../../fixture_predictions/presentation/screens/prediction_screen.dart';
import '../../data/dashboard_prediction_repository.dart';
import '../../models/dashboard_prediction_model.dart';
import '../../services/prediction_dashboard_service.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Bottom-nav **Predictions** hub: summary, weekly joker, weekly progress, league filter, tabs.
class PredictionsDashboardScreen extends ConsumerStatefulWidget {
  const PredictionsDashboardScreen({super.key});

  @override
  ConsumerState<PredictionsDashboardScreen> createState() => _PredictionsDashboardScreenState();
}

class _PredictionsDashboardScreenState extends ConsumerState<PredictionsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _repo = DashboardPredictionRepository();
  final _service = PredictionDashboardService();
  final _jokerRepo = PredictionRepository();

  late final TabController _tabs;

  List<DashboardPredictionModel> _rows = [];
  bool _loading = true;
  String _filterLeagueId = 'ALL';
  String? _jokerFixtureLabel;

  static const _leagueFilters = <(String, String)>[
    ('ALL', 'All Leagues'),
    ('39', 'Premier League'),
    ('140', 'La Liga'),
    ('135', 'Serie A'),
    ('78', 'Bundesliga'),
    ('61', 'Ligue 1'),
    ('2', 'Champions League'),
    ('3', 'Europa League'),
    ('6', 'AFCON'),
    ('9', 'Copa America'),
    ('1', 'World Cup'),
    ('307', 'Saudi Pro League'),
    ('269', 'Qatar Stars League'),
    ('387', 'Jordanian Pro League'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await _repo.loadAll();
      final enriched = await _service.enrichAll(raw);
      enriched.sort((a, b) => a.kickoff.compareTo(b.kickoff));
      final jokerId = await _jokerRepo.getWeeklyJokerFixtureId();
      String? jokerLabel;
      if (jokerId != null) {
        try {
          final fx = await FootballApiService.getFixtureById(jokerId);
          if (fx != null) {
            jokerLabel = '${fx.homeTeam} vs ${fx.awayTeam}';
          } else {
            jokerLabel = 'Fixture #$jokerId';
          }
        } catch (_) {
          jokerLabel = 'Fixture #$jokerId';
        }
      }
      if (!mounted) return;
      setState(() {
        _rows = enriched;
        _jokerFixtureLabel = jokerLabel;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load predictions: $e')),
      );
    }
  }

  Iterable<DashboardPredictionModel> get _filtered {
    if (_filterLeagueId == 'ALL') return _rows;
    return _rows.where((e) => e.leagueId == _filterLeagueId);
  }

  List<DashboardPredictionModel> _forTab(int index) {
    final f = _filtered.toList();
    switch (index) {
      case 0:
        return f.where((p) => p.matchStatus == 'UPCOMING').toList();
      case 1:
        return f.where((p) => p.matchStatus == 'LIVE').toList();
      default:
        return f.where((p) => p.matchStatus == 'FINISHED').toList();
    }
  }

  String _winnerLabel(DashboardPredictionModel p) {
    switch (p.predictedWinner) {
      case 'HOME':
        return p.homeTeam;
      case 'AWAY':
        return p.awayTeam;
      default:
        return 'Draw';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    final total = _rows.length;
    final correctWinners = _service.countCorrectWinners(_rows);
    final exact = _service.countExactScores(_rows);
    final weeklyPts = _service.weeklyPoints(_rows);

    final leaderboardId = _filterLeagueId == 'ALL' ? 0 : int.parse(_filterLeagueId);
    final leaderboard = ref.watch(leaderboardProvider(leaderboardId)).valueOrNull ?? [];
    final currentUser = ref.watch(authStateProvider).value;
    int? currentRank;
    if (currentUser != null) {
      final entry = leaderboard.where((e) => e.userId == currentUser.id).firstOrNull;
      currentRank = entry?.rank;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _SummaryCard(
                            total: total,
                            correctWinners: correctWinners,
                            exactScores: exact,
                            weeklyPoints: weeklyPts,
                            rank: currentRank,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _JokerCard(
                            usedLabel: _jokerFixtureLabel,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Competition',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _filterLeagueId,
                                items: _leagueFilters
                                    .map(
                                      (e) => DropdownMenuItem<String>(
                                        value: e.$1,
                                        child: Text(e.$2),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _filterLeagueId = v ?? 'ALL'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Live'),
                      Tab(text: 'Finished'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: List.generate(3, (tabIndex) {
                      final list = _forTab(tabIndex);
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            tabIndex == 0
                                ? 'No upcoming predictions.'
                                : tabIndex == 1
                                    ? 'No live predictions.'
                                    : 'No finished predictions yet.',
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final p = list[i];
                            final canEdit =
                                p.matchStatus == 'UPCOMING' && p.kickoff.isAfter(DateTime.now());
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PredictionCard(
                                p: p,
                                dateFormat: df,
                                winnerLabel: _winnerLabel(p),
                                tabIndex: tabIndex,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PredictionScreen(
                                        fixtureId: int.parse(p.fixtureId),
                                        kickoffTime: p.kickoff,
                                        homeTeam: p.homeTeam,
                                        awayTeam: p.awayTeam,
                                        homeLogo: p.homeLogo,
                                        awayLogo: p.awayLogo,
                                        homeTeamId: p.homeTeamId,
                                        awayTeamId: p.awayTeamId,
                                        leagueId: int.tryParse(p.leagueId) ?? 39,
                                        leagueName: p.leagueName ?? 'League',
                                      ),
                                    ),
                                  );
                                },
                                onEdit: canEdit
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PredictionScreen(
                                              fixtureId: int.parse(p.fixtureId),
                                              kickoffTime: p.kickoff,
                                              homeTeam: p.homeTeam,
                                              awayTeam: p.awayTeam,
                                              homeLogo: p.homeLogo,
                                              awayLogo: p.awayLogo,
                                              homeTeamId: p.homeTeamId,
                                              awayTeamId: p.awayTeamId,
                                              leagueId: int.tryParse(p.leagueId) ?? 39,
                                              leagueName: p.leagueName ?? 'League',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int correctWinners;
  final int exactScores;
  final int weeklyPoints;
  final int? rank;

  const _SummaryCard({
    required this.total,
    required this.correctWinners,
    required this.exactScores,
    required this.weeklyPoints,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediction summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _sumRow('Total predictions', '$total'),
          _sumRow('Correct winners', '$correctWinners'),
          _sumRow('Exact scores', '$exactScores'),
          _sumRow('Weekly points', '+$weeklyPoints', highlight: true),
          if (rank != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Global Rank:',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sumRow(String k, String v, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 13)),
          Text(
            v,
            style: TextStyle(
              color: highlight ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerCard extends StatelessWidget {
  final String? usedLabel;

  const _JokerCard({required this.usedLabel});

  @override
  Widget build(BuildContext context) {
    final used = (usedLabel ?? '').isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Colors.amber.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber.shade400),
              const SizedBox(width: 8),
              const Text(
                'Weekly Joker status',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            used
                ? 'Joker used this week:\n$usedLabel'
                : 'Joker available this week',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


class _PredictionCard extends StatelessWidget {
  final DashboardPredictionModel p;
  final DateFormat dateFormat;
  final String winnerLabel;
  final int tabIndex;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _PredictionCard({
    required this.p,
    required this.dateFormat,
    required this.winnerLabel,
    required this.tabIndex,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (p.matchStatus) {
      'LIVE' => Colors.redAccent,
      'FINISHED' => Colors.blueGrey,
      _ => Colors.tealAccent.shade700,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.leagueName ?? 'League ${p.leagueId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      p.matchStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (p.matchStatus == 'FINISHED' && p.pointsEarned != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (p.pointsEarned! > 0 ? Colors.green : (p.pointsEarned! < 0 ? Colors.red : Colors.grey)).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${p.pointsEarned! > 0 ? '+' : ''}${p.pointsEarned} pts',
                        style: TextStyle(
                          color: p.pointsEarned! > 0 ? Colors.greenAccent : (p.pointsEarned! < 0 ? Colors.redAccent : Colors.grey.shade300),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _TeamChip(name: p.homeTeam, logo: p.homeLogo)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('vs', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(child: _TeamChip(name: p.awayTeam, logo: p.awayLogo)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dateFormat.format(p.kickoff.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Prediction: ${p.homeScore}–${p.awayScore}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text('Winner: $winnerLabel${p.jokerUsed ? '  ·  Joker' : ''}'),
              if (p.matchStatus == 'LIVE' || p.matchStatus == 'FINISHED') ...[
                const SizedBox(height: 6),
                Text(
                  '${p.matchStatus == 'FINISHED' ? 'Final Score' : 'Current Score'}: ${p.actualHomeGoals ?? '—'} – ${p.actualAwayGoals ?? '—'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              if (tabIndex == 2) ...[
                const SizedBox(height: 6),
                Text(
                  'Final: ${p.actualHomeGoals ?? '—'}–${p.actualAwayGoals ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Points earned: ${p.pointsEarned != null ? '+${p.pointsEarned}' : '—'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (tabIndex == 0) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: Text(onEdit == null ? 'Edit locked' : 'Edit prediction'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String name;
  final String? logo;

  const _TeamChip({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: logo == null || logo!.isEmpty
              ? Container(
                  width: 32,
                  height: 32,
                  color: Colors.grey.withOpacity(0.25),
                  child: const Icon(Icons.shield_outlined, size: 16),
                )
              : Image.network(
                  logo!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey.withOpacity(0.25),
                    child: const Icon(Icons.shield_outlined, size: 16),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
