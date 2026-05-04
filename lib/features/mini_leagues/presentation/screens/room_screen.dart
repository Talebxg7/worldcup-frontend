import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/room_repository.dart';
import '../../models/room_models.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../matches/presentation/screens/prediction_fixtures_screen.dart';

class RoomScreen extends StatefulWidget {
  final int roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _repo = RoomRepository();
  late Future<_RoomBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RoomBundle> _load() async {
    final details = await _repo.getRoom(widget.roomId);
    final leaderboard = await _repo.getLeaderboard(widget.roomId);
    return _RoomBundle(details: details, leaderboard: leaderboard);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openSettings(RoomDetailsModel details) async {
    var maxMembers = details.room.maxMembers;
    final controller = TextEditingController(text: '$maxMembers');
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Room settings'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Max members (1-20)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) {
                        maxMembers = parsed.clamp(1, 20);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Members',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: details.members.length,
                      itemBuilder: (context, i) {
                        final m = details.members[i];
                        final isHost = m.userId == details.room.hostId;
                        return ListTile(
                          dense: true,
                          title: Text(m.username),
                          subtitle: Text('User #${m.userId}${isHost ? ' (Host)' : ''}'),
                          trailing: isHost
                              ? null
                              : TextButton(
                                  onPressed: () async {
                                    await _repo.kickMember(
                                      roomId: details.room.id,
                                      userId: m.userId,
                                    );
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    await _refresh();
                                  },
                                  child: const Text('Kick'),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  await _repo.updateMaxMembers(
                    roomId: details.room.id,
                    maxMembers: maxMembers,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  await _refresh();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Room'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_RoomBundle>(
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
          final room = data.details.room;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('League: ${room.leagueName}'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Join code: ${room.joinCode}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: room.joinCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copied')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy Code'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Members: ${room.membersCount}/${room.maxMembers}'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PredictionFixturesScreen(
                                      leagueId: room.leagueId,
                                      leagueName: room.leagueName,
                                      roomId: room.id,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.sports_soccer_rounded),
                              label: const Text('Predict'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/room/${room.id}/live'),
                              icon: const Icon(Icons.live_tv_rounded),
                              label: const Text('Live'),
                            ),
                            if (room.isHost)
                              OutlinedButton.icon(
                                onPressed: () => _openSettings(data.details),
                                icon: const Icon(Icons.settings_rounded),
                                label: const Text('Settings'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Private Leaderboard',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        dense: true,
                        title: Text('Rank'),
                        trailing: SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Username'),
                              Text('Points'),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                        ...data.leaderboard.map(
                          (r) => ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(
                                    userId: r.userId,
                                    fallbackUsername: r.username,
                                    roomId: widget.roomId,
                                  ),
                                ),
                              );
                            },
                            dense: true,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundImage: (r.avatarUrl != null && r.avatarUrl!.startsWith('data:image'))
                                      ? MemoryImage(base64Decode(r.avatarUrl!.split(',').last))
                                      : null,
                                  child: (r.avatarUrl == null || !r.avatarUrl!.startsWith('data:image'))
                                      ? Text(
                                          r.username.isNotEmpty ? r.username[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text('#${r.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            title: Text(r.username),
                            trailing: Text('${r.points}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Prediction Visibility',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (data.details.predictions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No room predictions yet.'),
                    ),
                  )
                else
                  ...(() {
                    final grouped = <int, List<RoomPredictionPeekModel>>{};
                    for (final p in data.details.predictions) {
                      grouped.putIfAbsent(p.matchId, () => []).add(p);
                    }
                    return grouped.entries.map((e) {
                      final matchId = e.key;
                      final preds = e.value;
                      final first = preds.first;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Match Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (first.homeTeamFlag != null) ...[
                                    Image.network(first.homeTeamFlag!, width: 24, height: 24),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(first.homeTeam, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('vs', style: TextStyle(color: Colors.grey)),
                                  ),
                                  Text(first.awayTeam, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (first.awayTeamFlag != null) ...[
                                    const SizedBox(width: 8),
                                    Image.network(first.awayTeamFlag!, width: 24, height: 24),
                                  ],
                                ],
                              ),
                              if (first.status == 'finished') ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Final Score: ${first.actualHomeScore ?? '-'} - ${first.actualAwayScore ?? '-'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              
                              // Predictions List
                              ...preds.map((p) {
                                String winnerText = '';
                                if (!p.hidden && p.homeScore != null && p.awayScore != null) {
                                  if (p.homeScore! > p.awayScore!) winnerText = ' (${p.homeTeam} to win)';
                                  else if (p.awayScore! > p.homeScore!) winnerText = ' (${p.awayTeam} to win)';
                                  else winnerText = ' (Draw)';
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => PublicProfileScreen(
                                                      userId: p.userId,
                                                      fallbackUsername: p.username,
                                                      roomId: widget.roomId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                '(${p.username})', 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold, 
                                                  color: Theme.of(context).colorScheme.primary,
                                                  decoration: TextDecoration.underline,
                                                )
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                p.hidden 
                                                    ? 'Prediction Hidden' 
                                                    : '${p.homeScore}-${p.awayScore}$winnerText',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            if (p.pointsEarned != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (p.pointsEarned! > 0 ? Colors.green : (p.pointsEarned! < 0 ? Colors.red : Colors.grey)).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${p.pointsEarned! > 0 ? '+' : ''}${p.pointsEarned} pts',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.pointsEarned! > 0 ? Colors.greenAccent : (p.pointsEarned! < 0 ? Colors.redAccent : Colors.grey.shade300),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (!p.hidden && (p.joker == true || p.redCard == true || p.penalty == true)) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (p.joker == true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text('JOKER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                                                ),
                                              if (p.redCard == true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade800,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text('RED CARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                                ),
                                              if (p.penalty == true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade800,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text('PENALTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    });
                  })(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoomBundle {
  final RoomDetailsModel details;
  final List<RoomLeaderboardRowModel> leaderboard;

  const _RoomBundle({
    required this.details,
    required this.leaderboard,
  });
}
