import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/edge_fade_marquee.dart';
import '../../../matches/data/models/match_model.dart';
import '../../../matches/presentation/providers/matches_provider.dart';

class LiveFixturesMarquee extends ConsumerWidget {
  const LiveFixturesMarquee({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();

        // Sort: Live matches first, then upcoming matches, then finished
        final sorted = List<MatchModel>.from(matches)
          ..sort((a, b) {
            final aLive = a.status == MatchStatus.live;
            final bLive = b.status == MatchStatus.live;
            if (aLive && !bLive) return -1;
            if (!aLive && bLive) return 1;
            return a.kickoffTime.compareTo(b.kickoffTime);
          });

        final tickerMatches = sorted.take(12).toList();
        if (tickerMatches.isEmpty) return const SizedBox.shrink();

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
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.stadiumNeonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MATCH TICKER',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                pixelsPerSecond: 32.0,
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
  final MatchModel match;
  final bool isDark;

  const _MatchTickerCard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.finished;

    final cardBg = isDark
        ? const Color(0xFF0F172A).withOpacity(0.85)
        : Colors.white;
    final borderColor = isLive
        ? AppColors.stadiumNeonGreen.withOpacity(0.5)
        : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0));

    final timeStr = DateFormat('h:mm a').format(match.kickoffTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/matches/${match.id}');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isLive ? 1.4 : 1),
            boxShadow: [
              BoxShadow(
                color: isLive
                    ? AppColors.stadiumNeonGreen.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // League / Live Indicator
              if (isLive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.liveMinute != null ? "${match.liveMinute}'" : 'LIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (match.stage.isNotEmpty) ...[
                Text(
                  match.stage.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),

              // Score or Kickoff Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLive || isFinished
                      ? '${match.homeScore ?? 0} - ${match.awayScore ?? 0}'
                      : timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isLive
                        ? AppColors.stadiumNeonGreen
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
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
