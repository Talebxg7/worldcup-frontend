import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/football_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/notifications/local_notifications_service.dart';
import '../../../../services/football_api_service.dart';
import '../../../fixture_predictions/presentation/screens/prediction_screen.dart';
import '../../../../core/localization/app_localizations.dart';

class PredictionFixturesScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final String leagueName;
  final int? roomId;

  const PredictionFixturesScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    this.roomId,
  });

  @override
  ConsumerState<PredictionFixturesScreen> createState() => _PredictionFixturesScreenState();
}

class _PredictionFixturesScreenState extends ConsumerState<PredictionFixturesScreen> {
  late Future<List<FixtureModel>> _future;
  _FixturesFilter _filter = _FixturesFilter.allUpcoming;
  final Set<int> _activeAlerts = {};

  @override
  void initState() {
    super.initState();
    _future = FootballApiService.getFixtures(
      league: widget.leagueId,
      season: widget.leagueId == 1 ? 2026 : FootballConfig.currentSeason(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FootballApiService.getFixtures(
        league: widget.leagueId,
        season: widget.leagueId == 1 ? 2026 : FootballConfig.currentSeason(),
      );
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName.tr(ref)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: widget.leagueId == 1
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/world_cup_hero.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
              )
            : null,
        child: FutureBuilder<List<FixtureModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error'.tr(ref) + ': ${snap.error}'));
          }
          final fixtures = snap.data ?? [];
          final filtered = _applyFilter(fixtures);
          if (fixtures.isEmpty) {
            return Center(child: Text('No upcoming fixtures.'.tr(ref)));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final chipTextStyle = TextStyle(color: isDark ? Colors.white : Colors.black);
                  
                  final resultsColor = AppColors.secondary;
                  final resultsSelectedColor = resultsColor.withOpacity(0.8);
                  final resultsLabelStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
                  final resultsUnselectedStyle = TextStyle(color: resultsColor);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text('All upcoming'.tr(ref), style: chipTextStyle),
                                selected: _filter == _FixturesFilter.allUpcoming,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.allUpcoming),
                              ),
                              ChoiceChip(
                                label: Text('Today'.tr(ref), style: chipTextStyle),
                                selected: _filter == _FixturesFilter.today,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.today),
                              ),
                              ChoiceChip(
                                label: Text('Tomorrow'.tr(ref), style: chipTextStyle),
                                selected: _filter == _FixturesFilter.tomorrow,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.tomorrow),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 2,
                            height: 24,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text('Latest'.tr(ref), style: _filter == _FixturesFilter.latestResults ? resultsLabelStyle : resultsUnselectedStyle),
                                selected: _filter == _FixturesFilter.latestResults,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.latestResults),
                                selectedColor: resultsSelectedColor,
                                side: BorderSide(color: resultsColor.withOpacity(0.5)),
                                backgroundColor: isDark ? Colors.transparent : Colors.blue.withOpacity(0.05),
                              ),
                              ChoiceChip(
                                label: Text('Results Today'.tr(ref), style: _filter == _FixturesFilter.resultsToday ? resultsLabelStyle : resultsUnselectedStyle),
                                selected: _filter == _FixturesFilter.resultsToday,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.resultsToday),
                                selectedColor: resultsSelectedColor,
                                side: BorderSide(color: resultsColor.withOpacity(0.5)),
                                backgroundColor: isDark ? Colors.transparent : Colors.blue.withOpacity(0.05),
                              ),
                              ChoiceChip(
                                label: Text('Yesterday'.tr(ref), style: _filter == _FixturesFilter.yesterday ? resultsLabelStyle : resultsUnselectedStyle),
                                selected: _filter == _FixturesFilter.yesterday,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.yesterday),
                                selectedColor: resultsSelectedColor,
                                side: BorderSide(color: resultsColor.withOpacity(0.5)),
                                backgroundColor: isDark ? Colors.transparent : Colors.blue.withOpacity(0.05),
                              ),
                              ChoiceChip(
                                label: Text('Before Yesterday'.tr(ref), style: _filter == _FixturesFilter.beforeYesterday ? resultsLabelStyle : resultsUnselectedStyle),
                                selected: _filter == _FixturesFilter.beforeYesterday,
                                onSelected: (_) => setState(() => _filter = _FixturesFilter.beforeYesterday),
                                selectedColor: resultsSelectedColor,
                                side: BorderSide(color: resultsColor.withOpacity(0.5)),
                                backgroundColor: isDark ? Colors.transparent : Colors.blue.withOpacity(0.05),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No fixtures for this filter.'.tr(ref)),
                    ),
                  );
                }

                final f = filtered[i - 1];
                final kickoff = f.date != null ? df.format(f.date!.toLocal()) : '-';
                final canPredict = f.date != null &&
                    f.date!.subtract(const Duration(hours: 2)).isAfter(DateTime.now());
                final isEffectivelyFinished = (f.status != 'NS' && f.status != 'TBD') || 
                    (f.date != null && f.date!.isBefore(DateTime.now().subtract(const Duration(hours: 4))));
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _TeamRow(name: f.homeTeam, logo: f.homeLogo)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                            Expanded(child: _TeamRow(name: f.awayTeam, logo: f.awayLogo)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(kickoff, style: Theme.of(context).textTheme.bodySmall),
                            if (isEffectivelyFinished)
                              Expanded(
                                child: Text(
                                  f.homeGoals != null 
                                      ? '  |  ' + 'Score'.tr(ref) + ': ${f.homeGoals} - ${f.awayGoals} ${['1H', '2H', 'HT', 'LIVE'].contains(f.status) ? '(Live)'.tr(ref) : '(FT)'.tr(ref)}'
                                      : '  |  ' + 'Waiting for result...'.tr(ref),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800, 
                                    color: f.homeGoals != null ? Colors.green : Colors.orangeAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!isEffectivelyFinished && (f.status == 'NS' || f.status == 'TBD'))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: f.date == null
                                    ? null
                                    : () async {
                                        final isActive = _activeAlerts.contains(f.id);
                                        if (isActive) {
                                          await LocalNotificationsService.instance.cancelMatchReminders(f.id);
                                          setState(() => _activeAlerts.remove(f.id));
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Match alert canceled'.tr(ref))),
                                          );
                                        } else {
                                          await LocalNotificationsService.instance.scheduleMatchReminders(
                                            fixtureId: f.id,
                                            homeTeam: f.homeTeam,
                                            awayTeam: f.awayTeam,
                                            kickoff: f.date!,
                                          );
                                          setState(() => _activeAlerts.add(f.id));
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Match alert set'.tr(ref))),
                                          );
                                        }
                                      },
                                icon: Icon(
                                  _activeAlerts.contains(f.id)
                                      ? Icons.notifications_active
                                      : Icons.notifications_active_outlined,
                                  color: _activeAlerts.contains(f.id) ? Colors.greenAccent : null,
                                ),
                                label: Text(
                                  _activeAlerts.contains(f.id) ? 'Alerted'.tr(ref) : 'Alert'.tr(ref),
                                  style: TextStyle(
                                    color: _activeAlerts.contains(f.id) ? Colors.greenAccent : null,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _activeAlerts.contains(f.id)
                                        ? Colors.greenAccent
                                        : Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: canPredict
                                    ? () {
                                        final kickoffTime =
                                            f.date ?? DateTime.now().add(const Duration(hours: 2));
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PredictionScreen(
                                              fixtureId: f.id,
                                              kickoffTime: kickoffTime,
                                              homeTeam: f.homeTeam,
                                              awayTeam: f.awayTeam,
                                              homeLogo: f.homeLogo,
                                              awayLogo: f.awayLogo,
                                              homeTeamId: f.homeTeamId,
                                              awayTeamId: f.awayTeamId,
                                              leagueId: widget.leagueId,
                                              leagueName: widget.leagueName,
                                              roomId: widget.roomId,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text('Predict'.tr(ref)),
                              ),
                            ],
                          ),
                        if (!isEffectivelyFinished && !canPredict && (f.status == 'NS' || f.status == 'TBD'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Predictions are closed for this match'.tr(ref),
                              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }

  List<FixtureModel> _applyFilter(List<FixtureModel> fixtures) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);

    if (_filter == _FixturesFilter.allUpcoming) {
      return fixtures.where((f) {
        if (f.status != 'NS' && f.status != 'TBD') return false;
        if (f.date != null && f.date!.isBefore(now.subtract(const Duration(hours: 4)))) return false;
        return true;
      }).toList();
    }

    if (_filter == _FixturesFilter.latestResults) {
      final finished = fixtures.where((f) {
        if (f.status != 'NS' && f.status != 'TBD') return true;
        if (f.date != null && f.date!.isBefore(now.subtract(const Duration(hours: 4)))) return true;
        return false;
      }).toList();
      finished.sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
      return finished.take(15).toList();
    }

    return fixtures.where((f) {
      final d = f.date?.toLocal();
      if (d == null) return false;
      final isSameDay = (DateTime target) => d.year == target.year && d.month == target.month && d.day == target.day;

      switch (_filter) {
        case _FixturesFilter.today:
          return (f.status == 'NS' || f.status == 'TBD') && isSameDay(base);
        case _FixturesFilter.tomorrow:
          return (f.status == 'NS' || f.status == 'TBD') && isSameDay(base.add(const Duration(days: 1)));
        case _FixturesFilter.resultsToday:
          return (f.status != 'NS' && f.status != 'TBD' || (f.date != null && f.date!.isBefore(now.subtract(const Duration(hours: 4))))) && isSameDay(base);
        case _FixturesFilter.yesterday:
          return (f.status != 'NS' && f.status != 'TBD' || (f.date != null && f.date!.isBefore(now.subtract(const Duration(hours: 4))))) && isSameDay(base.subtract(const Duration(days: 1)));
        case _FixturesFilter.beforeYesterday:
          return (f.status != 'NS' && f.status != 'TBD' || (f.date != null && f.date!.isBefore(now.subtract(const Duration(hours: 4))))) && isSameDay(base.subtract(const Duration(days: 2)));
        default:
          return false;
      }
    }).toList();
  }
}

enum _FixturesFilter { allUpcoming, today, tomorrow, latestResults, resultsToday, yesterday, beforeYesterday }

class _TeamRow extends StatelessWidget {
  final String name;
  final String? logo;

  const _TeamRow({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: (logo == null || logo!.isEmpty)
              ? Container(
                  width: 34,
                  height: 34,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.shield_outlined, size: 18),
                )
              : Image.network(
                  logo!,
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
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

