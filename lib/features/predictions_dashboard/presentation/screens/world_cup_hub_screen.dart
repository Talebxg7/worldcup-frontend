import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../models/dashboard_prediction_model.dart';
import '../../models/world_cup_countries.dart';
import '../../models/world_cup_prediction_model.dart';
import '../../data/world_cup_prediction_repository.dart';
import '../../../fixture_predictions/presentation/screens/prediction_screen.dart';

/// 🏆 Dedicated World Cup 2026 Hub Screen
class WorldCupHubScreen extends ConsumerStatefulWidget {
  final List<DashboardPredictionModel> allPredictions;
  const WorldCupHubScreen({super.key, required this.allPredictions});

  @override
  ConsumerState<WorldCupHubScreen> createState() => _WorldCupHubScreenState();
}

class _WorldCupHubScreenState extends ConsumerState<WorldCupHubScreen> {
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration();

  static final DateTime _wcStartDate = DateTime.parse('2026-06-11T19:00:00Z');

  @override
  void initState() {
    super.initState();
    _startCountdown();
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

  @override
  Widget build(BuildContext context) {
    // Filter World Cup fixtures (league ID = 1)
    final wcFixtures = widget.allPredictions
        .where((e) => e.leagueId == '1')
        .toList();
    wcFixtures.sort((a, b) => a.kickoff.compareTo(b.kickoff));

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final mins = _timeLeft.inMinutes % 60;
    final secs = _timeLeft.inSeconds % 60;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF093122), // Pitch Deep Green
              Color(0xFF041710), // Shadow Forest Green
              Color(0xFF010A07), // Almost Black pitch boundary
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Bar with Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
                    const SizedBox(width: 48), // Balancing back button
                  ],
                ),
              ),

              // Scrollable Pitch Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Countdown Card
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

                      // Prominent "EVENTS CHALLENGES" Button
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
                      const SizedBox(height: 24),

                      // World Cup Match Section Header
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
                          Text(
                            '${wcFixtures.length} Matches'.tr(ref),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Empty State or List
                      if (wcFixtures.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Text(
                            'No World Cup matches scheduled yet.'.tr(ref),
                            style: const TextStyle(color: Colors.white38),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wcFixtures.length,
                          itemBuilder: (context, i) {
                            final p = wcFixtures[i];
                            return _WcMatchCard(p: p, df: DateFormat('EEE, MMM d • HH:mm'));
                          },
                        ),
                    ],
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

class _WcMatchCard extends StatelessWidget {
  final DashboardPredictionModel p;
  final DateFormat df;

  const _WcMatchCard({required this.p, required this.df});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C3A).withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PredictionScreen(
                  fixtureId: int.parse(p.fixtureId),
                  kickoffTime: p.kickoff,
                  homeTeam: p.homeTeam,
                  awayTeam: p.awayTeam,
                  homeLogo: p.homeLogo ?? '',
                  awayLogo: p.awayLogo ?? '',
                  homeTeamId: p.homeTeamId,
                  awayTeamId: p.awayTeamId,
                  leagueId: int.tryParse(p.leagueId) ?? 1,
                  leagueName: p.leagueName ?? 'World Cup',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      df.format(p.kickoff.toLocal()),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.matchStatus,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (p.homeLogo != null && p.homeLogo!.isNotEmpty)
                            Image.network(p.homeLogo!, width: 26, height: 26, errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: Colors.white70))
                          else
                            const Icon(Icons.flag_rounded, color: Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.homeTeam,
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
                      child: Text('vs', style: TextStyle(color: Colors.white30, fontSize: 13)),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              p.awayTeam,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (p.awayLogo != null && p.awayLogo!.isNotEmpty)
                            Image.network(p.awayLogo!, width: 26, height: 26, errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: Colors.white70))
                          else
                            const Icon(Icons.flag_rounded, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Your Prediction: ',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      '${p.homeScore} – ${p.awayScore}',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E15),
      appBar: AppBar(
        title: Text('Prediction Events'.tr(ref)),
        backgroundColor: const Color(0xFF093122),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Winner Pick'.tr(ref)),
            Tab(text: 'Group Qualifiers'.tr(ref)),
          ],
        ),
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
                    'Select exactly 2 countries from each group to advance. +10 Points per correct prediction!'.tr(ref),
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
