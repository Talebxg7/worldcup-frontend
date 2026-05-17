import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/football_config.dart';
import '../../../../services/football_api_service.dart';
import '../../data/room_repository.dart';

class RoomLiveScreen extends StatefulWidget {
  final int roomId;
  const RoomLiveScreen({super.key, required this.roomId});

  @override
  State<RoomLiveScreen> createState() => _RoomLiveScreenState();
}

class _RoomLiveScreenState extends State<RoomLiveScreen> {
  final _roomRepo = RoomRepository();
  late Future<_LiveRoomData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LiveRoomData> _load() async {
    final room = (await _roomRepo.getRoom(widget.roomId)).room;
    final fixtures = await FootballApiService.getFixtures(
      league: room.leagueId,
      season: FootballConfig.currentSeason(),
      live: 'all',
    );
    return _LiveRoomData(fixtures: fixtures);
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
        title: const Text('Room Live'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_LiveRoomData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data;
          if (data == null) return const SizedBox.shrink();

          if (data.fixtures.isEmpty) {
            return const Center(child: Text('No live matches in this room league.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.fixtures.length,
              itemBuilder: (context, i) {
                final f = data.fixtures[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        if (f.homeLogo != null) Padding(padding: const EdgeInsets.only(right: 8), child: Image.network(f.homeLogo!, width: 20, height: 20)),
                        Expanded(child: Text('${f.homeTeam} vs ${f.awayTeam}', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (f.awayLogo != null) Padding(padding: const EdgeInsets.only(left: 8), child: Image.network(f.awayLogo!, width: 20, height: 20)),
                      ],
                    ),
                    subtitle: Text(
                      '${f.minute != null ? "${f.minute}′" : (f.statusLong ?? f.status ?? "")} • ${f.date != null ? df.format(f.date!.toLocal()) : ""}',
                    ),
                    trailing: Text(
                      '${f.homeGoals ?? '-'} - ${f.awayGoals ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    children: [
                      FutureBuilder<_FixtureLiveExtra>(
                        future: _loadFixtureExtra(f.id),
                        builder: (context, extraSnap) {
                          if (extraSnap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            );
                          }
                          final extra = extraSnap.data;
                          if (extra == null) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Live details unavailable right now.'),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _kv('Shots', '${extra.homeShots} - ${extra.awayShots}'),
                                _kv('Shots on goal', '${extra.homeShotsOnGoal} - ${extra.awayShotsOnGoal}'),
                                _kv('Red Cards', '${extra.homeRedCards} - ${extra.awayRedCards}'),
                                _kv('Yellow Cards', '${extra.homeYellowCards} - ${extra.awayYellowCards}'),
                                _kv('Goal scorers', extra.goalScorersText),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<_FixtureLiveExtra> _loadFixtureExtra(int fixtureId) async {
    final stats = await FootballApiService.getFixtureStatistics(fixtureId: fixtureId);
    final events = await FootballApiService.getFixtureEvents(fixtureId: fixtureId);

    int homeShots = 0, awayShots = 0;
    int homeOn = 0, awayOn = 0;
    int homeRed = 0, awayRed = 0;
    int homeYellow = 0, awayYellow = 0;

    if (stats.isNotEmpty) {
      final a = stats.first;
      homeShots = a.shotsTotal;
      homeOn = a.shotsOnGoal;
      homeRed = a.redCards;
      homeYellow = a.yellowCards;
      if (stats.length > 1) {
        final b = stats[1];
        awayShots = b.shotsTotal;
        awayOn = b.shotsOnGoal;
        awayRed = b.redCards;
        awayYellow = b.yellowCards;
      }
    }

    final goals = events
        .where((e) => e.type.toLowerCase() == 'goal')
        .map((e) {
          final m = e.elapsedMinute != null ? '${e.elapsedMinute}′ ' : '';
          final extra = e.detail.toLowerCase().contains('penalty') ? ' (Pen)' : '';
          return '$m${e.playerName ?? 'Unknown'}$extra (${e.teamName})';
        })
        .toList();

    return _FixtureLiveExtra(
      homeShots: homeShots,
      awayShots: awayShots,
      homeShotsOnGoal: homeOn,
      awayShotsOnGoal: awayOn,
      homeRedCards: homeRed,
      awayRedCards: awayRed,
      homeYellowCards: homeYellow,
      awayYellowCards: awayYellow,
      goalScorersText: goals.isEmpty ? 'No goals yet' : goals.join('\n'),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

class _LiveRoomData {
  final List<FixtureModel> fixtures;
  const _LiveRoomData({required this.fixtures});
}

class _FixtureLiveExtra {
  final int homeShots;
  final int awayShots;
  final int homeShotsOnGoal;
  final int awayShotsOnGoal;
  final int homeRedCards;
  final int awayRedCards;
  final int homeYellowCards;
  final int awayYellowCards;
  final String goalScorersText;

  const _FixtureLiveExtra({
    required this.homeShots,
    required this.awayShots,
    required this.homeShotsOnGoal,
    required this.awayShotsOnGoal,
    required this.homeRedCards,
    required this.awayRedCards,
    required this.homeYellowCards,
    required this.awayYellowCards,
    required this.goalScorersText,
  });
}
