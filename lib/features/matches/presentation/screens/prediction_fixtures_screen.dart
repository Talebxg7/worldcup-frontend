import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/football_config.dart';
import '../../../../core/notifications/local_notifications_service.dart';
import '../../../../services/football_api_service.dart';
import '../../../fixture_predictions/presentation/screens/prediction_screen.dart';

class PredictionFixturesScreen extends StatefulWidget {
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
  State<PredictionFixturesScreen> createState() => _PredictionFixturesScreenState();
}

class _PredictionFixturesScreenState extends State<PredictionFixturesScreen> {
  late Future<List<FixtureModel>> _future;
  _FixturesFilter _filter = _FixturesFilter.all;
  final Set<int> _activeAlerts = {};

  @override
  void initState() {
    super.initState();
    _future = FootballApiService.getFixtures(
      league: widget.leagueId,
      season: FootballConfig.currentSeason(),
      status: 'NS',
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FootballApiService.getFixtures(
        league: widget.leagueId,
        season: FootballConfig.currentSeason(),
        status: 'NS',
      );
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<FixtureModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final fixtures = snap.data ?? [];
          final filtered = _applyFilter(fixtures);
          if (fixtures.isEmpty) {
            return const Center(child: Text('No upcoming fixtures.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All upcoming'),
                          selected: _filter == _FixturesFilter.all,
                          onSelected: (_) => setState(() => _filter = _FixturesFilter.all),
                        ),
                        ChoiceChip(
                          label: const Text('Today'),
                          selected: _filter == _FixturesFilter.today,
                          onSelected: (_) => setState(() => _filter = _FixturesFilter.today),
                        ),
                        ChoiceChip(
                          label: const Text('Tomorrow'),
                          selected: _filter == _FixturesFilter.tomorrow,
                          onSelected: (_) => setState(() => _filter = _FixturesFilter.tomorrow),
                        ),
                      ],
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No fixtures for this filter.'),
                    ),
                  );
                }

                final f = filtered[i - 1];
                final kickoff = f.date != null ? df.format(f.date!.toLocal()) : '-';
                final canPredict = f.date != null &&
                    f.date!.subtract(const Duration(hours: 2)).isAfter(DateTime.now());
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
                        Text(kickoff, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 10),
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
                                          const SnackBar(content: Text('Match alert canceled')),
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
                                          const SnackBar(content: Text('Match alert set')),
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
                                _activeAlerts.contains(f.id) ? 'Alerted' : 'Alert',
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
                              child: const Text('Predict'),
                            ),
                          ],
                        ),
                        if (!canPredict)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Predictions are closed for this match',
                              style: TextStyle(fontSize: 12, color: Colors.redAccent),
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
    );
  }

  List<FixtureModel> _applyFilter(List<FixtureModel> fixtures) {
    if (_filter == _FixturesFilter.all) return fixtures;
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final target = _filter == _FixturesFilter.today ? base : base.add(const Duration(days: 1));
    return fixtures.where((f) {
      final d = f.date?.toLocal();
      if (d == null) return false;
      return d.year == target.year && d.month == target.month && d.day == target.day;
    }).toList();
  }
}

enum _FixturesFilter { today, tomorrow, all }

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

