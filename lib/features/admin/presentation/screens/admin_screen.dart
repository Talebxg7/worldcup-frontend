import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../matches/data/models/match_model.dart';

final adminMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final response = await ApiClient.instance.get('/matches');
  final list = response.data as List;
  return list.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(adminMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.add_circle_rounded,
                          title: 'Add Match',
                          subtitle: 'Schedule match',
                          color: AppColors.primary,
                          onTap: () => context.push('/admin/add-match'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Grant Premium',
                          subtitle: 'Free mini leagues',
                          color: Colors.amber,
                          onTap: () => _showGrantPremiumDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.people_alt_rounded,
                          title: 'Users',
                          subtitle: 'Points & Bans',
                          color: Colors.blue,
                          onTap: () => _showUsersManagementDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.campaign_rounded,
                          title: 'Announce',
                          subtitle: 'Global Push',
                          color: Colors.purple,
                          onTap: () => _showAnnounceDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.attach_money_rounded,
                          title: 'Revenue',
                          subtitle: 'Financial Stats',
                          color: Colors.green,
                          onTap: () => _showRevenueDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.emoji_events_rounded,
                          title: 'Leagues',
                          subtitle: 'Manage Leagues',
                          color: Colors.orange,
                          onTap: () => context.push('/admin/manage-leagues'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.rate_review_rounded,
                          title: 'Feedbacks',
                          subtitle: 'User Reviews & Bugs',
                          color: const Color(0xFF0284C7),
                          onTap: () => _showFeedbackViewerDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.published_with_changes_rounded,
                          title: 'Close Season 1',
                          subtitle: 'Award bonus points',
                          color: Colors.redAccent,
                          onTap: () => _showCloseSeasonDialog(context, ref),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.sync_rounded,
                          title: 'Sync Players',
                          subtitle: 'Fetch scorers from API',
                          color: Colors.teal,
                          onTap: () => _showSyncPlayersDialog(context, ref),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Matches — Enter Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Match list for entering results
          matchesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (matches) {
              final upcoming = matches.where((m) => m.status == MatchStatus.upcoming).toList();
              final live = matches.where((m) => m.status == MatchStatus.live).toList();
              final finished = matches.where((m) => m.status == MatchStatus.finished).toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (live.isNotEmpty) ...[
                      _SectionHeader(title: '🔴 Live', count: live.length),
                      ...live.asMap().entries.map(
                        (e) => _AdminMatchTile(match: e.value, index: e.key, ref: ref),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      _SectionHeader(title: '⏰ Upcoming', count: upcoming.length),
                      ...upcoming.asMap().entries.map(
                        (e) => _AdminMatchTile(match: e.value, index: e.key, ref: ref),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (finished.isNotEmpty) ...[
                      _SectionHeader(title: '✅ Finished', count: finished.length),
                      ...finished.asMap().entries.map(
                        (e) => _AdminMatchTile(match: e.value, index: e.key, ref: ref),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _AdminMatchTile extends StatelessWidget {
  final MatchModel match;
  final int index;
  final WidgetRef ref;

  const _AdminMatchTile({required this.match, required this.index, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasResult = match.homeScore != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '${match.homeTeamFlag} ${match.homeTeam}  vs  ${match.awayTeam} ${match.awayTeamFlag}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.displayStage),
            if (hasResult)
              Text('Result: ${match.homeScore} - ${match.awayScore}',
                  style: const TextStyle(color: AppColors.exactScore, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.status == MatchStatus.upcoming)
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                color: AppColors.primary,
                tooltip: 'Override Match',
                onPressed: () => _showOverrideMatchDialog(context, match, ref),
              ),
            match.status != MatchStatus.finished
                ? ElevatedButton(
                    onPressed: () =>
                        context.push('/admin/enter-result/${match.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasResult ? AppColors.secondary : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      hasResult ? 'Update' : 'Result',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Done ✅', style: TextStyle(fontSize: 12, color: Colors.green)),
                  ),
          ],
        ),
      ),
    ).animate().slideX(
          begin: 0.2,
          duration: 300.ms,
          delay: Duration(milliseconds: index * 30),
        ).fadeIn(duration: 250.ms, delay: Duration(milliseconds: index * 30));
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showGrantPremiumDialog(BuildContext context) async {
  final controller = TextEditingController();
  bool loading = false;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Grant Premium Access'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Premium users can create unlimited Mini-Leagues without paying.'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final identifier = controller.text.trim();
                        if (identifier.isEmpty) return;

                        setState(() => loading = true);
                        try {
                          await ApiClient.instance.post(
                            '/admin/grant-premium',
                            data: {'identifier': identifier},
                          );
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Premium granted to $identifier!')),
                          );
                        } catch (e) {
                          setState(() => loading = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Grant Access'),
              ),
            ],
          );
        },
      );
    },
  );
}

const List<Map<String, dynamic>> _leaguesForPoints = [
  {'id': 0, 'name': 'Global / General'},
  {'id': 39, 'name': 'Premier League'},
  {'id': 140, 'name': 'La Liga'},
  {'id': 135, 'name': 'Serie A'},
  {'id': 78, 'name': 'Bundesliga'},
  {'id': 61, 'name': 'Ligue 1'},
  {'id': 2, 'name': 'Champions League'},
  {'id': 3, 'name': 'Europa League'},
  {'id': 6, 'name': 'AFCON'},
  {'id': 9, 'name': 'Copa America'},
  {'id': 1, 'name': 'World Cup'},
  {'id': 307, 'name': 'Saudi Pro League'},
  {'id': 269, 'name': 'Qatar Stars League'},
  {'id': 387, 'name': 'Jordanian Pro League'},
  {'id': 200, 'name': 'Botola Pro'},
  {'id': 542, 'name': 'Iraqi League'},
];

Future<void> _showUsersManagementDialog(BuildContext context) async {
  final searchCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Users'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by username or email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                searchCtrl.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder(
                      future: ApiClient.instance.get(
                        '/admin/users',
                        params: searchCtrl.text.trim().isNotEmpty
                            ? {'search': searchCtrl.text.trim()}
                            : null,
                      ),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}'));
                        }
                        final users = snap.data?.data as List? ?? [];
                        if (users.isEmpty) {
                          return const Center(child: Text('No users found'));
                        }
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, i) {
                            final u = users[i];
                            
                            // Clean up decimal point display if it is a round number
                            final ptsRaw = u['total_points'];
                            final ptsDouble = double.tryParse(ptsRaw?.toString() ?? '0') ?? 0.0;
                            final ptsString = ptsDouble % 1 == 0 
                                ? ptsDouble.toInt().toString() 
                                : ptsDouble.toStringAsFixed(2);

                            return ListTile(
                              title: Row(
                                children: [
                                  Text(u['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (u['is_verified'] == true)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                                    ),
                                ],
                              ),
                              subtitle: Text('${u['email']}\nPoints: $ptsString | Premium: ${u['is_premium']}'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.push_pin_rounded, size: 18),
                                color: AppColors.primary,
                                tooltip: 'Award/Adjust Points',
                                onPressed: () async {
                                  int selectedLeagueId = 0; // Default to Global
                                  final pointsCtrl = TextEditingController();
                                  final reasonCtrl = TextEditingController();

                                  await showDialog(
                                    context: context,
                                    builder: (c) {
                                      return StatefulBuilder(
                                        builder: (context, setSubState) {
                                          return AlertDialog(
                                            title: Text('Adjust Points for ${u['username']}'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Select which league to award/deduct points for:',
                                                    style: TextStyle(fontSize: 13, color: Colors.grey),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  DropdownButtonFormField<int>(
                                                    value: selectedLeagueId,
                                                    decoration: const InputDecoration(
                                                      labelText: 'League',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    items: _leaguesForPoints.map((l) {
                                                      return DropdownMenuItem<int>(
                                                        value: l['id'] as int,
                                                        child: Text(l['name'] as String),
                                                      );
                                                    }).toList(),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setSubState(() => selectedLeagueId = val);
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                    controller: pointsCtrl,
                                                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                                    decoration: const InputDecoration(
                                                      labelText: 'Points to Add (use minus to deduct)',
                                                      hintText: 'e.g., 5 or -2',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                    controller: reasonCtrl,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Reason (Optional)',
                                                      hintText: 'e.g., Bonus points, correction',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(c),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final pointsText = pointsCtrl.text.trim();
                                                  if (pointsText.isEmpty) return;

                                                  final parsedPoints = double.tryParse(pointsText);
                                                  if (parsedPoints == null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Please enter a valid number')),
                                                    );
                                                    return;
                                                  }

                                                  try {
                                                    await ApiClient.instance.put(
                                                      '/admin/users/${u['id']}/points',
                                                      data: {
                                                        'points': parsedPoints,
                                                        'league_id': selectedLeagueId,
                                                        'reason': reasonCtrl.text.trim(),
                                                      },
                                                    );
                                                    if (!context.mounted) return;
                                                    Navigator.pop(c); // Close point adjust dialog
                                                    Navigator.pop(ctx); // Close manage users dialog
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Points updated successfully for ${u['username']}!')),
                                                    );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to adjust points: $e')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
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
            ],
          );
        },
      );
    },
  );
}

Future<void> _showAnnounceDialog(BuildContext context) async {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  bool loading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Send Global Push'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Notification Title')),
            const SizedBox(height: 8),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message Body')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: loading ? null : () async {
              if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
              setState(() => loading = true);
              try {
                await ApiClient.instance.post('/admin/announce', data: {'title': titleCtrl.text, 'body': bodyCtrl.text});
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement Sent!')));
              } catch (_) {
                setState(() => loading = false);
              }
            },
            child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showRevenueDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Revenue Dashboard'),
      content: FutureBuilder(
        future: ApiClient.instance.get('/admin/revenue'),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          if (snap.hasError) return Text('Error: ${snap.error}');
          final data = snap.data?.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.group_work_rounded, color: Colors.blue, size: 36),
                title: const Text('Total Paid Rooms'),
                trailing: Text('${data['totalPaidRooms']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.attach_money_rounded, color: Colors.green, size: 36),
                title: const Text('Gross Revenue'),
                trailing: Text('\$${data['totalRevenueUSD']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
          );
        },
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
  );
}

Future<void> _showOverrideMatchDialog(BuildContext context, MatchModel match, WidgetRef ref) async {
  String selectedStatus = match.status.name;
  bool loading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Override Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.homeTeam} vs ${match.awayTeam}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Status:'),
            DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: ['upcoming', 'live', 'finished', 'cancelled'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => selectedStatus = v);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: loading ? null : () async {
              setState(() => loading = true);
              try {
                await ApiClient.instance.put('/admin/matches/${match.id}/override', data: {'status': selectedStatus});
                if (!context.mounted) return;
                ref.invalidate(adminMatchesProvider);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match overridden!')));
              } catch (_) {
                setState(() => loading = false);
              }
            },
            child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showCloseSeasonDialog(BuildContext context, WidgetRef ref) async {
  bool loading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Close Season 1'),
        content: const Text(
          'Are you sure you want to close Season 1 standings and award carry-over points for Season 2?\n\n'
          'Top 5 players in each league will receive starting bonus points:\n'
          '• Rank 1: +10 pts\n'
          '• Rank 2: +7 pts\n'
          '• Rank 3: +5 pts\n'
          '• Rank 4: +3 pts\n'
          '• Rank 5: +2 pts',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: loading ? null : () async {
              setState(() => loading = true);
              try {
                final response = await ApiClient.instance.post('/challenge/close-season');
                if (!context.mounted) return;
                Navigator.pop(ctx);
                
                final details = response.data['details'] as List?;
                final count = details?.length ?? 0;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Season 1 closed! Seeded starting rewards for $count players!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setState(() => loading = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to close season: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showSyncPlayersDialog(BuildContext context, WidgetRef ref) async {
  bool loading = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sync Players from API-Sports'),
        content: const Text(
          'This will fetch top goalscorers for all active leagues from API-Sports in the background.\n\n'
          'It may take 1-2 minutes to populate all leagues. The process runs on the server.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: loading ? null : () async {
              setState(() => loading = true);
              try {
                final response = await ApiClient.instance.post('/challenge/sync-players');
                if (!context.mounted) return;
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response.data['message'] ?? 'Sync started successfully!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              } catch (e) {
                setState(() => loading = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start sync: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sync'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showFeedbackViewerDialog(BuildContext context) async {
  String selectedCategory = 'All';

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
  }
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
        final borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0);

        final categories = ['All', 'Feature Request', 'Bug Report', 'UI & Design', 'Performance', 'General'];

        return Dialog(
          backgroundColor: bgColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: Color(0xFF38BDF8), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Feedbacks',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            Text(
                              'Live suggestions, bug reports & ratings',
                              style: GoogleFonts.outfit(fontSize: 12, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => setState(() => selectedCategory = cat),
                            selectedColor: const Color(0xFF0284C7),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : textColor,
                            ),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF38BDF8) : borderColor,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Live Feedbacks List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('feedback')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading feedbacks: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final filteredDocs = selectedCategory == 'All'
                            ? docs
                            : docs.where((d) => d.data()['category'] == selectedCategory).toList();

                        if (filteredDocs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 48, color: secondaryTextColor),
                                const SizedBox(height: 12),
                                Text(
                                  selectedCategory == 'All'
                                      ? 'No feedbacks submitted yet'
                                      : 'No feedbacks in "$selectedCategory"',
                                  style: GoogleFonts.outfit(color: secondaryTextColor, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data();
                            final username = data['username'] as String? ?? 'Anonymous';
                            final email = data['email'] as String? ?? '';
                            final category = data['category'] as String? ?? 'General';
                            final rating = data['rating'] as int? ?? 5;
                            final message = data['message'] as String? ?? '';
                            final platform = data['platform'] as String? ?? 'Web';
                            
                            String formattedDate = '';
                            final timestamp = data['createdAt'] as Timestamp?;
                            if (timestamp != null) {
                              formattedDate = DateFormat('MMM d, y • h:mm a').format(timestamp.toDate());
                            } else if (data['dateString'] != null) {
                              try {
                                formattedDate = DateFormat('MMM d, y • h:mm a').format(DateTime.parse(data['dateString']));
                              } catch (_) {}
                            }

                            Color categoryColor = const Color(0xFF38BDF8);
                            if (category == 'Bug Report') categoryColor = Colors.redAccent;
                            if (category == 'Feature Request') categoryColor = Colors.amber;
                            if (category == 'Performance') categoryColor = Colors.orangeAccent;
                            if (category == 'UI & Design') categoryColor = Colors.purpleAccent;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: User Info & Actions
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: categoryColor.withOpacity(0.2),
                                        child: Text(
                                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                          style: GoogleFonts.outfit(
                                            color: categoryColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  username,
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: categoryColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: categoryColor.withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    category,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: categoryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (email.isNotEmpty)
                                              Text(
                                                email,
                                                style: GoogleFonts.outfit(fontSize: 11, color: secondaryTextColor),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Stars
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 16,
                                            color: starIdx < rating ? const Color(0xFFF59E0B) : secondaryTextColor.withOpacity(0.4),
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 4),

                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: 'Dismiss / Delete',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dCtx) => AlertDialog(
                                              title: const Text('Delete Feedback?'),
                                              content: const Text('Are you sure you want to delete this feedback item?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dCtx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                  onPressed: () => Navigator.pop(dCtx, true),
                                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await doc.reference.delete();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Feedback Message
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: SelectableText(
                                      message,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: textColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Metadata Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: GoogleFonts.outfit(fontSize: 11, color: secondaryTextColor),
                                      ),
                                      Text(
                                        'Platform: $platform',
                                        style: GoogleFonts.outfit(fontSize: 11, color: secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
