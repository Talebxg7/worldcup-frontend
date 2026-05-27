import 'package:flutter/material.dart';
import '../../../../core/config/football_config.dart';
import '../../../../services/football_api_service.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late Future<List<StandingModel>> _future;
  int _selectedLeagueId = FootballConfig.defaultLeagueId;

  static const _leagues = <int, String>{
    39: 'Premier League',
    140: 'La Liga',
    135: 'Serie A',
    78: 'Bundesliga',
    61: 'Ligue 1',
    1: 'World Cup',
    2: 'Champions League',
    3: 'Europa League',
    6: 'AFCON',
    9: 'Copa America',
    307: 'Saudi Pro League',
    305: 'Qatar Stars League',
    233: 'Egyptian League',
    94: 'Primeira Liga',
  };

  @override
  void initState() {
    super.initState();
    _future = FootballApiService.getStandings(
      league: _selectedLeagueId,
      season: _selectedLeagueId == 1 ? 2026 : FootballConfig.currentSeason(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FootballApiService.getStandings(
        league: _selectedLeagueId,
        season: _selectedLeagueId == 1 ? 2026 : FootballConfig.currentSeason(),
      );
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standings'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<int>(
              value: _selectedLeagueId,
              decoration: const InputDecoration(
                labelText: 'Select League',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _leagues.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLeagueId = val;
                  });
                  _refresh();
                }
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StandingModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final rows = snap.data ?? [];
          if (rows.isEmpty) return const Center(child: Text('No standings data.'));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = rows[i];
                return ListTile(
                  leading: Text(
                    '${r.rank}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  title: Text(r.teamName),
                  trailing: Text(
                    '${r.points} pts',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('P:${r.played} W:${r.win} D:${r.draw} L:${r.lose}'),
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
}

