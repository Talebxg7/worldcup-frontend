import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/localization/app_localizations.dart';
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
  static const Map<int, String> _leagueBackgroundById = {
    39: 'assets/images/premier_league.jpg',
    140: 'assets/images/la_liga.png',
    135: 'assets/images/serie_a.jpg',
    78: 'assets/images/bundesliga.png',
    61: 'assets/images/ligue1_bg.png',
    233: 'assets/images/egyptian_league.png',
    94: 'assets/images/portuguese.webp',
    1: 'assets/images/world_cup.png',
    2: 'assets/images/uefa_champions_bg.png',
    3: 'assets/images/uefa_europa_bg.png',
    6: 'assets/images/afcon_bg.png',
    9: 'assets/images/copa_america_bg.png',
    307: 'assets/images/saudi_league.png',
    305: 'assets/images/qatar_league.jpg',
    387: 'assets/images/jordan_league_bg.jpg',
    542: 'assets/images/iraqi_league.jpg',
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
    final backgroundAsset = _leagueBackgroundById[competition.leagueId];
    final badgeText = isLoadingCount
        ? 'Loading...'.tr(ref)
        : upcomingCount == null
            ? '—'
            : '$upcomingCount ' + 'upcoming'.tr(ref);

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              if (backgroundAsset != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildBackground(backgroundAsset),
                  ),
                ),
              if (backgroundAsset != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.20),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          competition.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      competition.name.tr(ref),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      competition.subtitle.tr(ref),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD700), // Permanently Gold/Amber color
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tickerItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ScrollingTicker(items: tickerItems),
                    ],
                  ],
                ),
              ),
              if (disabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.28),
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
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
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
    );
  }

  Widget _buildBackground(String source) {
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }
    return Image.file(
      File(source),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
    // If not standard, take first letter of each word
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
