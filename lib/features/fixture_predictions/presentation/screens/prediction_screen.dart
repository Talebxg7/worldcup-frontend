import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/prediction_repository.dart';
import '../../models/fixture_prediction_model.dart';
import '../../../predictions_dashboard/data/dashboard_prediction_repository.dart';
import '../../../predictions_dashboard/models/dashboard_prediction_model.dart';
import '../../../../core/network/api_client.dart';

class PredictionScreen extends StatefulWidget {
  final int fixtureId;
  final DateTime kickoffTime;

  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;

  final int? homeTeamId;
  final int? awayTeamId;
  final int leagueId;
  final String leagueName;
  final int? roomId;

  const PredictionScreen({
    super.key,
    required this.fixtureId,
    required this.kickoffTime,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.leagueId,
    required this.leagueName,
    this.roomId,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen>
    with SingleTickerProviderStateMixin {
  final _repo = PredictionRepository();
  late FixturePredictionModel _model;

  bool _loading = true;
  bool _saving = false;

  bool _eventsExpanded = false;
  late final AnimationController _eventsController;
  late final Animation<double> _eventsSize;

  bool get _locked =>
      widget.kickoffTime.subtract(const Duration(hours: 2)).isBefore(DateTime.now());

  /// Match block: +2 for correct home score, +2 for correct away score (max 4).
  /// Joker ×2 on the match block only.
  static const int _ptsPerTeamExact = 2;
  int get _maxMatchBlock => _ptsPerTeamExact * 2; // 4 before joker
  int get _jokerMultiplier => _model.jokerUsed ? 2 : 1;
  int get _maxMatchPointsWithJoker => _maxMatchBlock * _jokerMultiplier;
  int get _maxTotalPointsIfAllCorrect => _maxMatchPointsWithJoker;

  @override
  void initState() {
    super.initState();
    _model = FixturePredictionModel.initial(widget.fixtureId);
    _eventsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _eventsSize = CurvedAnimation(
      parent: _eventsController,
      curve: Curves.easeInOut,
    );
    _init();
  }

  Future<void> _init() async {
    try {
      final existing = await _repo.getPrediction(widget.fixtureId, roomId: widget.roomId);
      if (existing != null) {
        _model = existing;
        _model = _sanitizeModel(_model);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  FixturePredictionModel _sanitizeModel(FixturePredictionModel m) {
    if (m.homeScore != null && m.awayScore != null) {
      if (m.homeScore! > m.awayScore!) return m.copyWith(winner: PredictedWinner.home);
      if (m.homeScore! < m.awayScore!) return m.copyWith(winner: PredictedWinner.away);
      return m.copyWith(winner: PredictedWinner.draw);
    }
    return m;
  }

  @override
  void dispose() {
    _eventsController.dispose();
    super.dispose();
  }

  void _showPointsInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Points (if you get it right)'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Home team score correct: +$_ptsPerTeamExact'),
              const SizedBox(height: 4),
              Text('Away team score correct: +$_ptsPerTeamExact'),
              const SizedBox(height: 8),
              Text(
                'Match subtotal: $_maxMatchBlock pts'
                '${_model.jokerUsed ? '  →  with Joker: $_maxMatchPointsWithJoker pts (×2)' : ''}',
              ),
              const SizedBox(height: 8),
              const Text('Winner pick correct (Home/Draw/Away): +2'),
              const SizedBox(height: 12),
              const Text('Match events (optional picks): +1 correct, −1 wrong'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setScore({int? home, int? away}) {
    final nextHome = home ?? _model.homeScore;
    final nextAway = away ?? _model.awayScore;
    
    PredictedWinner newWinner = _model.winner;
    if (nextHome != null && nextAway != null) {
      if (nextHome > nextAway) {
        newWinner = PredictedWinner.home;
      } else if (nextHome < nextAway) {
        newWinner = PredictedWinner.away;
      } else {
        newWinner = PredictedWinner.draw;
      }
    }

    setState(() {
      _model = _model.copyWithNullableScores(
        homeScore: nextHome,
        awayScore: nextAway,
      ).copyWith(winner: newWinner);
    });
  }

  Future<void> _toggleJoker(bool value) async {
    if (_locked) return;
    if (!value) {
      setState(() => _model = _model.copyWith(jokerUsed: false));
      return;
    }

    final allowed = await _repo.canUseJokerThisWeek();
    final currentJokerFixture = await _repo.getWeeklyJokerFixtureId();

    if (!allowed && currentJokerFixture != widget.fixtureId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only use ONE Joker per week.'),
        ),
      );
      return;
    }

    await _repo.setWeeklyJokerFixture(widget.fixtureId);
    setState(() => _model = _model.copyWith(jokerUsed: true));
  }

  Future<void> _save() async {
    if (_locked) return;
    setState(() => _saving = true);
    try {
      await _repo.savePrediction(_model, roomId: widget.roomId);
      final dashRepo = DashboardPredictionRepository();
      await dashRepo.upsert(
        DashboardPredictionModel(
          fixtureId: '${widget.fixtureId}',
          leagueId: '${widget.leagueId}',
          leagueName: widget.leagueName,
          homeTeam: widget.homeTeam,
          awayTeam: widget.awayTeam,
          homeLogo: widget.homeLogo,
          awayLogo: widget.awayLogo,
          homeTeamId: widget.homeTeamId,
          awayTeamId: widget.awayTeamId,
          kickoffIso: widget.kickoffTime.toIso8601String(),
          homeScore: _model.homeScore ?? 0,
          awayScore: _model.awayScore ?? 0,
          predictedWinner: _winnerCode(_model.winner),
          jokerUsed: _model.jokerUsed,
          matchStatus: 'UPCOMING',
          savedAtIso: DateTime.now().toIso8601String(),
        ),
      );
      // Save to Node.js Render Backend
      try {
        final Map<String, dynamic> data = {
          'api_fixture_id': widget.fixtureId,
          'home_score': _model.homeScore ?? 0,
          'away_score': _model.awayScore ?? 0,
          'red_card': _model.redCardYesNo,
          'penalty': _model.penaltyYesNo,
          'joker': _model.jokerUsed,
        };
        if (widget.roomId != null) {
          data['room_id'] = widget.roomId;
        }
        await ApiClient.instance.post('/predictions', data: data);
      } catch (e) {
        if (e.toString().contains('already predicted')) {
           // We might need to use PUT if we already predicted it in Postgres.
           // However, to keep it simple, we could just ignore or handle update.
        }
        print('Backend sync error: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediction saved!')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _winnerCode(PredictedWinner w) {
    switch (w) {
      case PredictedWinner.home:
        return 'HOME';
      case PredictedWinner.away:
        return 'AWAY';
      case PredictedWinner.draw:
        return 'DRAW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • HH:mm');
    final kickoff = df.format(widget.kickoffTime.toLocal());

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _showPointsInfo,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Up to',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$_maxTotalPointsIfAllCorrect pts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: ElevatedButton(
          onPressed: _locked || _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _locked
                ? 'Predictions are closed for this match'
                : (_saving ? 'Saving...' : 'Save prediction'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _MatchHeader(
            homeTeam: widget.homeTeam,
            awayTeam: widget.awayTeam,
            homeLogo: widget.homeLogo,
            awayLogo: widget.awayLogo,
            kickoffLabel: kickoff,
            locked: _locked,
          ),
          const SizedBox(height: 14),

          _Section(
            title: 'Who will win?',
            subtitle: 'Pick Home, Draw, or Away (+2 if correct)',
            trailing: const _PointsPill(correctPts: 2, wrongNegPts: 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WinnerChoiceChip(
                  label: 'Home',
                  selected: _model.winner == PredictedWinner.home,
                  enabled: !_locked && (_model.homeScore == null || _model.awayScore == null),
                  onTap: () => setState(
                    () => _model = _model.copyWith(winner: PredictedWinner.home),
                  ),
                ),
                _WinnerChoiceChip(
                  label: 'Draw',
                  selected: _model.winner == PredictedWinner.draw,
                  enabled: !_locked && (_model.homeScore == null || _model.awayScore == null),
                  onTap: () => setState(
                    () => _model = _model.copyWith(winner: PredictedWinner.draw),
                  ),
                ),
                _WinnerChoiceChip(
                  label: 'Away',
                  selected: _model.winner == PredictedWinner.away,
                  enabled: !_locked && (_model.homeScore == null || _model.awayScore == null),
                  onTap: () => setState(
                    () => _model = _model.copyWith(winner: PredictedWinner.away),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Section(
            title: 'Exact score',
            subtitle: 'Get +2 for each team score you predict correctly',
            trailing: const _ExactScorePointsPill(),
            child: Row(
              children: [
                Expanded(
                  child: _ScoreDropdown(
                    label: widget.homeTeam,
                    value: _model.homeScore,
                    enabled: !_locked,
                    onChanged: (v) => _setScore(home: v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('-', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                Expanded(
                  child: _ScoreDropdown(
                    label: widget.awayTeam,
                    value: _model.awayScore,
                    enabled: !_locked,
                    onChanged: (v) => _setScore(away: v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Section(
            title: 'Joker (weekly multiplier)',
            subtitle: 'Only one Joker per week · ×2 on match points (+$_maxMatchBlock → +${_maxMatchBlock * 2})',
            child: SwitchListTile(
              value: _model.jokerUsed,
              onChanged: _locked ? null : _toggleJoker,
              title: const Text('Use Joker for this match'),
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          _Section(
            title: 'Predict match events',
            subtitle: 'Extra points if correct',
            trailing: IconButton(
              onPressed: () {
                setState(() => _eventsExpanded = !_eventsExpanded);
                if (_eventsExpanded) {
                  _eventsController.forward();
                } else {
                  _eventsController.reverse();
                }
              },
              icon: AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                turns: _eventsExpanded ? 0.5 : 0,
                child: const Icon(Icons.expand_more_rounded),
              ),
            ),
            child: SizeTransition(
              sizeFactor: _eventsSize,
              axisAlignment: -1,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _EventToggle(
                    title: 'Red card',
                    titleSuffix: const _HalfPointsPill(),
                    value: _model.redCardYesNo,
                    enabled: !_locked,
                    onChanged: (v) =>
                        setState(() => _model = _model.copyWith(redCardYesNo: v)),
                  ),
                  const SizedBox(height: 10),
                  _EventToggle(
                    title: 'Penalty',
                    titleSuffix: const _HalfPointsPill(),
                    value: _model.penaltyYesNo,
                    enabled: !_locked,
                    onChanged: (v) =>
                        setState(() => _model = _model.copyWith(penaltyYesNo: v)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// +2 for each team's correct score (max 4).
class _ExactScorePointsPill extends StatelessWidget {
  const _ExactScorePointsPill();

  @override
  Widget build(BuildContext context) {
    return const _PointsPill(correctPts: 4, wrongNegPts: 0);
  }
}

class _HalfPointsPill extends StatelessWidget {
  const _HalfPointsPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Text(
        '+1 / −1',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

/// Colored pill: correct points (green/teal scale) and wrong (−1 or 0).
class _PointsPill extends StatelessWidget {
  final int correctPts;
  /// 0 → show grey/orange "0" (no minus). 1 → show "−1".
  final int wrongNegPts;

  const _PointsPill({
    required this.correctPts,
    required this.wrongNegPts,
  });

  Color _correctColor() {
    if (correctPts >= 3) return Colors.green.shade400;
    if (correctPts == 2) return const Color(0xFF2DD4BF);
    return Colors.lightGreenAccent.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pos = _correctColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 15, color: pos),
          Text(
            ' +$correctPts  ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: pos,
            ),
          ),
          Icon(
            Icons.close_rounded,
            size: 15,
            color: wrongNegPts > 0 ? Colors.red.shade300 : Colors.orange.shade300,
          ),
          Text(
            wrongNegPts > 0 ? ' −$wrongNegPts' : ' 0',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: wrongNegPts > 0 ? Colors.red.shade200 : Colors.orange.shade200,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final String kickoffLabel;
  final bool locked;

  const _MatchHeader({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.kickoffLabel,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _TeamHeader(name: homeTeam, logo: homeLogo)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              Expanded(child: _TeamHeader(name: awayTeam, logo: awayLogo)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            kickoffLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Prediction locked',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  final String name;
  final String? logo;
  const _TeamHeader({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: (logo == null || logo!.isEmpty)
              ? Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.shield_outlined, size: 18),
                )
              : Image.network(
                  logo!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.withOpacity(0.2),
                    child: const Icon(Icons.shield_outlined, size: 18),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ScoreDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _ScoreDropdown({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: value,
          hint: const Text('Score'),
          items: List.generate(
            11,
            (i) => DropdownMenuItem(value: i, child: Text('$i')),
          ),
          onChanged: enabled ? (v) => onChanged(v ?? 0) : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _EventToggle extends StatelessWidget {
  final String title;
  final Widget? titleSuffix;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _EventToggle({
    required this.title,
    this.titleSuffix,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: enabled ? onChanged : null,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (titleSuffix != null) titleSuffix!,
            ],
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _WinnerChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _WinnerChoiceChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBg = theme.colorScheme.primary.withOpacity(0.18);
    final unselectedBg = theme.colorScheme.surfaceVariant.withOpacity(0.45);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withOpacity(0.45);
    final textColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.8 : 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// Team picker removed (events are simple yes/no).
