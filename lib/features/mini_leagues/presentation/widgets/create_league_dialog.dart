import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/league_repository.dart';

class CreateLeagueInput {
  final String leagueName;
  final String competition;
  final int maxMembers;
  final String paymentProvider;

  const CreateLeagueInput({
    required this.leagueName,
    required this.competition,
    required this.maxMembers,
    required this.paymentProvider,
  });
}

/// Professional create-league form (dark-theme friendly, rounded).
class CreateLeagueDialog extends StatefulWidget {
  const CreateLeagueDialog({
    super.key,
  });

  @override
  State<CreateLeagueDialog> createState() => _CreateLeagueDialogState();
}

class _CreateLeagueDialogState extends State<CreateLeagueDialog> {
  final TextEditingController leagueNameController = TextEditingController();
  static const List<String> _competitions = [
    'Premier League',
    'La Liga',
    'Serie A',
    'Bundesliga',
    'Ligue 1',
    'Egyptian Premier League',
    'Primeira Liga',
    'World Cup',
    'UEFA Champions League',
    'UEFA Europa League',
    'AFCON',
    'Copa America',
    'Saudi Pro League',
    'Qatar Stars League',
  ];

  String selectedCompetition = 'Premier League';
  static const int _defaultMaxMembers = LeagueRepository.leagueMemberCap; // 20
  bool _submitting = false;
  bool _acceptFee = false;
  String _paymentProvider = 'paypal';

  @override
  void dispose() {
    leagueNameController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final name = leagueNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a league name')),
      );
      return;
    }
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('League name must be at least 3 letters long')),
      );
      return;
    }

    setState(() => _submitting = true);
    if (!mounted) return;
    Navigator.of(context).pop<CreateLeagueInput>(
      CreateLeagueInput(
        leagueName: name,
        competition: selectedCompetition,
        maxMembers: _defaultMaxMembers,
        paymentProvider: _paymentProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.darkSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create league',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: leagueNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'League name',
                  hintText: 'e.g. Office predictions',
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.blueAccent.shade100,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'League name should be at least 3 letters',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Select Competition',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedCompetition,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                  ),
                ),
                isExpanded: true,
                items: _competitions
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedCompetition = v);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'This league is private (invite only).',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        children: [
                          const TextSpan(text: 'Mini League Pro - '),
                          TextSpan(
                            text: 'FREE for a limited time!',
                            style: TextStyle(
                              color: Colors.greenAccent.shade400,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What you get:\n'
                      '- Private room for family and friends\n'
                      '- Unique join code and private leaderboard\n'
                      '- Room controls for host (kick members / set max members)\n'
                      '- League-focused matches so everyone predicts same competition',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Default room capacity: 20 members (host can customize later in room settings).',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: _acceptFee,
                contentPadding: EdgeInsets.zero,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() {
                          _acceptFee = v ?? false;
                        }),
                title: Text(
                  'I understand this room will be free for a limited time only',
                  style: TextStyle(color: Colors.greenAccent.shade400, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('No payment required during this promotional period'),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkTextSecondary,
                        side: const BorderSide(color: AppColors.darkBorder),
                        backgroundColor: AppColors.darkCard,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting || !_acceptFee ? null : _onCreate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create (Free)',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
