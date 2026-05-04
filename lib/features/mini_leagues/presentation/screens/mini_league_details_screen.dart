import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/league_repository.dart';
import '../../models/mini_league_models.dart';

class MiniLeagueDetailsScreen extends ConsumerStatefulWidget {
  final LeagueModel league;

  const MiniLeagueDetailsScreen({
    super.key,
    required this.league,
  });

  @override
  ConsumerState<MiniLeagueDetailsScreen> createState() =>
      _MiniLeagueDetailsScreenState();
}

class _MiniLeagueDetailsScreenState extends ConsumerState<MiniLeagueDetailsScreen> {
  final _repo = LeagueRepository();
  late LeagueModel _league;
  late Future<List<LeagueLeaderboardRow>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _league = widget.league;
    _leaderboardFuture = _repo.getLeaderboard(league: _league);
  }

  Future<void> _refresh() async {
    setState(() {
      _leaderboardFuture = _repo.getLeaderboard(league: _league);
    });
    await _leaderboardFuture;
  }

  Future<void> _leave() async {
    final user = ref.read(authStateProvider).value;
    final userId = user?.id.toString() ?? 'local-user';
    await _repo.leaveLeague(leagueId: _league.leagueId, userId: userId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_league.leagueName),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Leave league',
            onPressed: _leave,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: 'Invite code',
            value: _league.inviteCode,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Members',
            value: '${_league.members.length} / ${_league.maxMembers}',
          ),
          const SizedBox(height: 16),
          const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          FutureBuilder<List<LeagueLeaderboardRow>>(
            future: _leaderboardFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Error: ${snap.error}'),
                );
              }
              final rows = snap.data ?? [];
              if (rows.isEmpty) return const Text('No leaderboard data yet.');

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    return ListTile(
                      leading: Text(
                        '#${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      title: Text(r.username),
                      subtitle: Text('User: ${r.userId}'),
                      trailing: Text(
                        '${r.points} pts',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Members', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _league.members.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = _league.members[i];
                return ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
        trailing: IconButton(
          tooltip: 'Copy',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied')),
            );
          },
          icon: const Icon(Icons.copy_rounded),
        ),
      ),
    );
  }
}

