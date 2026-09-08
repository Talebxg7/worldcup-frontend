import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../data/room_repository.dart';
import '../../models/room_models.dart';
import '../../../matches/presentation/screens/prediction_fixtures_screen.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../competitions/presentation/widgets/league_challenge_banner.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final int roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
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

  Future<void> _openSettings(RoomDetailsModel details, {bool canDelete = false}) async {
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
                                    try {
                                      await _repo.kickMember(
                                        roomId: details.room.id,
                                        userId: m.userId,
                                      );
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      await _refresh();
                                    } catch (e) {
                                      final errorMsg = e is DioException
                                          ? ApiException.fromDioError(e).message
                                          : e.toString();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to kick member: $errorMsg')),
                                      );
                                    }
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
              if (canDelete)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteRoom();
                  },
                  child: const Text('Delete Room'),
                ),
              if (canDelete) const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await _repo.updateMaxMembers(
                      roomId: details.room.id,
                      maxMembers: maxMembers,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await _refresh();
                  } catch (e) {
                    final errorMsg = e is DioException
                        ? ApiException.fromDioError(e).message
                        : e.toString();
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to update: $errorMsg')),
                    );
                  }
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

  Future<void> _leaveRoom() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.leaveRoom(widget.roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left the room')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is DioException
            ? ApiException.fromDioError(e).message
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave room: $errorMsg')),
        );
      }
    }
  }

  Future<void> _deleteRoom() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room? This action cannot be undone and will permanently remove the room for all members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Room'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteRoom(widget.roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room deleted successfully')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is DioException
            ? ApiException.fromDioError(e).message
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete room: $errorMsg')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    final currentUser = ref.watch(authStateProvider).value;
    final isAdmin = currentUser?.isAdmin == true;

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'This room is no longer available or has been deleted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to My Leagues'),
                    ),
                  ],
                ),
              ),
            );
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
                            const Text(
                              'Join code: ',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            SelectableText(
                              room.joinCode,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.amberAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: room.joinCode),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code copied')),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copy Code'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  final shareText = 'Join my private room "${room.name}" on Who Will Win!\nJoin code: ${room.joinCode}\nhttps://whowillwinapp.com';
                                  Share.share(shareText);
                                },
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: const Text('Share Code'),
                              ),
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
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PredictionFixturesScreen(
                                      leagueId: room.leagueId,
                                      leagueName: room.leagueName,
                                      roomId: room.id,
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  _refresh();
                                }
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
                                onPressed: () => _openSettings(data.details, canDelete: room.isHost || isAdmin),
                                icon: const Icon(Icons.settings_rounded),
                                label: const Text('Settings'),
                              ),
                            if (room.isHost || isAdmin)
                              OutlinedButton.icon(
                                onPressed: _deleteRoom,
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                label: const Text('Delete Room', style: TextStyle(color: Colors.redAccent)),
                              ),
                            if (!room.isHost)
                              OutlinedButton.icon(
                                onPressed: _leaveRoom,
                                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                                label: const Text('Leave', style: TextStyle(color: Colors.redAccent)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (room.leagueId != null) ...[
                  const SizedBox(height: 12),
                  LeagueChallengeBanner(leagueId: room.leagueId),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Private Leaderboard',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (data.leaderboard.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No rankings yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (data.leaderboard.length >= 3)
                    _RoomPodium(
                      entries: data.leaderboard.take(3).toList(),
                      roomId: widget.roomId,
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: data.leaderboard.length >= 3
                            ? data.leaderboard.length - 3
                            : data.leaderboard.length,
                        itemBuilder: (context, index) {
                          final r = data.leaderboard.length >= 3
                              ? data.leaderboard[index + 3]
                              : data.leaderboard[index];
                          final currentUserId = ref.watch(authStateProvider).value?.id;
                          final isMe = r.userId == currentUserId;

                          return _RoomLeaderboardRow(
                            row: r,
                            isCurrentUser: isMe,
                            index: index,
                            roomId: widget.roomId,
                          );
                        },
                      ),
                    ),
                  ),
                ],
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
                      
                      final cardKey = GlobalKey();
                      return RepaintBoundary(
                        key: cardKey,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Match Header
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (first.homeTeamFlag != null) ...[
                                            ClipOval(child: Image.network(first.homeTeamFlag!, width: 28, height: 28, fit: BoxFit.cover)),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Text(
                                              first.homeTeam,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10),
                                            child: Text('VS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 12)),
                                          ),
                                          Flexible(
                                            child: Text(
                                              first.awayTeam,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (first.awayTeamFlag != null) ...[
                                            const SizedBox(width: 8),
                                            ClipOval(child: Image.network(first.awayTeamFlag!, width: 28, height: 28, fit: BoxFit.cover)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share_rounded, size: 20),
                                      tooltip: 'Share Match Predictions',
                                      onPressed: () async {
                                        final buffer = StringBuffer();
                                        buffer.writeln('⚽ ${first.homeTeam} vs ${first.awayTeam} — ${data.details.room.name}');
                                        if (first.status == 'finished' && first.actualHomeScore != null) {
                                          buffer.writeln('Final Score: ${first.actualHomeScore} - ${first.actualAwayScore}');
                                        }
                                        buffer.writeln();
                                        buffer.writeln('Room Predictions:');
                                        for (final p in preds) {
                                          if (p.hidden) {
                                            buffer.writeln('• ${p.username}: Prediction Hidden');
                                          } else {
                                            final ptsStr = p.pointsEarned != null ? ' (${p.pointsEarned! >= 0 ? '+' : ''}${p.pointsEarned} pts)' : '';
                                            buffer.writeln('• ${p.username}: ${p.homeScore}-${p.awayScore}$ptsStr');
                                          }
                                        }
                                        buffer.writeln();
                                        buffer.writeln('Join our room on Who Will Win! Code: ${data.details.room.joinCode}');

                                        final textSummary = buffer.toString();

                                        try {
                                          final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                                          if (boundary != null) {
                                            final image = await boundary.toImage(pixelRatio: 3.0);
                                            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                                            if (byteData != null) {
                                              final bytes = byteData.buffer.asUint8List();
                                              final xFile = XFile.fromData(
                                                bytes,
                                                mimeType: 'image/png',
                                                name: 'match_${first.matchId}_predictions.png',
                                              );
                                              await Share.shareXFiles(
                                                [xFile],
                                                text: textSummary,
                                              );
                                              return;
                                            }
                                          }
                                        } catch (err) {
                                          debugPrint('Image share failed: $err');
                                        }

                                        Share.share(textSummary);
                                      },
                                    ),
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
                                                context.push(
                                                  '/public-profile/${p.userId}?name=${Uri.encodeComponent(p.username)}&roomId=${widget.roomId}',
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                                    backgroundImage: p.avatarUrl != null
                                                        ? (p.avatarUrl!.startsWith('data:image')
                                                            ? MemoryImage(base64Decode(p.avatarUrl!.split(',').last)) as ImageProvider
                                                            : NetworkImage(p.avatarUrl!))
                                                        : null,
                                                    child: p.avatarUrl == null
                                                        ? Text(
                                                            p.username.isNotEmpty ? p.username[0].toUpperCase() : '?',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '(${p.username})', 
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold, 
                                                      color: Theme.of(context).colorScheme.primary,
                                                      decoration: TextDecoration.underline,
                                                    )
                                                  ),
                                                ],
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

class _RoomPodium extends StatelessWidget {
  final List<RoomLeaderboardRowModel> entries;
  final int roomId;
  const _RoomPodium({required this.entries, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _RoomPodiumItem(entry: second, height: 80,
              bgColor: AppColors.silver.withOpacity(0.2),
              medal: '🥈', offset: 0, roomId: roomId),
          // 1st place
          _RoomPodiumItem(entry: first, height: 110,
              bgColor: AppColors.gold.withOpacity(0.2),
              medal: '🥇', offset: -20, roomId: roomId),
          // 3rd place
          _RoomPodiumItem(entry: third, height: 60,
              bgColor: AppColors.bronze.withOpacity(0.2),
              medal: '🥉', offset: 0, roomId: roomId),
        ],
      ),
    );
  }
}

class _RoomPodiumItem extends StatelessWidget {
  final RoomLeaderboardRowModel entry;
  final double height;
  final Color bgColor;
  final String medal;
  final double offset;
  final int roomId;

  const _RoomPodiumItem({
    required this.entry,
    required this.height,
    required this.bgColor,
    required this.medal,
    required this.offset,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/public-profile/${entry.userId}?name=${Uri.encodeComponent(entry.username)}&roomId=$roomId');
      },
      child: Transform.translate(
        offset: Offset(0, offset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(medal, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: bgColor,
              backgroundImage: entry.avatarUrl != null
                  ? (entry.avatarUrl!.startsWith('data:image')
                      ? MemoryImage(base64Decode(entry.avatarUrl!.split(',').last)) as ImageProvider
                      : NetworkImage(entry.avatarUrl!))
                  : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              entry.username,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${entry.points} pts',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: height,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomLeaderboardRow extends StatelessWidget {
  final RoomLeaderboardRowModel row;
  final bool isCurrentUser;
  final int index;
  final int roomId;

  const _RoomLeaderboardRow({
    required this.row,
    required this.isCurrentUser,
    required this.index,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          '/public-profile/${row.userId}?name=${Uri.encodeComponent(row.username)}&roomId=$roomId',
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isCurrentUser
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.08)
              : Theme.of(context).cardTheme.color,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  '#${row.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isCurrentUser ? AppColors.primary : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: isCurrentUser
                    ? AppColors.primary
                    : AppColors.secondary.withOpacity(0.2),
                backgroundImage: row.avatarUrl != null
                    ? (row.avatarUrl!.startsWith('data:image')
                        ? MemoryImage(base64Decode(row.avatarUrl!.split(',').last)) as ImageProvider
                        : NetworkImage(row.avatarUrl!))
                    : null,
                child: row.avatarUrl == null
                    ? Text(
                        row.username.isNotEmpty ? row.username[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isCurrentUser ? Colors.white : AppColors.secondary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Row(
                  children: [
                    Text(
                      row.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isCurrentUser ? AppColors.primary : null,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('YOU',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),

              // Points
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${row.points} pts',
                  style: const TextStyle(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
