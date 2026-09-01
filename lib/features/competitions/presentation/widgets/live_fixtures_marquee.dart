import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/football_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/edge_fade_marquee.dart';
import '../../../../services/football_api_service.dart';

class TickerMatchItem {
  final int id;
  final int? leagueId;
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeScore;
  final int? awayScore;
  final int? liveMinute;
  final bool isLive;
  final bool isFinished;
  final DateTime kickoffTime;

  const TickerMatchItem({
    required this.id,
    this.leagueId,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    this.homeScore,
    this.awayScore,
    this.liveMinute,
    required this.isLive,
    required this.isFinished,
    required this.kickoffTime,
  });
}

const Map<int, String> appTrackedLeagueNames = {
  39: 'Premier League',
  140: 'La Liga',
  135: 'Serie A',
  78: 'Bundesliga',
  61: 'Ligue 1',
  2: 'Champions League',
  3: 'Europa League',
  1: 'World Cup',
  94: 'Primeira Liga',
  307: 'Saudi Pro League',
  233: 'Egyptian League',
  305: 'Qatar League',
  387: 'Jordan League',
  200: 'Botola Pro',
  542: 'Iraqi League',
};

final tickerMatchesProvider = FutureProvider<List<TickerMatchItem>>((ref) async {
  final List<TickerMatchItem> result = [];
  final Set<int> seenIds = {};

  // 1. Fetch live matches and filter ONLY by our tracked app leagues
  try {
    final live = await FootballApiService.getFixtures(live: 'all');
    for (final f in live) {
      if (f.leagueId != null && appTrackedLeagueNames.containsKey(f.leagueId)) {
        if (seenIds.add(f.id)) {
          result.add(TickerMatchItem(
            id: f.id,
            leagueId: f.leagueId,
            leagueName: appTrackedLeagueNames[f.leagueId] ?? f.leagueName ?? '',
            homeTeam: f.homeTeam,
            awayTeam: f.awayTeam,
            homeLogo: f.homeLogo,
            awayLogo: f.awayLogo,
            homeScore: f.homeGoals,
            awayScore: f.awayGoals,
            liveMinute: f.minute,
            isLive: true,
            isFinished: false,
            kickoffTime: f.date ?? DateTime.now(),
          ));
        }
      }
    }
  } catch (e) {
    debugPrint('Error fetching live fixtures for ticker: $e');
  }

  // 2. Fetch past 5 rounds / recent played match scores for our tracked leagues
  final priorityLeagues = [39, 140, 135, 78, 61, 2, 307, 233, 94];
  final currentSeason = FootballConfig.currentSeason();

  for (final leagueId in priorityLeagues) {
    try {
      final season = leagueId == 1 ? 2026 : currentSeason;
      final past = await FootballApiService.getFixtures(
        league: leagueId,
        season: season,
        last: 5,
      );
      for (final f in past) {
        if (f.homeGoals != null && f.awayGoals != null && seenIds.add(f.id)) {
          result.add(TickerMatchItem(
            id: f.id,
            leagueId: f.leagueId ?? leagueId,
            leagueName: appTrackedLeagueNames[leagueId] ?? f.leagueName ?? '',
            homeTeam: f.homeTeam,
            awayTeam: f.awayTeam,
            homeLogo: f.homeLogo,
            awayLogo: f.awayLogo,
            homeScore: f.homeGoals,
            awayScore: f.awayGoals,
            liveMinute: null,
            isLive: false,
            isFinished: true,
            kickoffTime: f.date ?? DateTime.now(),
          ));
        }
      }
    } catch (_) {}
  }

  // 3. Fetch upcoming matches if available
  if (result.length < 15) {
    for (final leagueId in priorityLeagues.take(4)) {
      try {
        final season = leagueId == 1 ? 2026 : currentSeason;
        final upcoming = await FootballApiService.getFixtures(
          league: leagueId,
          season: season,
          next: 4,
        );
        for (final f in upcoming) {
          if (seenIds.add(f.id)) {
            result.add(TickerMatchItem(
              id: f.id,
              leagueId: f.leagueId ?? leagueId,
              leagueName: appTrackedLeagueNames[leagueId] ?? f.leagueName ?? '',
              homeTeam: f.homeTeam,
              awayTeam: f.awayTeam,
              homeLogo: f.homeLogo,
              awayLogo: f.awayLogo,
              homeScore: null,
              awayScore: null,
              liveMinute: null,
              isLive: false,
              isFinished: false,
              kickoffTime: f.date ?? DateTime.now(),
            ));
          }
        }
      } catch (_) {}
    }
  }

  // Sort: Live matches first, then recent played matches descending
  result.sort((a, b) {
    if (a.isLive && !b.isLive) return -1;
    if (!a.isLive && b.isLive) return 1;
    return b.kickoffTime.compareTo(a.kickoffTime);
  });

  return result;
});

class LiveFixturesMarquee extends ConsumerWidget {
  const LiveFixturesMarquee({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tickerMatchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();

        final tickerMatches = matches.take(20).toList();
        if (tickerMatches.isEmpty) return const SizedBox.shrink();

        final hasLive = tickerMatches.any((m) => m.isLive);

        final items = tickerMatches.map((m) {
          return _MatchTickerCard(match: m, isDark: isDark);
        }).toList();

        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hasLive
                            ? AppColors.stadiumNeonGreen
                            : const Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                        boxShadow: hasLive
                            ? [
                                BoxShadow(
                                  color: AppColors.stadiumNeonGreen.withOpacity(0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasLive ? 'LIVE & RECENT MATCHES' : 'SCORES & MATCH TICKER',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: hasLive
                            ? AppColors.stadiumNeonGreen
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Hover or tap to view',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              EdgeFadeMarquee(
                height: 42.0,
                pixelsPerSecond: 30.0,
                edgeFadeWidth: 48.0,
                spacing: 12.0,
                children: items,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MatchTickerCard extends StatelessWidget {
  final TickerMatchItem match;
  final bool isDark;

  const _MatchTickerCard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;

    // Green glow container for live matches
    final cardBg = isLive
        ? (isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF0F172A).withOpacity(0.85) : Colors.white);

    final borderColor = isLive
        ? AppColors.stadiumNeonGreen
        : (isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0));

    final timeStr = DateFormat('h:mm a').format(match.kickoffTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/match/${match.id}');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isLive ? 1.6 : 1),
            boxShadow: [
              BoxShadow(
                color: isLive
                    ? AppColors.stadiumNeonGreen.withOpacity(0.35)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isLive ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // League / Live Indicator Badge
              if (isLive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.stadiumNeonGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.stadiumNeonGreen.withOpacity(0.8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.stadiumNeonGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.liveMinute != null ? "${match.liveMinute}'" : 'LIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.stadiumNeonGreen : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (match.leagueName.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    match.leagueName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Home team
              Text(
                match.homeTeam,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLive
                      ? (isDark ? Colors.white : const Color(0xFF14532D))
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 6),

              // Score or Kickoff Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.stadiumNeonGreen.withOpacity(0.25)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLive || isFinished
                      ? '${match.homeScore ?? 0} - ${match.awayScore ?? 0}'
                      : timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isLive
                        ? (isDark ? AppColors.stadiumNeonGreen : const Color(0xFF15803D))
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Away team
              Text(
                match.awayTeam,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLive
                      ? (isDark ? Colors.white : const Color(0xFF14532D))
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),

              if (isFinished) ...[
                const SizedBox(width: 6),
                Text(
                  'FT',
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
