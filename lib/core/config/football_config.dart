class FootballConfig {
  // EPL by default. You can later make this user-selectable.
  static const int defaultLeagueId = 39;

  // API-FOOTBALL seasons are typically the starting year of the season.
  // Example: 2025 season corresponds to 2025/2026.
  static int currentSeason() {
    final now = DateTime.now();
    if (now.month >= 7) {
      return now.year;
    }
    return now.year - 1;
  }
}

