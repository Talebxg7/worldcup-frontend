import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/flag_circle.dart';
import '../../../matches/data/models/match_model.dart';
import '../../../matches/presentation/providers/matches_provider.dart';

class EnterResultScreen extends ConsumerStatefulWidget {
  final String matchId;
  const EnterResultScreen({super.key, required this.matchId});

  @override
  ConsumerState<EnterResultScreen> createState() => _EnterResultScreenState();
}

class _EnterResultScreenState extends ConsumerState<EnterResultScreen> {
  int _homeScore = 0;
  int _awayScore = 0;
  bool _isSubmitting = false;

  Future<void> _submitResult(MatchModel match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Result'),
        content: Text(
          'Submit: ${match.homeTeam} $_homeScore - $_awayScore ${match.awayTeam}?\n'
          '\nThis will auto-calculate points for all predictors.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiClient.instance.put('/matches/${match.id}/result', data: {
        'home_score': _homeScore,
        'away_score': _awayScore,
      });
      ref.invalidate(matchesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Result entered & points calculated! 🏆'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
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
        title: const Text('Enter Result'),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (match) {
          // Init with existing result if available
          if (match.homeScore != null && _homeScore == 0 && _awayScore == 0) {
            _homeScore = match.homeScore!;
            _awayScore = match.awayScore!;
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Match header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          FlagCircle(flag: match.homeTeamFlag, size: 40),
                          const SizedBox(height: 6),
                          Text(match.homeTeam,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                      const Text(
                        'VS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900),
                      ),
                      Column(
                        children: [
                          FlagCircle(flag: match.awayTeamFlag, size: 40),
                          const SizedBox(height: 6),
                          Text(match.awayTeam,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'Enter Final Score',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 32),

                // Score pickers
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AdminScorePicker(
                      label: match.homeTeam,
                      value: _homeScore,
                      onChanged: (v) => setState(() => _homeScore = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        ':',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    _AdminScorePicker(
                      label: match.awayTeam,
                      value: _awayScore,
                      onChanged: (v) => setState(() => _awayScore = v),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Info card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Submitting this result will automatically calculate and award points to all ${match.totalPredictions} predictors.',
                          style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitResult(match),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: const Text(
                      'Submit Result',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminScorePicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _AdminScorePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final ctrl = TextEditingController(text: '$value');
            final result = await showDialog<int>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Score for $label'),
                content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Enter score'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text) ?? 0;
                      Navigator.pop(ctx, v);
                    },
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (result != null) onChanged(result);
          },
          child: Column(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onChanged(value + 1);
                },
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.secondary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.secondary.withOpacity(0.08),
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (value > 0) {
                    HapticFeedback.lightImpact();
                    onChanged(value - 1);
                  }
                },
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: value > 0 ? AppColors.secondary : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
