import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../providers/matches_provider.dart';
import '../../data/models/match_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flag_circle.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  int _homeScore = 0;
  int _awayScore = 0;
  bool _isSubmitting = false;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _submitPrediction(MatchModel match) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(matchesProvider.notifier).savePrediction(
            matchId: match.id,
            homeScore: _homeScore,
            awayScore: _awayScore,
          );
      _confetti.play();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Prediction submitted! 🎉'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      ref.invalidate(matchesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                Colors.white,
              ],
            ),
          ),

          matchAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (match) {
              // Init score from existing prediction
              if (match.myPrediction != null && _homeScore == 0 && _awayScore == 0) {
                _homeScore = match.myPrediction!.homeScore;
                _awayScore = match.myPrediction!.awayScore;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _MatchHeroCard(match: match),
                    const SizedBox(height: 24),
                    if (match.canPredict)
                      _PredictionForm(
                        match: match,
                        homeScore: _homeScore,
                        awayScore: _awayScore,
                        isSubmitting: _isSubmitting,
                        onHomeChanged: (v) => setState(() => _homeScore = v),
                        onAwayChanged: (v) => setState(() => _awayScore = v),
                        onSubmit: () => _submitPrediction(match),
                      )
                    else if (match.myPrediction != null)
                      _PredictionResultCard(match: match)
                    else
                      _NoPredictonCard(match: match),
                    const SizedBox(height: 24),
                    _ScoringInfoCard(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MatchHeroCard extends StatelessWidget {
  final MatchModel match;
  const _MatchHeroCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • HH:mm');
    final hasResult = match.homeScore != null && match.awayScore != null;

    return Container(
      decoration: BoxDecoration(
        gradient: match.status == MatchStatus.live
            ? const LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFFF6D00)])
            : AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              match.displayStage,
              style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),

          // Teams
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    FlagCircle(flag: match.homeTeamFlag, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasResult)
                      Text(
                        '${match.homeScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (!hasResult)
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    )
                  else
                    Text(
                      '-',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  if (match.status == MatchStatus.live)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        match.liveMinute != null
                            ? '● ${match.liveMinute}\''
                            : '● LIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    FlagCircle(flag: match.awayTeamFlag, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasResult)
                      Text(
                        '${match.awayScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(match.kickoffTime.toLocal()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '${match.venue}, ${match.city}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(duration: 300.ms);
  }
}

class _PredictionForm extends StatelessWidget {
  final MatchModel match;
  final int homeScore;
  final int awayScore;
  final bool isSubmitting;
  final ValueChanged<int> onHomeChanged;
  final ValueChanged<int> onAwayChanged;
  final VoidCallback onSubmit;

  const _PredictionForm({
    required this.match,
    required this.homeScore,
    required this.awayScore,
    required this.isSubmitting,
    required this.onHomeChanged,
    required this.onAwayChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final deadline = match.kickoffTime.subtract(const Duration(hours: 2));
    final timeLeft = deadline.difference(DateTime.now());
    final isUrgent = timeLeft.inHours < 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  match.myPrediction != null ? 'Update Prediction' : 'Submit Prediction',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? Colors.orange.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: isUrgent ? Colors.orange : AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTimeLeft(timeLeft),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUrgent ? Colors.orange : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Score picker
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.homeTeam,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _ScorePicker(
                        value: homeScore,
                        onChanged: onHomeChanged,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ':',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.awayTeam,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _ScorePicker(
                        value: awayScore,
                        onChanged: onAwayChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        match.myPrediction != null
                            ? 'Update Prediction ✏️'
                            : 'Submit Prediction ⚽',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 150.ms)
        .fadeIn(duration: 300.ms, delay: 150.ms);
  }

  String _formatTimeLeft(Duration d) {
    if (d.isNegative) return 'Closed';
    if (d.inDays > 0) return '${d.inDays}d left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }
}

class _ScorePicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ScorePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.remove,
          onTap: () {
            if (value > 0) {
              HapticFeedback.lightImpact();
              onChanged(value - 1);
            }
          },
        ),
        Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.add,
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(value + 1);
          },
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _PredictionResultCard extends StatelessWidget {
  final MatchModel match;
  const _PredictionResultCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final pred = match.myPrediction!;
    final pts = pred.pointsEarned;

    Color cardColor;
    String title;
    IconData icon;

    if (pts == null) {
      cardColor = AppColors.secondary;
      title = 'Your Prediction';
      icon = Icons.edit_note_rounded;
    } else if (pts == 3) {
      cardColor = AppColors.exactScore;
      title = '🎯 Exact Score!';
      icon = Icons.star_rounded;
    } else if (pts == 1) {
      cardColor = AppColors.correctResult;
      title = '✅ Correct Result';
      icon = Icons.check_circle_rounded;
    } else {
      cardColor = AppColors.wrongResult;
      title = '❌ Wrong Result';
      icon = Icons.cancel_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: cardColor),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (pts != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+$pts pts',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${pred.homeScore}  -  ${pred.awayScore}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cardColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 150.ms)
        .fadeIn(duration: 300.ms, delay: 150.ms);
  }
}

class _NoPredictonCard extends StatelessWidget {
  final MatchModel match;
  const _NoPredictonCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_clock_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              match.status == MatchStatus.finished
                  ? 'Prediction deadline passed'
                  : 'Prediction window closed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'You need to submit predictions at least 2 hours before kickoff.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoringInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏅 Scoring System',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _ScoreRow('🎯 Exact score', '3 pts', AppColors.exactScore),
            const SizedBox(height: 8),
            _ScoreRow('✅ Correct result', '1 pt', AppColors.correctResult),
            const SizedBox(height: 8),
            _ScoreRow('❌ Wrong result', '0 pts', AppColors.wrongResult),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String pts;
  final Color color;

  const _ScoreRow(this.label, this.pts, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(pts,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    );
  }
}
