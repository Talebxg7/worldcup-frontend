class Competition {
  final String name;
  final String subtitle;
  final int leagueId;
  final String emoji;
  final bool isEnabled;
  final String? imagePath;

  const Competition({
    required this.name,
    required this.subtitle,
    required this.leagueId,
    required this.emoji,
    required this.isEnabled,
    this.imagePath,
  });

  String get leagueLogoUrl =>
      'https://media.api-sports.io/football/leagues/$leagueId.png';
}

