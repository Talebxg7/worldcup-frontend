import 'package:flutter/material.dart';
import '../../../../core/config/football_config.dart';
import '../../../../services/football_api_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late Future<List<TeamModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FootballApiService.getTeams(
      league: FootballConfig.defaultLeagueId,
      season: FootballConfig.currentSeason(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FootballApiService.getTeams(
        league: FootballConfig.defaultLeagueId,
        season: FootballConfig.currentSeason(),
      );
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<TeamModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final teams = snap.data ?? [];
          if (teams.isEmpty) return const Center(child: Text('No teams found.'));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = teams[i];
                return ListTile(
                  leading: ClipOval(
                    child: (t.logo == null || t.logo!.isEmpty)
                        ? Container(
                            width: 34,
                            height: 34,
                            color: Colors.grey.withOpacity(0.2),
                            child: const Icon(Icons.shield_outlined, size: 18),
                          )
                        : Image.network(
                            t.logo!,
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
                  title: Text(t.name),
                  subtitle: Text(t.country ?? ''),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

