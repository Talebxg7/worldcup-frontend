class Competition {
  final String name;
  final String subtitle;
  final int leagueId;
  final String emoji;
  final bool isEnabled;

  const Competition({
    required this.name,
    required this.subtitle,
    required this.leagueId,
    required this.emoji,
    required this.isEnabled,
  });

  String get leagueLogoUrl =>
      'https://media.api-sports.io/football/leagues/$leagueId.png';
}

