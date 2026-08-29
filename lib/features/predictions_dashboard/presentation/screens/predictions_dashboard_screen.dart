import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/football_api_service.dart';
import '../../../fixture_predictions/data/prediction_repository.dart';
import '../../../fixture_predictions/presentation/screens/prediction_screen.dart';
import '../../data/dashboard_prediction_repository.dart';
import '../../models/dashboard_prediction_model.dart';
import '../../services/prediction_dashboard_service.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../competitions/presentation/widgets/league_challenge_banner.dart';

enum DateFilterMode {
  all,
  lastWeek,
  yesterday,
  today,
  custom,
}

/// Bottom-nav **Predictions** hub: summary, weekly joker, weekly progress, date/period filter, tabs.
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
  DateFilterMode _dateFilter = DateFilterMode.all;
  DateTime? _customFilterDate;
  String? _jokerFixtureLabel;
  String _selectedLeagueId = 'all';

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

  bool _matchesDateFilter(DateTime kickoff) {
    final now = DateTime.now();
    final localKickoff = kickoff.toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    switch (_dateFilter) {
      case DateFilterMode.all:
        return true;
      case DateFilterMode.today:
        return localKickoff.year == now.year &&
            localKickoff.month == now.month &&
            localKickoff.day == now.day;
      case DateFilterMode.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return localKickoff.year == yesterday.year &&
            localKickoff.month == yesterday.month &&
            localKickoff.day == yesterday.day;
      case DateFilterMode.lastWeek:
        final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
        return localKickoff.isAfter(sevenDaysAgo) && localKickoff.isBefore(todayEnd);
      case DateFilterMode.custom:
        if (_customFilterDate == null) return true;
        return localKickoff.year == _customFilterDate!.year &&
            localKickoff.month == _customFilterDate!.month &&
            localKickoff.day == _customFilterDate!.day;
    }
  }

  Future<void> _selectCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customFilterDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFFFD700), // Gold accent
              onPrimary: const Color(0xFF093122), // Deep green background contrast
              surface: const Color(0xFF0F4C3A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF061E15),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateFilter = DateFilterMode.custom;
        _customFilterDate = picked;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter by Date'.tr(ref),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text('All Time'.tr(ref)),
                      trailing: _dateFilter == DateFilterMode.all
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _dateFilter = DateFilterMode.all);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.date_range_rounded),
                      title: Text('Last Week'.tr(ref)),
                      trailing: _dateFilter == DateFilterMode.lastWeek
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _dateFilter = DateFilterMode.lastWeek);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_busy_rounded),
                      title: Text('Yesterday'.tr(ref)),
                      trailing: _dateFilter == DateFilterMode.yesterday
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _dateFilter = DateFilterMode.yesterday);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.today_rounded),
                      title: Text('Today'.tr(ref)),
                      trailing: _dateFilter == DateFilterMode.today
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _dateFilter = DateFilterMode.today);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: Text(_dateFilter == DateFilterMode.custom && _customFilterDate != null
                          ? 'Custom: ${DateFormat('yyyy-MM-dd').format(_customFilterDate!)}'
                          : 'Select Custom Date...'.tr(ref)),
                      trailing: _dateFilter == DateFilterMode.custom
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _selectCustomDate();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Iterable<DashboardPredictionModel> get _filtered {
    return _rows.where((e) {
      final matchesDate = _matchesDateFilter(e.kickoff);
      final matchesLeague = _selectedLeagueId == 'all' || e.leagueId == _selectedLeagueId;
      return matchesDate && matchesLeague;
    });
  }

  List<DashboardPredictionModel> _forTab(int index) {
    final f = _filtered.toList();
    switch (index) {
      case 0:
        return f.where((p) => p.matchStatus == 'UPCOMING').toList();
      case 1:
        return f.where((p) => p.matchStatus == 'LIVE').toList();
      default:
        final finished = f.where((p) => p.matchStatus == 'FINISHED').toList();
        finished.sort((a, b) => b.kickoff.compareTo(a.kickoff)); // Descending chronological order: newest finished matches first
        return finished;
    }
  }

  String _winnerLabel(DashboardPredictionModel p, WidgetRef ref) {
    switch (p.predictedWinner) {
      case 'HOME':
        return p.homeTeam;
      case 'AWAY':
        return p.awayTeam;
      default:
        return 'Draw'.tr(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    final total = _rows.length;
    final correctWinners = _service.countCorrectWinners(_rows);
    final exact = _service.countExactScores(_rows);
    final weeklyPts = _service.weeklyPoints(_rows);

    final leaderboardId = 0;
    final leaderboardRes = ref.watch(leaderboardProvider(LeaderboardArgs(leagueId: leaderboardId, season: 2))).valueOrNull;
    final leaderboard = leaderboardRes?.entries ?? <LeaderboardEntry>[];
    final currentUser = ref.watch(authStateProvider).value;
    int? currentRank;
    if (currentUser != null) {
      final entry = leaderboard.where((e) => e.userId == currentUser.id).firstOrNull;
      currentRank = entry?.rank;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Predictions'.tr(ref)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterDialog,
          ),
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
                            hideUsername: currentUser?.hideUsername ?? false,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: LeagueChallengeBanner(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _JokerCard(
                            usedLabel: _jokerFixtureLabel,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Builder(
                            builder: (context) {
                              final uniqueLeagues = <String, String>{};
                              for (final p in _rows) {
                                if (p.leagueName != null && p.leagueName!.isNotEmpty) {
                                  uniqueLeagues[p.leagueId] = p.leagueName!;
                                } else {
                                  uniqueLeagues[p.leagueId] = 'League ${p.leagueId}';
                                }
                              }
                              final isSelectedLeagueValid = _selectedLeagueId == 'all' || uniqueLeagues.containsKey(_selectedLeagueId);
                              final dropdownValue = isSelectedLeagueValid ? _selectedLeagueId : 'all';

                              return InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Filter by League'.tr(ref),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: dropdownValue,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All Leagues'.tr(ref)),
                                      ),
                                      ...uniqueLeagues.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(entry.value.tr(ref)),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedLeagueId = v;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              );
                            }
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
                    tabs: [
                      Tab(text: 'Upcoming'.tr(ref)),
                      Tab(text: 'Live'.tr(ref)),
                      Tab(text: 'Finished'.tr(ref)),
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
                                ? 'No upcoming predictions.'.tr(ref)
                                : tabIndex == 1
                                    ? 'No live predictions.'.tr(ref)
                                    : 'No finished predictions yet.'.tr(ref),
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
                                winnerLabel: _winnerLabel(p, ref),
                                tabIndex: tabIndex,
                                onTap: () async {
                                  await Navigator.of(context).push(
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
                                  if (mounted) _load();
                                },
                                onEdit: canEdit
                                    ? () async {
                                        await Navigator.of(context).push(
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
                                        if (mounted) _load();
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

class _SummaryCard extends ConsumerWidget {
  final int total;
  final int correctWinners;
  final int exactScores;
  final int weeklyPoints;
  final int? rank;
  final bool hideUsername;

  const _SummaryCard({
    required this.total,
    required this.correctWinners,
    required this.exactScores,
    required this.weeklyPoints,
    this.rank,
    this.hideUsername = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              )
            : null,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prediction summary'.tr(ref),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _sumRow('Total predictions'.tr(ref), '$total', isDark: isDark),
          _sumRow('Correct winners'.tr(ref), '$correctWinners', isDark: isDark),
          _sumRow('Exact Scores'.tr(ref), '$exactScores', isDark: isDark),
          _sumRow('Weekly points'.tr(ref), '+$weeklyPoints', isDark: isDark, highlight: true),
          if (hideUsername) ...[
            const SizedBox(height: 8),
            Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Global Rank:'.tr(ref),
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.75) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '(-)',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Unhide your username to see your Global rank'.tr(ref),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (rank != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Global Rank:'.tr(ref),
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.75) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '#$rank',
                  style: TextStyle(
                    color: isDark ? Colors.amberAccent : const Color(0xFFD97706),
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

  Widget _sumRow(String k, String v, {required bool isDark, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.78) : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              color: highlight
                  ? (isDark ? Colors.greenAccent : const Color(0xFF059669))
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerCard extends ConsumerWidget {
  final String? usedLabel;

  const _JokerCard({required this.usedLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final used = (usedLabel ?? '').isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isDark ? Colors.amber.withOpacity(0.35) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber.shade400),
              const SizedBox(width: 8),
              Text(
                'Weekly Joker status'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            used
                ? 'Joker used this week:\n'.tr(ref) + '$usedLabel'
                : 'Joker available this week'.tr(ref),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


class _PredictionCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (p.leagueName ?? 'League ${p.leagueId}').tr(ref),
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
                      p.matchStatus.tr(ref),
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
                        '${p.pointsEarned! > 0 ? '+' : ''}${p.pointsEarned} ${'pts'.tr(ref)}',
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
                'Prediction'.tr(ref) + ': ${p.homeScore}–${p.awayScore}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text('Winner'.tr(ref) + ': $winnerLabel${p.jokerUsed ? '  ·  ' + 'Joker'.tr(ref) : ''}'),
              if (p.matchStatus == 'LIVE' || p.matchStatus == 'FINISHED') ...[
                const SizedBox(height: 6),
                Text(
                  '${p.matchStatus == 'FINISHED' ? 'Final Score'.tr(ref) : 'Current Score'.tr(ref)}: ${p.actualHomeGoals ?? '—'} – ${p.actualAwayGoals ?? '—'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              if (tabIndex == 2) ...[
                const SizedBox(height: 6),
                Text(
                  'Final'.tr(ref) + ': ${p.actualHomeGoals ?? '—'}–${p.actualAwayGoals ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Points earned'.tr(ref) + ': ${p.pointsEarned != null ? (p.pointsEarned! > 0 ? '+${p.pointsEarned}' : '${p.pointsEarned}') : '—'}',
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
                    child: Text(onEdit == null ? 'Edit locked'.tr(ref) : 'Edit prediction'.tr(ref)),
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
