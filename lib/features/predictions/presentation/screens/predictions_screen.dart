import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/predictions_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flag_circle.dart';
import '../../../matches/data/models/match_model.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(predictionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Predictions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(predictionsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: predictionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(predictionsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (predictions) {
          if (predictions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_note_rounded, size: 80, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 16),
                  Text('No predictions yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Matches and start predicting!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sports_soccer_rounded, color: Colors.white),
                    label: const Text('View Matches',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          // Stats
          final total = predictions.length;
          final withPoints = predictions.where((p) => p.pointsEarned != null).toList();
          final totalPoints = withPoints.fold<int>(0, (sum, p) => sum + (p.pointsEarned!));
          final exactScores = withPoints.where((p) => p.pointsEarned! >= 4).length;
          final correctResults = withPoints.where((p) => (p.pointsEarned ?? 0) > 0).length;

          return RefreshIndicator(
            onRefresh: () async => ref.read(predictionsProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                // Stats header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total Points',
                          value: '$totalPoints',
                          icon: Icons.star_rounded,
                          color: AppColors.accent,
                        ),
                        _Divid(),
                        _StatItem(
                          label: 'Exact',
                          value: '$exactScores',
                          icon: Icons.gps_fixed_rounded,
                          color: Colors.white,
                        ),
                        _Divid(),
                        _StatItem(
                          label: 'Correct',
                          value: '$correctResults',
                          icon: Icons.check_rounded,
                          color: Colors.white,
                        ),
                        _Divid(),
                        _StatItem(
                          label: 'Total',
                          value: '$total',
                          icon: Icons.list_alt_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(duration: 300.ms),
                ),

                // Predictions list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pred = predictions[index];
                        return _PredictionCard(prediction: pred, index: index);
                      },
                      childCount: predictions.length,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Divid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _PredictionCard extends ConsumerWidget {
  final PredictionModel prediction;
  final int index;

  const _PredictionCard({required this.prediction, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = prediction.pointsEarned;

    Color pts3 = AppColors.exactScore;
    Color pts1 = AppColors.correctResult;
    Color pts0 = AppColors.wrongResult;
    Color ptsNull = AppColors.secondary;

    Color cardBorderColor;
    Color ptsColor;
    String ptsLabel;

    if (pts == null) {
      cardBorderColor = ptsNull;
      ptsColor = ptsNull;
      ptsLabel = 'Pending';
    } else if (pts >= 4) {
      cardBorderColor = pts3;
      ptsColor = pts3;
      ptsLabel = '+$pts pts 🎯';
    } else if (pts > 0) {
      cardBorderColor = pts1;
      ptsColor = pts1;
      ptsLabel = '+$pts pts ✅';
    } else {
      cardBorderColor = pts0;
      ptsColor = pts0;
      ptsLabel = '0 pts ❌';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor.withOpacity(0.4), width: 1.5),
        color: Theme.of(context).cardTheme.color,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: ApiClient.instance.get('/matches/${prediction.matchId}'),
          builder: (context, snapshot) {
            String homeTeam = 'Loading...';
            String awayTeam = '';
            String flag1 = '';
            String flag2 = '';

            if (snapshot.hasData) {
              final match = MatchModel.fromJson(
                  snapshot.data!.data as Map<String, dynamic>);
              homeTeam = match.homeTeam;
              awayTeam = match.awayTeam;
              flag1 = match.homeTeamFlag;
              flag2 = match.awayTeamFlag;
            }

            return Row(
              children: [
                // Teams & prediction
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FlagCircle(flag: flag1, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              homeTeam,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          FlagCircle(flag: flag2, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              awayTeam,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Your prediction score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${prediction.homeScore} - ${prediction.awayScore}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ptsColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ptsColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ptsLabel,
                        style: TextStyle(
                          color: ptsColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ).animate().slideX(
          begin: 0.2,
          duration: 350.ms,
          delay: Duration(milliseconds: index * 50),
          curve: Curves.easeOut,
        ).fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50));
  }
}
