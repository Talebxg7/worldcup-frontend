import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_navigation_drawer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../models/competition.dart';
import '../widgets/competition_card.dart';
import '../widgets/league_challenge_banner.dart';
import '../widgets/live_fixtures_marquee.dart';

class CompetitionSelectionScreen extends ConsumerStatefulWidget {
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
  ConsumerState<CompetitionSelectionScreen> createState() =>
      _CompetitionSelectionScreenState();
}

class _CompetitionSelectionScreenState extends ConsumerState<CompetitionSelectionScreen> {
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
      
      final userState = ref.read(authStateProvider).value;
      if (userState == null) return;

      final announcementTime = DateTime.parse(createdAt);
      final now = DateTime.now();

      // Skip announcement if it is older than 7 days
      if (now.difference(announcementTime).inDays > 7) {
        return;
      }

      // Check user's seen status
      final lastSeen = userState.lastSeenAnnouncement;
      if (lastSeen != null) {
        if (announcementTime.isBefore(lastSeen) || announcementTime.isAtSameMomentAs(lastSeen)) {
          return;
        }
      } else {
        // Fallback for new users: skip announcements created before registration
        if (announcementTime.isBefore(userState.createdAt)) {
          return;
        }
      }

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
                try {
                  await ref.read(authStateProvider.notifier).markAnnouncementAsSeen();
                } catch (e) {
                  debugPrint('Failed to save announcement seen status: $e');
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('Close'.tr(ref)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Failed to fetch/process announcement: $e');
    }
  }  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            tooltip: 'Menu'.tr(ref),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          widget.title.tr(ref),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF080C14).withOpacity(0.95) : null,
        actions: [
          if (widget.showTopActions) ...[
            IconButton(
              tooltip: 'Live'.tr(ref),
              onPressed: () => context.go('/home/live'),
              icon: const Icon(Icons.sports_soccer_rounded, color: AppColors.stadiumNeonGreen),
            ),
            IconButton(
              tooltip: 'Standings'.tr(ref),
              onPressed: () => context.go('/home/standings'),
              icon: const Icon(Icons.leaderboard_rounded, color: AppColors.stadiumTrophyGold),
            ),
          ],
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0C1322),
                    Color(0xFF080C14),
                    Color(0xFF05080E),
                  ],
                )
              : AppColors.lightStadiumGradient,
        ),
        child: _competitions == null 
              ? const Center(child: CircularProgressIndicator(color: AppColors.stadiumNeonGreen))
              : RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.stadiumNeonGreen,
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
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: const LeagueChallengeBanner(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: LiveFixturesMarquee(),
                    ),
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
      ),
    );
  }

  List<Color> _gradientFor(int leagueId) {
    switch (leagueId) {
      case 39: // Premier League (Royal Purple & Vivid Violet)
        return const [Color(0xFF2E0854), Color(0xFF6B21A8), Color(0xFF9333EA)];
      case 140: // La Liga (Crimson & Solar Amber)
        return const [Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFFEA580C)];
      case 135: // Serie A (Italian Azzurro & Deep Sapphire)
        return const [Color(0xFF0F172A), Color(0xFF1E40AF), Color(0xFF0284C7)];
      case 78: // Bundesliga (Midnight Charcoal & Vivid Scarlet)
        return const [Color(0xFF18181B), Color(0xFF991B1B), Color(0xFFDC2626)];
      case 61: // Ligue 1 (French Electric Blue & Neon Emerald)
        return const [Color(0xFF0C1B33), Color(0xFF0284C7), Color(0xFF059669)];
      case 1: // FIFA World Cup (FIFA Emerald & Trophy Gold)
        return const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFFD97706)];
      case 2: // UEFA Champions League (Starball Deep Space Navy & Cyan)
        return const [Color(0xFF030B1E), Color(0xFF0F2B66), Color(0xFF1D4ED8)];
      case 3: // UEFA Europa League (Europa Midnight & Electric Copper)
        return const [Color(0xFF18181B), Color(0xFF9A3412), Color(0xFFEA580C)];
      case 94: // Primeira Liga (Portuguese Forest & Crimson)
        return const [Color(0xFF064E3B), Color(0xFF15803D), Color(0xFFB91C1C)];
      case 307: // Saudi Pro League (Saudi Royal Green & Emerald)
        return const [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF10B981)];
      case 233: // Egyptian Premier League (Pharaoh Midnight Gold & Crimson)
        return const [Color(0xFF1C1917), Color(0xFFB45309), Color(0xFFDC2626)];
      case 305: // Qatar Stars League (Qatari Maroon & Vivid Berry)
        return const [Color(0xFF4C0519), Color(0xFF881337), Color(0xFFBE123C)];
      case 200: // Botola Pro (Moroccan Red & Emerald)
        return const [Color(0xFF7F1D1D), Color(0xFF991B1B), Color(0xFF047857)];
      case 542: // Iraqi League (Mesopotamian Green & Azure)
        return const [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF1E40AF)];
      case 6: // AFCON (African Sun & Green)
        return const [Color(0xFF78350F), Color(0xFFD97706), Color(0xFF059669)];
      case 9: // Copa America (South American Blue & Sun)
        return const [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFFCA8A04)];
      case 387: // Jordan League (Jordanian Midnight & Emerald)
        return const [Color(0xFF18181B), Color(0xFF047857), Color(0xFFB91C1C)];
      default:
        return const [Color(0xFF0F172A), Color(0xFF0284C7), Color(0xFF10B981)];
    }
  }
}

