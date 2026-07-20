import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/competition.dart';

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

class LeagueChallengeDialog extends ConsumerStatefulWidget {
  final int? initialLeagueId;

  const LeagueChallengeDialog({super.key, this.initialLeagueId});

  @override
  ConsumerState<LeagueChallengeDialog> createState() => _LeagueChallengeDialogState();
}

class _LeagueChallengeDialogState extends ConsumerState<LeagueChallengeDialog> {
  bool _isLoadingLeagues = false;
  bool _isLoadingData = false;
  bool _isSubmitting = false;

  List<Competition> _leagues = [];
  int? _selectedLeagueId;
  
  List<String> _teams = [];
  String? _selectedTeamName;
  final TextEditingController _scorerController = TextEditingController();
  
  List<ChallengePlayerModel> _players = [];
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _selectedLeagueId = widget.initialLeagueId;
    _initFlow();
  }

  @override
  void dispose() {
    _scorerController.dispose();
    super.dispose();
  }

  Future<void> _initFlow() async {
    await _fetchLeagues();
    if (_selectedLeagueId != null) {
      await _loadLeagueData(_selectedLeagueId!);
    }
  }

  Future<void> _fetchLeagues() async {
    setState(() => _isLoadingLeagues = true);
    try {
      final res = await ApiClient.instance.get('/leagues');
      if (res.data is List) {
        final List<Competition> loaded = [];
        for (var item in res.data) {
          loaded.add(Competition(
            name: item['name'] ?? '',
            subtitle: item['subtitle'] ?? '',
            leagueId: item['api_league_id'],
            emoji: item['emoji'] ?? '⚽',
            isEnabled: item['is_enabled'] ?? true,
            upcomingCount: item['upcoming_count'] ?? 0,
          ));
        }
        setState(() {
          _leagues = loaded;
          if (_selectedLeagueId == null && _leagues.isNotEmpty) {
            _selectedLeagueId = _leagues.first.leagueId;
            _loadLeagueData(_selectedLeagueId!);
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch leagues for challenge: $e');
    } finally {
      setState(() => _isLoadingLeagues = false);
    }
  }

  Future<void> _loadLeagueData(int leagueId) async {
    setState(() {
      _isLoadingData = true;
      _teams = [];
      _players = [];
      _selectedTeamName = null;
      _scorerController.clear();
      _isLocked = false;
    });

    try {
      // 1. Fetch teams for this league
      final teamsRes = await ApiClient.instance.get('/matches/leagues/$leagueId/teams');
      List<String> loadedTeams = [];
      if (teamsRes.data is List) {
        loadedTeams = List<String>.from(teamsRes.data);
      }

      // 2. Fetch user's existing prediction and lock status
      final predRes = await ApiClient.instance.get('/challenge/predictions/$leagueId');
      
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

      // 3. Fetch players list for this league
      final playersRes = await ApiClient.instance.get('/challenge/leagues/$leagueId/players');
      List<ChallengePlayerModel> loadedPlayers = [];
      if (playersRes.data is List) {
        loadedPlayers = (playersRes.data as List)
            .map((p) => ChallengePlayerModel.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      setState(() {
        _teams = loadedTeams;
        _players = loadedPlayers;
        _isLocked = lockedVal;
        
        if (teamPred != null && _teams.contains(teamPred)) {
          _selectedTeamName = teamPred;
        } else if (_teams.isNotEmpty) {
          _selectedTeamName = null;
        }
        
        if (scorerPred != null) {
          _scorerController.text = scorerPred;
        }
      });
    } catch (e) {
      debugPrint('Failed to load challenge data: $e');
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  void _showPlayerPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return _PlayerSearchDialog(
          players: _players,
          onSelected: (player) {
            setState(() {
              _scorerController.text = player.name;
            });
          },
        );
      },
    );
  }

  Future<void> _submitPrediction() async {
    if (_selectedLeagueId == null) return;
    if (_selectedTeamName == null || _selectedTeamName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a champion team')),
      );
      return;
    }
    if (_scorerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the predicted top scorer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiClient.instance.post('/challenge/predictions', data: {
        'league_id': _selectedLeagueId,
        'predicted_team_name': _selectedTeamName,
        'predicted_top_scorer': _scorerController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Prediction saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Submission failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit predictions. Please try again.'),
            backgroundColor: AppColors.wrongResult,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Season Challenge'.tr(ref),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1.2),

              // League Selector (only if not passed initially)
              if (widget.initialLeagueId == null) ...[
                Text(
                  'Select League'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (_isLoadingLeagues)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<int>(
                    value: _selectedLeagueId,
                    dropdownColor: cardColor,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _leagues.map((lg) {
                      return DropdownMenuItem<int>(
                        value: lg.leagueId,
                        child: Text('${lg.emoji} ${lg.name.tr(ref)}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLeagueId = val);
                        _loadLeagueData(val);
                      }
                    },
                  ),
                const SizedBox(height: 16),
              ] else ...[
                // Show readonly league banner
                if (_leagues.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_soccer_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _leagues.firstWhere((l) => l.leagueId == _selectedLeagueId, orElse: () => _leagues.first).name.tr(ref),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              if (_isLoadingData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Lock Banner
                if (_isLocked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.wrongResult.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.wrongResult.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.wrongResult, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Predictions are locked for this season!'.tr(ref),
                            style: TextStyle(
                              color: AppColors.wrongResult,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Champion Team prediction
                Text(
                  'League Champion (+50 pts)'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTeamName,
                  dropdownColor: cardColor,
                  hint: Text('Select Team'.tr(ref)),
                  disabledHint: Text(_selectedTeamName ?? 'No Prediction'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _teams.map((t) {
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Text(t),
                    );
                  }).toList(),
                  onChanged: _isLocked
                      ? null
                      : (val) {
                          setState(() => _selectedTeamName = val);
                        },
                ),
                const SizedBox(height: 16),

                // 2. Top Scorer prediction
                Text(
                  'Top Scorer (+30 pts)'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scorerController,
                  readOnly: true,
                  enabled: !_isLocked,
                  onTap: _isLocked ? null : _showPlayerPicker,
                  decoration: InputDecoration(
                    hintText: 'Select Player'.tr(ref),
                    suffixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                if (!_isLocked)
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Save Prediction'.tr(ref),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  )
                else
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Locked'.tr(ref),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSearchDialog extends StatefulWidget {
  final List<ChallengePlayerModel> players;
  final ValueChanged<ChallengePlayerModel> onSelected;

  const _PlayerSearchDialog({
    required this.players,
    required this.onSelected,
  });

  @override
  State<_PlayerSearchDialog> createState() => _PlayerSearchDialogState();
}

class _PlayerSearchDialogState extends State<_PlayerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ChallengePlayerModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.players;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.players;
      } else {
        _filtered = widget.players.where((p) {
          return p.name.toLowerCase().contains(query) ||
              (p.teamName?.toLowerCase().contains(query) ?? false) ||
              (p.position?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                'Select Player',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search player or team...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No players found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final player = _filtered[index];
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
