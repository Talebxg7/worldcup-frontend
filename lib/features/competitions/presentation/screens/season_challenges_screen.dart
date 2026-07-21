import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/competition.dart';

class SeasonChallengesScreen extends ConsumerStatefulWidget {
  final int? roomId;
  const SeasonChallengesScreen({super.key, this.roomId});

  @override
  ConsumerState<SeasonChallengesScreen> createState() => _SeasonChallengesScreenState();
}

class _SeasonChallengesScreenState extends ConsumerState<SeasonChallengesScreen> {
  bool _isLoading = false;
  List<Competition> _leagues = [];
  Map<int, Map<String, dynamic>> _predictions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch enabled leagues
      final leaguesRes = await ApiClient.instance.get('/leagues');
      List<Competition> loadedLeagues = [];
      if (leaguesRes.data is List) {
        for (var item in leaguesRes.data) {
          loadedLeagues.add(Competition(
            name: item['name'] ?? '',
            subtitle: item['subtitle'] ?? '',
            leagueId: item['api_league_id'],
            emoji: item['emoji'] ?? '⚽',
            isEnabled: item['is_enabled'] ?? true,
            upcomingCount: item['upcoming_count'] ?? 0,
          ));
        }
      }

      // 2. Fetch user's predictions
      final predRes = await ApiClient.instance.get('/challenge/predictions');
      Map<int, Map<String, dynamic>> loadedPreds = {};
      if (predRes.data is List) {
        for (var pred in predRes.data) {
          final lgId = pred['league_id'] as int?;
          if (lgId != null) {
            loadedPreds[lgId] = pred;
          }
        }
      }

      setState(() {
        _leagues = loadedLeagues.where((l) => ![1, 2, 3, 6, 9].contains(l.leagueId)).toList();
        _predictions = loadedPreds;
      });
    } catch (e) {
      debugPrint('Failed to load season challenges: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openPredictionDetail(int leagueId) {
    context.push('/challenge/league/$leagueId').then((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          title: Text('Season Challenges'.tr(ref)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _leagues.isEmpty
                ? Center(
                    child: Text(
                      'No challenges available'.tr(ref),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leagues.length,
                    itemBuilder: (context, index) {
                      final league = _leagues[index];
                      final pred = _predictions[league.leagueId];
                      // Wait! The competition object doesn't have challenge_locked. But we can fetch it or get it from active leagues response:
                      // Wait! In `_loadData`, each league item in `leaguesRes.data` has `challenge_locked`!
                      // Let's pass challenge_locked to the Competition model or extract it here!
                      // Actually, let's look at competition model: it doesn't have it, but we can check a map or store it in state!
                      // Let's see: how did we fetch it in leaguesRes?
                      // The leaguesRes.data has challenge_locked as boolean. Let's build a map of lock statuses!
                      return _buildLeagueCard(league, pred);
                    },
                  ),
      ),
    );
  }

  Widget _buildLeagueCard(Competition league, Map<String, dynamic>? pred) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPred = pred != null;
    final champion = pred?['predicted_team_name'] as String?;
    final scorer = pred?['predicted_top_scorer'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPred ? AppColors.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openPredictionDetail(league.leagueId),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Logo, Name, Edit Button
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: NetworkImage(league.leagueLogoUrl),
                      child: Text(
                        league.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            league.name.tr(ref),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            league.subtitle.tr(ref),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      hasPred ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                      color: hasPred ? AppColors.primary : Colors.grey,
                      size: 24,
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),

                // Prediction Info Rows
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Champion Pick',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            champion ?? 'Not Selected',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: champion != null ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top Scorer Pick',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scorer ?? 'Not Selected',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: scorer != null ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
