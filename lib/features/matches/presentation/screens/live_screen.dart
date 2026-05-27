import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/football_config.dart';
import '../../../../services/football_api_service.dart';


class LiveScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;

  const LiveScreen({
    super.key,
    this.leagueId = FootballConfig.defaultLeagueId,
    this.leagueName = 'Live',
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  late Future<_LiveData> _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<_LiveData> _load() async {
    final season = widget.leagueId == 1 ? 2026 : FootballConfig.currentSeason();
    final live = await FootballApiService.getFixtures(
      live: 'all',
    );
    if (live.isNotEmpty) return _LiveData(live: live, upcomingSoon: const []);

    final upcoming = await FootballApiService.getFixtures(
      league: widget.leagueId,
      season: season,
      status: 'NS',
    );

    final now = DateTime.now();
    final end = now.add(const Duration(hours: 2));
    final soon = upcoming.where((f) {
      final d = f.date;
      if (d == null) return false;
      return d.isAfter(now) && d.isBefore(end);
    }).toList()
      ..sort((a, b) => (a.date ?? now).compareTo(b.date ?? now));

    return _LiveData(live: const [], upcomingSoon: soon);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Matches'),
        centerTitle: true,
        actions: [

          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_LiveData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final data = snap.data ?? const _LiveData(live: [], upcomingSoon: []);
          final items = data.live;
          if (items.isEmpty) {
            if (data.upcomingSoon.isEmpty) {
              return const Center(child: Text('No live matches right now.'));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.upcomingSoon.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No live matches right now.\nNext matches start within 2 hours:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  }
                  final f = data.upcomingSoon[i - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${f.homeTeam} vs ${f.awayTeam}'),
                      subtitle: Text(
                        f.date != null ? 'Starts at ${df.format(f.date!.toLocal())}' : '',
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final f = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('${f.homeTeam} vs ${f.awayTeam}'),
                    subtitle: Text(
                      '${f.minute != null ? "● ${f.minute}′" : (f.statusLong ?? f.status ?? "")} • ${f.date != null ? df.format(f.date!.toLocal()) : ""}',
                    ),
                    trailing: Text(
                      '${f.homeGoals ?? "-"} - ${f.awayGoals ?? "-"}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
}

class _LiveData {
  final List<FixtureModel> live;
  final List<FixtureModel> upcomingSoon;

  const _LiveData({
    required this.live,
    required this.upcomingSoon,
  });
}

