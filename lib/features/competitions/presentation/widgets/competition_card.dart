import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/competition.dart';
import '../../../../services/football_api_service.dart';

/// Dynamic, auto-refreshing provider to fetch live match scores reactively every 30 seconds
final liveMatchesProvider = StreamProvider<List<FixtureModel>>((ref) async* {
  while (true) {
    try {
      final fixtures = await FootballApiService.getFixtures(live: 'all');
      yield fixtures;
    } catch (_) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

class CompetitionCard extends ConsumerWidget {
  final Competition competition;
  final int? upcomingCount;
  final bool isLoadingCount;
  final VoidCallback? onTap;
  final List<Color> gradientColors;

  static const Map<int, String> _leagueFlagById = {
    39: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', // Premier League -> England
    140: '🇪🇸',   // La Liga -> Spain
    135: '🇮🇹',   // Serie A -> Italy
    78: '🇩🇪',    // Bundesliga -> Germany
    61: '🇫🇷',    // Ligue 1 -> France
    233: '🇪🇬',   // Egyptian Premier League -> Egypt
    94: '🇵🇹',    // Primeira Liga -> Portugal
    1: '🌍',     // FIFA World Cup -> World
    2: '🇪🇺',     // UEFA Champions League -> Europe
    3: '🇪🇺',     // UEFA Europa League -> Europe
    6: '🌍',     // AFCON -> Africa
    9: '🌎',     // Copa America -> South America
    307: '🇸🇦',   // Saudi Pro League -> Saudi Arabia
    305: '🇶🇦',   // Qatar Stars League -> Qatar
    387: '🇯🇴',   // Jordan League -> Jordan
    200: '🇲🇦',   // Botola Pro -> Morocco
    542: '🇮🇶',   // Iraqi League -> Iraq
  };

  static const Map<int, String> _tournamentBackgroundById = {
    1: 'assets/images/world_cup.png',
    2: 'assets/images/uefa_champions_bg.png',
    3: 'assets/images/uefa_europa_bg.png',
    6: 'assets/images/afcon_bg.png',
    9: 'assets/images/copa_america_bg.png',
  };

  static const Map<int, IconData> _leagueIconById = {
    1: Icons.emoji_events_rounded, // World Cup Trophy
    2: Icons.stars_rounded,        // Champions League Stars
    3: Icons.shield_rounded,       // Europa League
    39: Icons.sports_soccer_rounded, // Premier League
    140: Icons.sports_soccer_rounded, // La Liga
    78: Icons.sports_soccer_rounded, // Bundesliga
    135: Icons.sports_soccer_rounded, // Serie A
    61: Icons.sports_soccer_rounded, // Ligue 1
  };

  const CompetitionCard({
    super.key,
    required this.competition,
    required this.gradientColors,
    this.upcomingCount,
    this.isLoadingCount = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabled = !competition.isEnabled;
    final flag = _leagueFlagById[competition.leagueId] ?? competition.emoji;
    final watermarkIcon = _leagueIconById[competition.leagueId] ?? Icons.sports_soccer_rounded;
    final tournamentBg = _tournamentBackgroundById[competition.leagueId];

    final badgeText = isLoadingCount
        ? 'Loading...'.tr(ref)
        : upcomingCount == null
            ? '—'
            : '$upcomingCount ${'upcoming'.tr(ref)}';

    final liveMatchesAsync = ref.watch(liveMatchesProvider);
    final List<String> tickerItems = [];

    liveMatchesAsync.whenData((fixtures) {
      final leagueFixtures = fixtures.where((f) => f.leagueId == competition.leagueId).toList();
      for (var f in leagueFixtures) {
        const liveShort = {'1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE', 'INT'};
        if (liveShort.contains(f.status)) {
          final homeCode = _abbreviate(f.homeTeam);
          final awayCode = _abbreviate(f.awayTeam);
          tickerItems.add("• $homeCode ${f.homeGoals ?? 0} - ${f.awayGoals ?? 0} $awayCode •");
        }
      }
    });

    final hasUpcoming = upcomingCount != null && upcomingCount! > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Tournament Background Photo (if World Cup, UCL, UEL, AFCON, Copa America)
                if (tournamentBg != null)
                  Positioned.fill(
                    child: Image.asset(
                      tournamentBg,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                if (tournamentBg != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Subtle Ambient Stadium Light Glow for league cards
                if (tournamentBg == null)
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                  ),

                // Watermark for league cards
                if (tournamentBg == null)
                  Positioned(
                    bottom: -15,
                    right: -10,
                    child: Opacity(
                      opacity: 0.12,
                      child: Icon(
                        watermarkIcon,
                        size: 110,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Card Foreground Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Country Flag Pill & Upcoming Match Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Frosted Country Flag Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.20),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              flag,
                              style: const TextStyle(fontSize: 19),
                            ),
                          ),

                          // Upcoming Matches Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.40),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: hasUpcoming
                                    ? AppColors.stadiumNeonGreen.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.15),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasUpcoming) ...[
                                  const PulsingGreenDot(),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: hasUpcoming
                                        ? AppColors.stadiumNeonGreen
                                        : Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // League Name
                      Text(
                        competition.name.tr(ref),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Subtitle / Country in Vibrant Gold
                      Text(
                        competition.subtitle.tr(ref),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFFFD700).withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),

                      // Live Ticker if active
                      if (tickerItems.isNotEmpty && hasUpcoming) ...[
                        const SizedBox(height: 8),
                        ScrollingTicker(items: tickerItems),
                      ],
                    ],
                  ),
                ),

                // Coming Soon Disabled Overlay
                if (disabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.55),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            'Coming soon'.tr(ref),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScrollingTicker extends StatefulWidget {
  final List<String> items;
  const ScrollingTicker({super.key, required this.items});

  @override
  State<ScrollingTicker> createState() => _ScrollingTickerState();
}

class _ScrollingTickerState extends State<ScrollingTicker> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0.0);
      } else {
        _scrollController.jumpTo(currentScroll + 1.0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doubledItems = [...widget.items, ...widget.items, ...widget.items];

    return Container(
      height: 24,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doubledItems.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                doubledItems[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _abbreviate(String name) {
  if (name.isEmpty) return '???';
  final cleanName = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
  final parts = cleanName.split(' ');
  if (parts.length >= 2) {
    final firstWord = parts[0].toUpperCase();
    final secondWord = parts[1].toUpperCase();
    if (firstWord == 'REAL' && secondWord == 'MADRID') return 'RMA';
    if (firstWord == 'MANCHESTER' && secondWord == 'CITY') return 'MCI';
    if (firstWord == 'MANCHESTER' && secondWord == 'UNITED') return 'MUN';
    if (firstWord == 'BAYERN' && secondWord == 'MUNICH') return 'BAY';
    if (firstWord == 'ATLETICO' && secondWord == 'MADRID') return 'ATM';
    if (parts.length >= 3) {
      return '${parts[0][0]}${parts[1][0]}${parts[2][0]}'.toUpperCase();
    }
    final secondWordSub = parts[1].substring(0, math.min(2, parts[1].length));
    return '${parts[0][0]}$secondWordSub'.toUpperCase();
  }
  if (cleanName.length > 3) {
    return cleanName.substring(0, 3).toUpperCase();
  }
  return cleanName.toUpperCase();
}

class PulsingGreenDot extends StatefulWidget {
  const PulsingGreenDot({super.key});

  @override
  State<PulsingGreenDot> createState() => _PulsingGreenDotState();
}

class _PulsingGreenDotState extends State<PulsingGreenDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.stadiumNeonGreen,
            boxShadow: [
              BoxShadow(
                color: AppColors.stadiumNeonGreen.withOpacity(0.8 * _controller.value),
                blurRadius: 10 * _controller.value,
                spreadRadius: 4.0 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
