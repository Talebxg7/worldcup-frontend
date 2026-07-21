import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class ChallengePlayerModel {
  final String name;
  final String? teamName;
  final String? position;

  ChallengePlayerModel({
    required this.name,
    this.teamName,
    this.position,
  });

  factory ChallengePlayerModel.fromJson(Map<String, dynamic> json) {
    return ChallengePlayerModel(
      name: json['name'] ?? '',
      teamName: json['team_name'] as String?,
      position: json['position'] as String?,
    );
  }
}

class ChallengeTeamModel {
  final String name;
  final String flag;

  ChallengeTeamModel({required this.name, required this.flag});

  factory ChallengeTeamModel.fromJson(Map<String, dynamic> json) {
    return ChallengeTeamModel(
      name: json['name'] ?? '',
      flag: json['flag'] ?? '',
    );
  }
}

class LeagueChallengeDetailScreen extends ConsumerStatefulWidget {
  final int leagueId;
  const LeagueChallengeDetailScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueChallengeDetailScreen> createState() => _LeagueChallengeDetailScreenState();
}

class _LeagueChallengeDetailScreenState extends ConsumerState<LeagueChallengeDetailScreen> {
  bool _isLoading = false;
  bool _isSaving = false;

  String _leagueName = '';
  String _leagueEmoji = '⚽';
  List<ChallengeTeamModel> _teams = [];
  String? _selectedTeam;
  String? _selectedScorer;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch league details
      final leaguesRes = await ApiClient.instance.get('/leagues');
      if (leaguesRes.data is List) {
        for (var item in leaguesRes.data) {
          if (item['api_league_id'] == widget.leagueId) {
            _leagueName = item['name'] ?? '';
            _leagueEmoji = item['emoji'] ?? '⚽';
            break;
          }
        }
      }

      // 2. Fetch teams for this league
      final teamsRes = await ApiClient.instance.get('/matches/leagues/${widget.leagueId}/teams');
      List<ChallengeTeamModel> loadedTeams = [];
      if (teamsRes.data is List) {
        loadedTeams = (teamsRes.data as List)
            .map((t) => ChallengeTeamModel.fromJson(t as Map<String, dynamic>))
            .toList();
      }

      // 3. Fetch user's existing prediction and lock status
      final predRes = await ApiClient.instance.get('/challenge/predictions/${widget.leagueId}');
      String? teamPred;
      String? scorerPred;
      bool lockedVal = false;

      if (predRes.data != null) {
        lockedVal = predRes.data['locked'] ?? false;
        final pred = predRes.data['prediction'];
        if (pred != null) {
          teamPred = pred['predicted_team_name'];
          scorerPred = pred['predicted_top_scorer'];
        }
      }

      setState(() {
        _teams = loadedTeams;
        _isLocked = lockedVal;
        _selectedTeam = teamPred;
        _selectedScorer = scorerPred;
      });
    } catch (e) {
      debugPrint('Failed to load league challenge details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrediction() async {
    if (_selectedTeam == null || _selectedTeam!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a champion team')),
      );
      return;
    }
    if (_selectedScorer == null || _selectedScorer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the predicted top scorer')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await ApiClient.instance.post('/challenge/predictions', data: {
        'league_id': widget.leagueId,
        'predicted_team_name': _selectedTeam,
        'predicted_top_scorer': _selectedScorer,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Predictions saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Submission failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save predictions. Please try again.'),
            backgroundColor: AppColors.wrongResult,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openPlayerSearch() {
    showDialog(
      context: context,
      builder: (context) => _PlayerSearchDialog(
        leagueId: widget.leagueId,
        onSelected: (player) {
          setState(() {
            _selectedScorer = player.name;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

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
          title: Text('$_leagueEmoji ${_leagueName.tr(ref)}'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (!_isLocked && !_isLoading)
              TextButton(
                onPressed: _isSaving ? null : _savePrediction,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Text(
                        'Save'.tr(ref),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary),
                      ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lock Indicator Banner
                    if (_isLocked)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.wrongResult.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.wrongResult.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_rounded, color: AppColors.wrongResult, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Predictions are locked for this season!'.tr(ref),
                                style: TextStyle(
                                  color: AppColors.wrongResult,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Section 1: Champion Prediction
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'League Champion (+50 pts)'.tr(ref),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_teams.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No clubs found in this league.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: _teams.length,
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          final isSelected = _selectedTeam == team.name;
                          return Material(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkCard : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isLocked
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedTeam = team.name;
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.withOpacity(0.2),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (team.flag.isNotEmpty)
                                      Image.network(
                                        team.flag,
                                        width: 28,
                                        height: 28,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.shield, size: 24, color: Colors.grey),
                                      )
                                    else
                                      const Icon(Icons.shield, size: 24, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        team.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),

                    // Section 2: Top Scorer Prediction
                    Row(
                      children: [
                        const Icon(Icons.sports_soccer_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Top Scorer (+30 pts)'.tr(ref),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selectedScorer != null) ...[
                            Text(
                              _selectedScorer!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            const Text(
                              'No top scorer selected yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (!_isLocked)
                            ElevatedButton.icon(
                              onPressed: _openPlayerSearch,
                              icon: const Icon(Icons.search_rounded),
                              label: Text('Choose Top Scorer'.tr(ref)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PlayerSearchDialog extends StatefulWidget {
  final int leagueId;
  final ValueChanged<ChallengePlayerModel> onSelected;

  const _PlayerSearchDialog({
    required this.leagueId,
    required this.onSelected,
  });

  @override
  State<_PlayerSearchDialog> createState() => _PlayerSearchDialogState();
}

class _PlayerSearchDialogState extends State<_PlayerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ChallengePlayerModel> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _results = [];
          _searching = false;
        });
        return;
      }
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);
    try {
      final res = await ApiClient.instance.get(
        '/challenge/leagues/${widget.leagueId}/players',
        params: {'q': query},
      );
      if (res.data is List) {
        final List<ChallengePlayerModel> loaded = (res.data as List)
            .map((p) => ChallengePlayerModel.fromJson(p as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _results = loaded;
            _searching = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching players: $e');
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Search Top Scorer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type player name (e.g. L)...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchController.text.trim().isEmpty
                        ? const Center(
                            child: Text(
                              'Type at least 1 character to search.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : _results.isEmpty
                            ? const Center(
                                child: Text(
                                  'No players found.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final player = _results[index];
                                  final subtitle = '${player.teamName ?? ''} • ${player.position ?? ''}';
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    title: Text(
                                      player.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    onTap: () {
                                      widget.onSelected(player);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
