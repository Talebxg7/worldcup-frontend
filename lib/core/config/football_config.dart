class FootballConfig {
  // EPL by default. You can later make this user-selectable.
  static const int defaultLeagueId = 39;

  // API-FOOTBALL seasons are typically the starting year of the season.
  // Example: 2025 season corresponds to 2025/2026.
  static int currentSeason() => DateTime.now().year - 1;
}

