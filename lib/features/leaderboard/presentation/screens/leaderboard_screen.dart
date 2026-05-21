import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/localization/app_localizations.dart';

// Leaderboard entry model
class LeaderboardEntry {
  final int rank;
  final int userId;
  final String username;
  final num totalPoints;
  final int exactScores;
  final int correctResults;
  final int totalPredictions;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.exactScores,
    required this.correctResults,
    required this.totalPredictions,
    this.avatarUrl,
  });

  static num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    return LeaderboardEntry(
      rank: rank,
      userId: json['id'] as int,
      username: json['username'] as String,
      totalPoints: _toNum(json['total_points']),
      exactScores: _toNum(json['exact_scores']).toInt(),
      correctResults: _toNum(json['correct_results']).toInt(),
      totalPredictions: _toNum(json['total_predictions']).toInt(),
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, int>((ref, leagueId) async {
  final response = await ApiClient.instance.get('/leaderboard', params: {'league_id': leagueId});
  final list = response.data as List;
  final entries = list.asMap().entries
      .map((e) => LeaderboardEntry.fromJson(e.value as Map<String, dynamic>, e.key + 1))
      .toList();

  final currentUser = ref.read(authStateProvider).value;
  if (currentUser != null && !entries.any((e) => e.userId == currentUser.id)) {
    entries.add(
      LeaderboardEntry(
        rank: entries.length + 1,
        userId: currentUser.id,
        username: currentUser.username,
        totalPoints: currentUser.totalPoints,
        exactScores: currentUser.exactScores,
        correctResults: currentUser.correctResults,
        totalPredictions: currentUser.totalPredictions,
        avatarUrl: currentUser.avatarUrl,
      ),
    );
  }
  return entries;
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _selectedLeagueId = 39;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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

  static const _leagues = [
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

  Future<void> _refresh() async {
    return ref.refresh(leaderboardProvider(_selectedLeagueId).future);
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(_selectedLeagueId));
    final currentUser = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/leaderboard_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.refresh(leaderboardProvider(_selectedLeagueId)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: Colors.white, size: 36),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Leaderboard'.tr(ref),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              (_leagues.firstWhere((e) => e['id'] == _selectedLeagueId)['name'] as String).tr(ref),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _leagues.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final l = _leagues[index];
                    final id = l['id'] as int;
                    final name = l['name'] as String;
                    final selected = _selectedLeagueId == id;
                    return ChoiceChip(
                      label: Text(name.tr(ref)),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedLeagueId = id);
                      },
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        body: leaderboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 12),
                Text('Failed to load'.tr(ref), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(leaderboardProvider(_selectedLeagueId)),
                  child: Text('Retry'.tr(ref)),
                ),
              ],
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.leaderboard_rounded, size: 80, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 16),
                    Text('No rankings yet'.tr(ref)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  // Top 3 podium
                  if (entries.length >= 3)
                    SliverToBoxAdapter(
                      child: _Podium(entries: entries.take(3).toList(), leagueId: _selectedLeagueId)
                          .animate()
                          .slideY(begin: 0.1, duration: 500.ms)
                          .fadeIn(duration: 400.ms),
                    ),

                  // Rest of list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries.length >= 3
                              ? entries[index + 3]
                              : entries[index];
                          final isMe = entry.userId == currentUser?.id;
                          return _LeaderboardRow(
                            entry: entry,
                            isCurrentUser: isMe,
                            index: index,
                            leagueId: _selectedLeagueId,
                          );
                        },
                        childCount: entries.length >= 3
                            ? entries.length - 3
                            : entries.length,
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final int leagueId;
  const _Podium({required this.entries, required this.leagueId});

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Container(
      margin: const EdgeInsets.all(16),
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
          _PodiumItem(entry: second, height: 80,
              bgColor: AppColors.silver.withOpacity(0.2),
              medal: '🥈', offset: 0, leagueId: leagueId),
          // 1st place
          _PodiumItem(entry: first, height: 110,
              bgColor: AppColors.gold.withOpacity(0.2),
              medal: '🥇', offset: -20, leagueId: leagueId),
          // 3rd place
          _PodiumItem(entry: third, height: 60,
              bgColor: AppColors.bronze.withOpacity(0.2),
              medal: '🥉', offset: 0, leagueId: leagueId),
        ],
      ),
    );
  }
}

String _formatPoints(num pts) {
  return pts % 1 == 0 ? pts.toInt().toString() : pts.toStringAsFixed(2);
}

class _PodiumItem extends ConsumerWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color bgColor;
  final String medal;
  final double offset;
  final int leagueId;

  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.bgColor,
    required this.medal,
    required this.offset,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final lid = leagueId == 0 ? '' : '&leagueId=$leagueId';
        context.push('/public-profile/${entry.userId}?name=${Uri.encodeComponent(entry.username)}$lid');
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
            '${_formatPoints(entry.totalPoints)} ${'pts'.tr(ref)}',
            style: TextStyle(
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

class _LeaderboardRow extends ConsumerWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final int index;
  final int leagueId;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
    required this.index,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        final lid = leagueId == 0 ? '' : '&leagueId=$leagueId';
        context.push('/public-profile/${entry.userId}?name=${Uri.encodeComponent(entry.username)}$lid');
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
                '#${entry.rank}',
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
              backgroundImage: entry.avatarUrl != null
                  ? (entry.avatarUrl!.startsWith('data:image')
                      ? MemoryImage(base64Decode(entry.avatarUrl!.split(',').last)) as ImageProvider
                      : NetworkImage(entry.avatarUrl!))
                  : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.username,
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
                          child: Text('YOU'.tr(ref),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${entry.exactScores}🎯 ${entry.correctResults}✅ · ${entry.totalPredictions} ${'predictions'.tr(ref)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                _formatPoints(entry.totalPoints),
                style: const TextStyle(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ).animate().slideX(
          begin: 0.2,
          duration: 300.ms,
          delay: Duration(milliseconds: index * 40),
        ).fadeIn(duration: 250.ms, delay: Duration(milliseconds: index * 40));
  }
}

