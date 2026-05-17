import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/football_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/football_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/competition.dart';
import '../widgets/competition_card.dart';
import '../../../matches/presentation/screens/prediction_fixtures_screen.dart';
import '../../../matches/presentation/screens/live_screen.dart';
import '../../../matches/presentation/screens/standings_screen.dart';

class CompetitionSelectionScreen extends StatefulWidget {
  final String title;
  final void Function(BuildContext context, Competition competition)? onSelect;
  final bool showTopActions;

  const CompetitionSelectionScreen({
    super.key,
    this.title = 'Pick a Competition',
    this.onSelect,
    this.showTopActions = true,
  });

  @override
  State<CompetitionSelectionScreen> createState() =>
      _CompetitionSelectionScreenState();
}

class _CompetitionSelectionScreenState extends State<CompetitionSelectionScreen> {
  List<Competition>? _competitions;

  @override
  void initState() {
    super.initState();
    _fetchLeagues();
    _checkAnnouncement();
  }

  Future<void> _fetchLeagues() async {
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
          _competitions = loaded;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch leagues: $e');
      if (mounted) {
        setState(() {
          _competitions = [];
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _fetchLeagues();
  }

  Future<void> _checkAnnouncement() async {
    try {
      final res = await ApiClient.instance.get('/announcement');
      if (res.data == null) return;
      
      final title = res.data['title'] as String;
      final body = res.data['body'] as String;
      final createdAt = res.data['created_at'] as String;
      
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString('last_announcement');
      
      if (lastSeen != createdAt) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.campaign, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(body),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await prefs.setString('last_announcement', createdAt);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch announcement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (widget.showTopActions) ...[
            IconButton(
              tooltip: 'Live',
              onPressed: () => context.go('/home/live'),
              icon: const Icon(Icons.sports_soccer_rounded),
            ),
            IconButton(
              tooltip: 'Standings',
              onPressed: () => context.go('/home/standings'),
              icon: const Icon(Icons.leaderboard_rounded),
            ),
          ],
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _competitions == null 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final cols = w < 560
                  ? 2
                  : w < 900
                      ? 3
                      : 4;

              return CustomScrollView(
                slivers: [
                  if (_competitions!.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: AspectRatio(
                          aspectRatio: (cols == 2 ? 2.2 : 3.3) / 1.1,
                          child: CompetitionCard(
                            competition: _competitions![0],
                            gradientColors: _gradientFor(_competitions![0].leagueId),
                            upcomingCount: _competitions![0].upcomingCount,
                            isLoadingCount: false,
                            onTap: () {
                              final onSelect = widget.onSelect;
                              if (onSelect != null) {
                                onSelect(context, _competitions![0]);
                                return;
                              }
                              context.go(
                                '/home/fixtures?leagueId=${_competitions![0].leagueId}&leagueName=${Uri.encodeComponent(_competitions![0].name)}',
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (_competitions!.length > 1)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final comp = _competitions![index + 1];
                            return CompetitionCard(
                              competition: comp,
                              gradientColors: _gradientFor(comp.leagueId),
                              upcomingCount: comp.upcomingCount,
                              isLoadingCount: false,
                              onTap: () {
                                final onSelect = widget.onSelect;
                                if (onSelect != null) {
                                  onSelect(context, comp);
                                  return;
                                }
                                context.go(
                                  '/home/fixtures?leagueId=${comp.leagueId}&leagueName=${Uri.encodeComponent(comp.name)}',
                                );
                              },
                            );
                          },
                          childCount: _competitions!.length - 1,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
    );
  }

  List<Color> _gradientFor(int leagueId) {
    switch (leagueId) {
      case 39: // Premier League
        return const [Color(0xFF8B5CF6), Color(0xFFEC4899)];
      case 140: // La Liga
        return const [Color(0xFFEF4444), Color(0xFFF97316)];
      case 135: // Serie A
        return const [Color(0xFF3B82F6), Color(0xFF60A5FA)];
      case 78: // Bundesliga
        return const [Color(0xFFB91C1C), Color(0xFFFB7185)];
      case 61: // Ligue 1
        return const [Color(0xFF06B6D4), Color(0xFF3B82F6)];
      case 233: // Egypt
        return const [Color(0xFFF59E0B), Color(0xFF10B981)];
      case 94: // Portugal
        return const [Color(0xFF22C55E), Color(0xFF16A34A)];
      case 1: // World Cup
        return const [Color(0xFFF59E0B), Color(0xFFF97316)];
      case 2: // UCL
        return const [Color(0xFF7C3AED), Color(0xFF60A5FA)];
      case 3: // UEL
        return const [Color(0xFFFB923C), Color(0xFFFDE047)];
      case 6: // AFCON
        return const [Color(0xFF10B981), Color(0xFF22C55E)];
      case 9: // Copa America
        return const [Color(0xFF0EA5E9), Color(0xFF22C55E)];
      case 307: // Saudi Pro League
        return const [Color(0xFF1D4ED8), Color(0xFF0F766E)];
      case 305: // Qatar Stars League
        return const [Color(0xFF9D174D), Color(0xFFBE185D)];
      case 200: // Botola Pro
        return const [Color(0xFFDC2626), Color(0xFF16A34A)];
      case 542: // Iraqi League
        return const [Color(0xFF047857), Color(0xFF1E40AF)];
      default:
        return const [Color(0xFF0EA5E9), Color(0xFF3B82F6)];
    }
  }
}

