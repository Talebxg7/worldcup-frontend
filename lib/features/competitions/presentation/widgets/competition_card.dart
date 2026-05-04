import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/competition.dart';

class CompetitionCard extends StatelessWidget {
  final Competition competition;
  final int? upcomingCount;
  final bool isLoadingCount;
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  static const Map<int, String> _leagueBackgroundById = {
    39: 'assets/images/premier_league_bg.png',
    140: 'assets/images/la_liga_bg.png',
    135: 'assets/images/serie_a_bg.png',
    78: 'assets/images/bundesliga_bg.png',
    61: 'assets/images/ligue1_bg.png',
    233: 'assets/images/egyptian_league_bg.png',
    94: 'assets/images/primeira_liga_bg.png',
    1: 'assets/images/world_cup_bg.png',
    2: 'assets/images/uefa_champions_bg.png',
    3: 'assets/images/uefa_europa_bg.png',
    6: 'assets/images/afcon_bg.png',
    9: 'assets/images/copa_america_bg.png',
    307: 'assets/images/saudi_league_bg.png',
    305: 'assets/images/qatar_league_bg.png',
    387: 'assets/images/jordan_league_bg.jpg',
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
  Widget build(BuildContext context) {
    final disabled = !competition.isEnabled;
    final backgroundAsset = _leagueBackgroundById[competition.leagueId];
    final badgeText = isLoadingCount
        ? 'Loading...'
        : upcomingCount == null
            ? '—'
            : '$upcomingCount upcoming';

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
                        _LeagueLogo(url: competition.leagueLogoUrl),
                        const SizedBox(width: 10),
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
                      competition.name,
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
                      competition.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                        child: const Text(
                          'Coming soon',
                          style: TextStyle(
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

class _LeagueLogo extends StatelessWidget {
  final String url;
  const _LeagueLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 28,
          height: 28,
          color: Colors.white.withOpacity(0.2),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

