import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

Future<void> _showUsersManagementDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Manage Users'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: FutureBuilder(
          future: ApiClient.instance.get('/admin/users'),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final users = snap.data?.data as List? ?? [];
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return ListTile(
                  title: Text(u['username']),
                  subtitle: Text('Points: ${u['total_points']} | Premium: ${u['is_premium']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    onPressed: () async {
                      final ctrl = TextEditingController(text: u['total_points'].toString());
                      final newPoints = await showDialog<String>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Edit ${u['username']} Points'),
                          content: TextField(controller: ctrl, keyboardType: TextInputType.number),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Save')),
                          ],
                        ),
                      );
                      if (newPoints != null && int.tryParse(newPoints) != null) {
                        try {
                          await ApiClient.instance.put('/admin/users/${u['id']}/points', data: {'points': int.parse(newPoints)});
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points updated!')));
                        } catch (_) {}
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
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
