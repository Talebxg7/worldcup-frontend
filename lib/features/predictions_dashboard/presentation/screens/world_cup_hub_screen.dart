import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/football_api_service.dart';
import '../../data/dashboard_prediction_repository.dart';
import '../../services/prediction_dashboard_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/dashboard_prediction_model.dart';
import '../../models/world_cup_countries.dart';
import '../../models/world_cup_prediction_model.dart';
import '../../data/world_cup_prediction_repository.dart';
import '../../../fixture_predictions/presentation/screens/prediction_screen.dart';

/// 🏆 Dedicated World Cup 2026 Hub Screen
class WorldCupHubScreen extends ConsumerStatefulWidget {
  const WorldCupHubScreen({super.key});

  @override
  ConsumerState<WorldCupHubScreen> createState() => _WorldCupHubScreenState();
}

class _WorldCupHubScreenState extends ConsumerState<WorldCupHubScreen> {
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration();
  bool _loadingFixtures = true;
  List<FixtureModel> _wcFixtures = [];
  Map<int, DashboardPredictionModel> _savedPredictions = {};
  String _selectedGroup = 'All';
  WorldCupPredictionsResponse? _wcPredictions;

  static final DateTime _wcStartDate = DateTime.parse('2026-06-11T19:00:00Z');

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loadingFixtures = true);
    try {
      final fixtures = await FootballApiService.getFixtures(league: 1, season: 2026);
      fixtures.sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

      final repo = DashboardPredictionRepository();
      final raw = await repo.loadAll();
      final service = PredictionDashboardService();
      final enriched = await service.enrichAll(raw);

      final Map<int, DashboardPredictionModel> predictionMap = {};
      for (var p in enriched) {
        if (p.leagueId == '1') {
          final fxId = int.tryParse(p.fixtureId);
          if (fxId != null) {
            predictionMap[fxId] = p;
          }
        }
      }

      // Load WC Winner and Group Predictions
      final wcRepo = WorldCupPredictionRepository();
      WorldCupPredictionsResponse? wcPredictions;
      try {
        wcPredictions = await wcRepo.loadWorldCupPredictions();
      } catch (e) {
        debugPrint('Error loading WC Winner/Groups predictions in Hub: $e');
      }

      if (mounted) {
        setState(() {
          _wcFixtures = fixtures;
          _savedPredictions = predictionMap;
          _wcPredictions = wcPredictions;
          _loadingFixtures = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading World Cup Hub data: $e');
      if (mounted) {
        setState(() => _loadingFixtures = false);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now().toUtc();
    final diff = _wcStartDate.difference(now);
    setState(() {
      _timeLeft = diff.isNegative ? Duration.zero : diff;
    });
  }

  Widget _buildGroupFilterBar() {
    final groups = ['All', 'Group A', 'Group B', 'Group C', 'Group D', 'Group E', 'Group F', 'Group G', 'Group H', 'Group I', 'Group J', 'Group K', 'Group L'];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final g = groups[index];
          final isSelected = _selectedGroup == g;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                g.tr(ref),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0A1F0F) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedGroup = g;
                  });
                }
              },
              selectedColor: const Color(0xFFFFD700), // Gold
              backgroundColor: Colors.transparent,
              checkmarkColor: const Color(0xFF0A1F0F),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                  width: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeaderCard() {
    final letter = _selectedGroup.replaceFirst('Group ', '');
    final groupCountries = worldCupCountries.where((c) => c.group == letter).toList();
    
    final groupMatches = _wcFixtures.where((f) {
      final homeCountry = getCountryByName(f.homeTeam);
      return homeCountry != null && 'Group ${homeCountry.group}' == _selectedGroup;
    }).toList();
    
    final predictedCount = groupMatches.where((f) => _savedPredictions.containsKey(f.id)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C3A).withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: -10,
            child: Opacity(
              opacity: 0.12,
              child: Text(
                letter,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedGroup.toUpperCase().tr(ref),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: groupCountries.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Tooltip(
                    message: c.name,
                    child: Text(
                      c.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Predict all 6 matches in this group'.tr(ref),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$predictedCount / 6 ' + 'predicted ✅'.tr(ref),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final mins = _timeLeft.inMinutes % 60;
    final secs = _timeLeft.inSeconds % 60;

    final filteredFixtures = _wcFixtures.where((f) {
      if (_selectedGroup == 'All') return true;
      final homeCountry = getCountryByName(f.homeTeam);
      return homeCountry != null && 'Group ${homeCountry.group}' == _selectedGroup;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0A1F0F),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: HexagonNetPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.pop(context);
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24),
                          const SizedBox(width: 6),
                          Text(
                            'WORLD CUP 2026'.tr(ref),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F4C3A).withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.08),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _timeLeft == Duration.zero
                                    ? 'TOURNAMENT ACTIVE'.tr(ref)
                                    : 'TOURNAMENT COUNTDOWN'.tr(ref),
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_timeLeft != Duration.zero)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _CountdownUnit(value: days, label: 'Days'),
                                    const _CountdownDivider(),
                                    _CountdownUnit(value: hours, label: 'Hrs'),
                                    const _CountdownDivider(),
                                    _CountdownUnit(value: mins, label: 'Mins'),
                                    const _CountdownDivider(),
                                    _CountdownUnit(value: secs, label: 'Secs'),
                                  ],
                                )
                              else
                                Text(
                                  'Locking predictions!'.tr(ref),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WorldCupEventsHubScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFCCA000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PREDICTION CHALLENGES'.tr(ref),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Champion Picker & Group Stage'.tr(ref),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            _showPredictionsSummaryDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F4C3A).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFFFD700), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MY WORLD CUP PICKS'.tr(ref),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'View your Champion & Group qualifiers'.tr(ref),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD700), size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.sports_soccer_rounded, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'World Cup Group Stage'.tr(ref),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (!_loadingFixtures)
                              Text(
                                '${filteredFixtures.length} Matches'.tr(ref),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!_loadingFixtures && _wcFixtures.isNotEmpty) ...[
                          _buildGroupFilterBar(),
                          if (_selectedGroup != 'All') _buildGroupHeaderCard(),
                        ],
                        if (_loadingFixtures)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(color: Color(0xFFFFD700)),
                          )
                        else if (filteredFixtures.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Text(
                              'No matches found for this group.'.tr(ref),
                              style: const TextStyle(color: Colors.white38),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredFixtures.length,
                            itemBuilder: (context, i) {
                              final f = filteredFixtures[i];
                              final pred = _savedPredictions[f.id];
                              return _WcMatchCard(
                                f: f,
                                prediction: pred,
                                df: DateFormat('EEE, MMM d • HH:mm'),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PredictionScreen(
                                        fixtureId: f.id,
                                        kickoffTime: f.date ?? DateTime.now(),
                                        homeTeam: f.homeTeam,
                                        awayTeam: f.awayTeam,
                                        homeLogo: f.homeLogo ?? '',
                                        awayLogo: f.awayLogo ?? '',
                                        homeTeamId: f.homeTeamId,
                                        awayTeamId: f.awayTeamId,
                                        leagueId: 1,
                                        leagueName: 'World Cup',
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPredictionsSummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final winner = _wcPredictions?.winner?.predictedWinner;
        final groups = _wcPredictions?.groups ?? [];
        final winnerCountry = winner != null ? getCountryByName(winner) : null;

        return Dialog(
          backgroundColor: const Color(0xFF061E15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFFFD700), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MY WORLD CUP PICKS'.tr(ref),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                const SizedBox(height: 8),
                Text(
                  'WORLD CUP CHAMPION'.tr(ref),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C3A).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        winnerCountry != null ? winnerCountry.flag : '🏆',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        winner != null ? winner.tr(ref) : 'No champion predicted yet'.tr(ref),
                        style: TextStyle(
                          color: winner != null ? Colors.white : Colors.white38,
                          fontSize: 15,
                          fontWeight: winner != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'GROUP QUALIFIERS'.tr(ref),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'].map((letter) {
                        final gp = groups.firstWhere(
                          (g) => g.groupLetter == letter,
                          orElse: () => WorldCupGroupPredictionModel(groupLetter: letter, predictedQualifiers: []),
                        );
                        final qs = gp.predictedQualifiers;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Group $letter'.tr(ref),
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: qs.isEmpty
                                    ? Text(
                                        'Not predicted yet'.tr(ref),
                                        style: const TextStyle(
                                          color: Colors.white24,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : Row(
                                        children: qs.map((countryName) {
                                          final country = getCountryByName(countryName);
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  country?.flag ?? '',
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  countryName.tr(ref),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HexagonNetPainter extends CustomPainter {
  const HexagonNetPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final spacing = 40.0;
    for (double i = -spacing; i < size.width + spacing; i += spacing * 1.5) {
      for (double j = -spacing; j < size.height + spacing; j += spacing * 1.5) {
        final path = Path();
        final center = Offset(i, j);
        for (int k = 0; k < 6; k++) {
          final angle = (k * 60) * (math.pi / 180);
          final x = center.dx + 20 * math.cos(angle);
          final y = center.dy + 20 * math.sin(angle);
          if (k == 0) path.moveTo(x, y); else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;
  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _CountdownDivider extends StatelessWidget {
  const _CountdownDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 14, right: 14, bottom: 12),
      child: Text(
        ':',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<Color> getFlagColors(String countryName) {
  final name = countryName.toLowerCase();
  if (name.contains('mexico')) return [const Color(0xFF006847), const Color(0xFFFFFFFF), const Color(0xFFCE1126)];
  if (name.contains('south africa')) return [const Color(0xFF007C3F), const Color(0xFFFFB612), const Color(0xFF002395)];
  if (name.contains('south korea')) return [const Color(0xFFFFFFFF), const Color(0xFFCD113B), const Color(0xFF0047A0)];
  if (name.contains('czech')) return [const Color(0xFF11457E), const Color(0xFFD71426)];
  if (name.contains('canada')) return [const Color(0xFFD80621), const Color(0xFFFFFFFF)];
  if (name.contains('bosnia')) return [const Color(0xFF002F6C), const Color(0xFFFECB00)];
  if (name.contains('qatar')) return [const Color(0xFF8A1538), const Color(0xFFFFFFFF)];
  if (name.contains('switzerland')) return [const Color(0xFFD52B1E), const Color(0xFFFFFFFF)];
  if (name.contains('brazil')) return [const Color(0xFF009739), const Color(0xFFFEDF00)];
  if (name.contains('morocco')) return [const Color(0xFFC1272D), const Color(0xFF006233)];
  if (name.contains('haiti')) return [const Color(0xFF00209F), const Color(0xFFD22630)];
  if (name.contains('scotland')) return [const Color(0xFF005EB8), const Color(0xFFFFFFFF)];
  if (name.contains('usa') || name.contains('united states')) return [const Color(0xFF0A3161), const Color(0xFFB31942)];
  if (name.contains('paraguay')) return [const Color(0xFFD52B1E), const Color(0xFF0038A8)];
  if (name.contains('australia')) return [const Color(0xFF00008B), const Color(0xFF00843D)];
  if (name.contains('türkiye') || name.contains('turkey')) return [const Color(0xFFE30A17), const Color(0xFFFFFFFF)];
  if (name.contains('germany')) return [const Color(0xFF000000), const Color(0xFFFFCC00), const Color(0xFFDD0000)];
  if (name.contains('curaçao')) return [const Color(0xFF002B7F), const Color(0xFFF9E814)];
  if (name.contains('ivory coast')) return [const Color(0xFFF77F00), const Color(0xFFFFFFFF), const Color(0xFF2EC4B6)];
  if (name.contains('ecuador')) return [const Color(0xFFFFDD00), const Color(0xFF0033A0), const Color(0xFFD52B1E)];
  if (name.contains('netherlands')) return [const Color(0xFF21468B), const Color(0xFFAE1C28)];
  if (name.contains('japan')) return [const Color(0xFFFFFFFF), const Color(0xFFBC002D)];
  if (name.contains('sweden')) return [const Color(0xFF006AA7), const Color(0xFFFECC00)];
  if (name.contains('tunisia')) return [const Color(0xFFE70013), const Color(0xFFFFFFFF)];
  if (name.contains('belgium')) return [const Color(0xFF000000), const Color(0xFFFDDA0D), const Color(0xFFEF3340)];
  if (name.contains('egypt')) return [const Color(0xFFC1272D), const Color(0xFF000000), const Color(0xFFFFFFFF)];
  if (name.contains('iran')) return [const Color(0xFF239F40), const Color(0xFFDA251D)];
  if (name.contains('new zealand')) return [const Color(0xFF000000), const Color(0xFFFFFFFF)];
  if (name.contains('spain')) return [const Color(0xFFAD1519), const Color(0xFFFABD00)];
  if (name.contains('cape verde')) return [const Color(0xFF002A8F), const Color(0xFFFFD100)];
  if (name.contains('saudi arabia')) return [const Color(0xFF006C35), const Color(0xFFFFFFFF)];
  if (name.contains('uruguay')) return [const Color(0xFF0081C8), const Color(0xFFFFFFFF)];
  if (name.contains('france')) return [const Color(0xFF0055A5), const Color(0xFFFFFFFF), const Color(0xFFEF4135)];
  if (name.contains('senegal')) return [const Color(0xFF00853F), const Color(0xFFFDEF42), const Color(0xFFE21820)];
  if (name.contains('iraq')) return [const Color(0xFFC1272D), const Color(0xFF000000), const Color(0xFF008F4C)];
  if (name.contains('norway')) return [const Color(0xFFBA0C2F), const Color(0xFF00205B)];
  if (name.contains('argentina')) return [const Color(0xFF74ACDF), const Color(0xFFFFFFFF)];
  if (name.contains('algeria')) return [const Color(0xFF006633), const Color(0xFFFFFFFF), const Color(0xFFD21F3C)];
  if (name.contains('austria')) return [const Color(0xFFED2939), const Color(0xFFFFFFFF)];
  if (name.contains('jordan')) return [const Color(0xFF000000), const Color(0xFF007A3D), const Color(0xFFE61920)];
  if (name.contains('portugal')) return [const Color(0xFF046A38), const Color(0xFFDA291C)];
  if (name.contains('congo')) return [const Color(0xFF007A5E), const Color(0xFFFCD116), const Color(0xFFCE1126)];
  if (name.contains('uzbekistan')) return [const Color(0xFF00B5E2), const Color(0xFFFFFFFF), const Color(0xFF1EAE58)];
  if (name.contains('colombia')) return [const Color(0xFFFCD116), const Color(0xFF003893), const Color(0xFFCE1126)];
  if (name.contains('england')) return [const Color(0xFFFFFFFF), const Color(0xFFCE1126)];
  if (name.contains('croatia')) return [const Color(0xFFFF0000), const Color(0xFF0000FF)];
  if (name.contains('ghana')) return [const Color(0xFFFCD116), const Color(0xFF006B3F), const Color(0xFFCE1126)];
  if (name.contains('panama')) return [const Color(0xFF002F6C), const Color(0xFFD21034)];
  return [const Color(0xFF0F4C3A), const Color(0xFF07291F)];
}

class PitchLineWatermarkPainter extends CustomPainter {
  const PitchLineWatermarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(Offset(cx, cy), 35, paint);
    canvas.drawCircle(Offset(cx, cy), 2, paint..style = PaintingStyle.fill);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StadiumCrowdPainter extends CustomPainter {
  const StadiumCrowdPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill;
      
    for (double y = 4.0; y < size.height; y += 6.0) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.white.withOpacity(0.015)..strokeWidth = 1.0,
      );
    }
    
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.85, size.width * 0.5, size.height * 0.90);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.85, size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WcMatchCard extends ConsumerWidget {
  final FixtureModel f;
  final DashboardPredictionModel? prediction;
  final DateFormat df;
  final VoidCallback onTap;

  const _WcMatchCard({
    required this.f,
    required this.prediction,
    required this.df,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPrediction = prediction != null;
    final matchTime = f.date ?? DateTime.now();
    final timeDiff = matchTime.difference(DateTime.now());
    final isSoon = timeDiff.inHours < 24 && !timeDiff.isNegative;

    final homeColors = getFlagColors(f.homeTeam);
    final awayColors = getFlagColors(f.awayTeam);
    final homeFlagColor = homeColors[0];
    final awayFlagColor = awayColors[0];

    final leftColor = homeFlagColor.withOpacity(0.18);
    final rightColor = awayFlagColor.withOpacity(0.18);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPrediction 
              ? Colors.white10 
              : const Color(0xFFFFD700).withOpacity(0.3),
          width: hasPrediction ? 1.0 : 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      leftColor,
                      rightColor,
                    ],
                    stops: const [0.4, 0.6],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(
                painter: PitchLineWatermarkPainter(),
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(
                painter: StadiumCrowdPainter(),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: isSoon ? Colors.redAccent : Colors.white54,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSoon
                                    ? 'Starts in ${timeDiff.inHours}h ${timeDiff.inMinutes % 60}m'.tr(ref)
                                    : df.format(matchTime.toLocal()),
                                style: TextStyle(
                                  color: isSoon ? Colors.redAccent : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: isSoon ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (!hasPrediction) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
                                  ),
                                  child: const Text(
                                    '+3 pts',
                                    style: TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasPrediction ? Colors.white12 : const Color(0xFFFFD700).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hasPrediction ? (f.status ?? 'NS') : 'TAP TO PREDICT',
                                  style: TextStyle(
                                    color: hasPrediction ? Colors.white70 : const Color(0xFFFFD700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ).animate(
                                onPlay: (controller) => controller.repeat(reverse: true),
                              ).shimmer(
                                duration: 1500.ms,
                                color: Colors.white24,
                              ).scale(
                                begin: const Offset(0.96, 0.96),
                                end: const Offset(1.04, 1.04),
                                duration: 1500.ms,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: homeFlagColor.withOpacity(0.55),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: f.homeLogo != null && f.homeLogo!.isNotEmpty
                                        ? Image.network(f.homeLogo!, width: 26, height: 26, errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: Colors.white70))
                                        : const Icon(Icons.flag_rounded, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f.homeTeam,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '⚡',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFFFD700),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    f.awayTeam,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: awayFlagColor.withOpacity(0.55),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: f.awayLogo != null && f.awayLogo!.isNotEmpty
                                        ? Image.network(f.awayLogo!, width: 26, height: 26, errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: Colors.white70))
                                        : const Icon(Icons.flag_rounded, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasPrediction) ...[
                            Text(
                              'Your Prediction: '.tr(ref),
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            Text(
                              '${prediction!.homeScore} – ${prediction!.awayScore}',
                              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ] else ...[
                            const Icon(Icons.edit_note_rounded, color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Tap to Predict Match (+Points)'.tr(ref),
                              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🏆 Split Hub screen for Winner Prediction and Group predictions
class WorldCupEventsHubScreen extends ConsumerStatefulWidget {
  const WorldCupEventsHubScreen({super.key});

  @override
  ConsumerState<WorldCupEventsHubScreen> createState() => _WorldCupEventsHubScreenState();
}

class _WorldCupEventsHubScreenState extends ConsumerState<WorldCupEventsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _wcRepo = WorldCupPredictionRepository();
  WorldCupPredictionsResponse? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _wcRepo.loadWorldCupPredictions();
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showMyPicksSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final winner = _data?.winner?.predictedWinner;
        final groups = _data?.groups ?? [];
        final winnerCountry = winner != null ? getCountryByName(winner) : null;

        return Dialog(
          backgroundColor: const Color(0xFF061E15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFFFD700), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MY WORLD CUP PICKS'.tr(ref),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                const SizedBox(height: 8),
                Text(
                  'WORLD CUP CHAMPION'.tr(ref),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C3A).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        winnerCountry != null ? winnerCountry.flag : '🏆',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        winner != null ? winner.tr(ref) : 'No champion predicted yet'.tr(ref),
                        style: TextStyle(
                          color: winner != null ? Colors.white : Colors.white38,
                          fontSize: 15,
                          fontWeight: winner != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'GROUP QUALIFIERS'.tr(ref),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'].map((letter) {
                        final gp = groups.firstWhere(
                          (g) => g.groupLetter == letter,
                          orElse: () => WorldCupGroupPredictionModel(groupLetter: letter, predictedQualifiers: []),
                        );
                        final qs = gp.predictedQualifiers;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Group $letter'.tr(ref),
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: qs.isEmpty
                                    ? Text(
                                        'Not predicted yet'.tr(ref),
                                        style: const TextStyle(
                                          color: Colors.white24,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: qs.map((countryName) {
                                          final country = getCountryByName(countryName);
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                country?.flag ?? '',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                countryName.tr(ref),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E15),
      appBar: AppBar(
        title: Text('Prediction Events'.tr(ref)),
        backgroundColor: const Color(0xFF093122),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFFFD700)),
            tooltip: 'My Picks'.tr(ref),
            onPressed: () => _showMyPicksSummary(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Winner Pick'.tr(ref)),
            Tab(text: 'Group Qualifiers'.tr(ref)),
          ],
        ),
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF061E15),
              icon: const Icon(Icons.assignment_turned_in_rounded),
              label: Text(
                'My Picks'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showMyPicksSummary(context),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _WinnerPickerTab(
                  data: _data,
                  onSuccess: _load,
                ),
                _GroupQualifiersTab(
                  data: _data,
                  onSuccess: _load,
                ),
              ],
            ),
    );
  }
}

class _WinnerPickerTab extends ConsumerStatefulWidget {
  final WorldCupPredictionsResponse? data;
  final VoidCallback onSuccess;

  const _WinnerPickerTab({required this.data, required this.onSuccess});

  @override
  ConsumerState<_WinnerPickerTab> createState() => _WinnerPickerTabState();
}

class _WinnerPickerTabState extends ConsumerState<_WinnerPickerTab> {
  final _wcRepo = WorldCupPredictionRepository();
  bool _saving = false;

  void _confirmSelection(WorldCupCountry country) {
    if (widget.data?.locked ?? false) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F4C3A),
          title: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
              const SizedBox(width: 10),
              Text(
                'Predict Champion'.tr(ref),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Confirm ${country.flag} ${country.name} as your World Cup 2026 Champion?\n\nIf correct, this will award you +50 points! Predictions will lock on June 11.'.tr(ref),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr(ref), style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF093122),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                setState(() => _saving = true);
                try {
                  await _wcRepo.submitWinner(country.name);
                  widget.onSuccess();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Your pick: ${country.flag} ${country.name} — Good luck!'.tr(ref))),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to submit prediction: $e'.tr(ref))),
                    );
                  }
                } finally {
                  setState(() => _saving = false);
                }
              },
              child: Text('Confirm'.tr(ref)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedWinner = widget.data?.winner?.predictedWinner;
    final locked = widget.data?.locked ?? false;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF093122).withOpacity(0.5),
              child: Column(
                children: [
                  Text(
                    'CHAMPION PREDICTION'.tr(ref),
                    style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Awarded +50 Points if correct! Pick exactly one winner.'.tr(ref),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  if (selectedWinner != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        border: Border.all(color: const Color(0xFFFFD700)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Your Pick: '.tr(ref),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${getCountryByName(selectedWinner)?.flag ?? ''} $selectedWinner',
                            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: worldCupCountries.length,
                itemBuilder: (context, i) {
                  final country = worldCupCountries[i];
                  final isSelected = selectedWinner?.toLowerCase() == country.name.toLowerCase();
                  
                  return Opacity(
                    opacity: locked && !isSelected ? 0.4 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFFFD700).withOpacity(0.25)
                            : const Color(0xFF0F4C3A).withOpacity(0.35),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: locked ? null : () => _confirmSelection(country),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                country.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      country.name,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Group ${country.group}'.tr(ref),
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_saving)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _GroupQualifiersTab extends ConsumerStatefulWidget {
  final WorldCupPredictionsResponse? data;
  final VoidCallback onSuccess;

  const _GroupQualifiersTab({required this.data, required this.onSuccess});

  @override
  ConsumerState<_GroupQualifiersTab> createState() => _GroupQualifiersTabState();
}

class _GroupQualifiersTabState extends ConsumerState<_GroupQualifiersTab> {
  final _wcRepo = WorldCupPredictionRepository();
  final Map<String, List<String>> _selections = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initSelections();
  }

  @override
  void didUpdateWidget(covariant _GroupQualifiersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _initSelections();
    }
  }

  void _initSelections() {
    _selections.clear();
    widget.data?.groups.forEach((g) {
      _selections[g.groupLetter] = List<String>.from(g.predictedQualifiers);
    });
  }

  void _toggleCountry(String groupLetter, String countryName) {
    if (widget.data?.locked ?? false) return;

    final current = _selections[groupLetter] ?? [];
    setState(() {
      if (current.contains(countryName)) {
        current.remove(countryName);
      } else {
        if (current.length >= 2) {
          // Keep max 2, remove first and add new
          current.removeAt(0);
        }
        current.add(countryName);
      }
      _selections[groupLetter] = current;
    });
  }

  Future<void> _submitGroup(String groupLetter) async {
    final list = _selections[groupLetter] ?? [];
    final messenger = ScaffoldMessenger.of(context);
    if (list.length != 2) {
      messenger.showSnackBar(
        SnackBar(content: Text('Please select exactly 2 countries for Group $groupLetter.'.tr(ref))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _wcRepo.submitGroupQualifiers(groupLetter, list);
      widget.onSuccess();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Saved qualifiers for Group $groupLetter: ${list.join(" & ")}'.tr(ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to save Group $groupLetter predictions: $e'.tr(ref))),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.data?.locked ?? false;
    final groupLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF093122).withOpacity(0.5),
              child: Column(
                children: [
                  Text(
                    'GROUP QUALIFIERS PREDICTION'.tr(ref),
                    style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select exactly 2 countries from each group to advance. +3 Points per correct qualifier prediction!'.tr(ref),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupLetters.length,
                itemBuilder: (context, i) {
                  final letter = groupLetters[i];
                  final groupTeams = worldCupCountries.where((c) => c.group == letter).toList();
                  final selected = _selections[letter] ?? [];
                   final groupPrediction = widget.data?.groups.firstWhere(
                     (g) => g.groupLetter == letter,
                     orElse: () => WorldCupGroupPredictionModel(groupLetter: letter, predictedQualifiers: []),
                   );
                   final savedList = groupPrediction?.predictedQualifiers ?? <String>[];
                  
                  final hasChanges = selected.length == 2 && 
                      (selected.any((e) => !savedList.contains(e)) || savedList.any((e) => !selected.contains(e)));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C3A).withOpacity(0.25),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GROUP $letter'.tr(ref),
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (locked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('Locked'.tr(ref), style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            else if (hasChanges)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF093122),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: const Size(60, 28),
                                ),
                                onPressed: () => _submitGroup(letter),
                                child: Text('Save'.tr(ref), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            else if (savedList.length == 2)
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 16),
                                  SizedBox(width: 4),
                                  Text('Saved', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: groupTeams.length,
                          itemBuilder: (context, idx) {
                            final c = groupTeams[idx];
                            final isToggled = selected.contains(c.name);
                            return Opacity(
                              opacity: locked && !isToggled ? 0.45 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isToggled 
                                      ? const Color(0xFFFFD700).withOpacity(0.15)
                                      : Colors.white.withOpacity(0.03),
                                  border: Border.all(
                                    color: isToggled ? const Color(0xFFFFD700) : Colors.white10,
                                    width: isToggled ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: locked ? null : () => _toggleCountry(letter, c.name),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Text(c.flag, style: const TextStyle(fontSize: 22)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c.name,
                                            style: TextStyle(
                                              color: isToggled ? const Color(0xFFFFD700) : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_saving)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
