class WorldCupCountry {
  final String name;
  final String group;
  final String flag; // Flag emoji

  const WorldCupCountry({
    required this.name,
    required this.group,
    required this.flag,
  });
}

const List<WorldCupCountry> worldCupCountries = [
  // Group A
  WorldCupCountry(name: 'Mexico', group: 'A', flag: '🇲🇽'),
  WorldCupCountry(name: 'South Africa', group: 'A', flag: '🇿🇦'),
  WorldCupCountry(name: 'South Korea', group: 'A', flag: '🇰🇷'),
  WorldCupCountry(name: 'Czech Republic', group: 'A', flag: '🇨🇿'),

  // Group B
  WorldCupCountry(name: 'Canada', group: 'B', flag: '🇨🇦'),
  WorldCupCountry(name: 'Bosnia & Herzegovina', group: 'B', flag: '🇧🇦'),
  WorldCupCountry(name: 'Qatar', group: 'B', flag: '🇶🇦'),
  WorldCupCountry(name: 'Switzerland', group: 'B', flag: '🇨🇭'),

  // Group C
  WorldCupCountry(name: 'Brazil', group: 'C', flag: '🇧🇷'),
  WorldCupCountry(name: 'Morocco', group: 'C', flag: '🇲🇦'),
  WorldCupCountry(name: 'Haiti', group: 'C', flag: '🇭🇹'),
  WorldCupCountry(name: 'Scotland', group: 'C', flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿'),

  // Group D
  WorldCupCountry(name: 'USA', group: 'D', flag: '🇺🇸'),
  WorldCupCountry(name: 'Paraguay', group: 'D', flag: '🇵🇾'),
  WorldCupCountry(name: 'Australia', group: 'D', flag: '🇦🇺'),
  WorldCupCountry(name: 'Türkiye', group: 'D', flag: '🇹🇷'),

  // Group E
  WorldCupCountry(name: 'Germany', group: 'E', flag: '🇩🇪'),
  WorldCupCountry(name: 'Curaçao', group: 'E', flag: '🇨🇼'),
  WorldCupCountry(name: 'Ivory Coast', group: 'E', flag: '🇨🇮'),
  WorldCupCountry(name: 'Ecuador', group: 'E', flag: '🇪🇨'),

  // Group F
  WorldCupCountry(name: 'Netherlands', group: 'F', flag: '🇳🇱'),
  WorldCupCountry(name: 'Japan', group: 'F', flag: '🇯🇵'),
  WorldCupCountry(name: 'Sweden', group: 'F', flag: '🇸🇪'),
  WorldCupCountry(name: 'Tunisia', group: 'F', flag: '🇹🇳'),

  // Group G
  WorldCupCountry(name: 'Belgium', group: 'G', flag: '🇧🇪'),
  WorldCupCountry(name: 'Egypt', group: 'G', flag: '🇪🇬'),
  WorldCupCountry(name: 'Iran', group: 'G', flag: '🇮🇷'),
  WorldCupCountry(name: 'New Zealand', group: 'G', flag: '🇳🇿'),

  // Group H
  WorldCupCountry(name: 'Spain', group: 'H', flag: '🇪🇸'),
  WorldCupCountry(name: 'Cape Verde Islands', group: 'H', flag: '🇨🇻'),
  WorldCupCountry(name: 'Saudi Arabia', group: 'H', flag: '🇸🇦'),
  WorldCupCountry(name: 'Uruguay', group: 'H', flag: '🇺🇾'),

  // Group I
  WorldCupCountry(name: 'France', group: 'I', flag: '🇫🇷'),
  WorldCupCountry(name: 'Senegal', group: 'I', flag: '🇸🇳'),
  WorldCupCountry(name: 'Iraq', group: 'I', flag: '🇮🇶'),
  WorldCupCountry(name: 'Norway', group: 'I', flag: '🇳🇴'),

  // Group J
  WorldCupCountry(name: 'Argentina', group: 'J', flag: '🇦🇷'),
  WorldCupCountry(name: 'Algeria', group: 'J', flag: '🇩🇿'),
  WorldCupCountry(name: 'Austria', group: 'J', flag: '🇦🇹'),
  WorldCupCountry(name: 'Jordan', group: 'J', flag: '🇯🇴'),

  // Group K
  WorldCupCountry(name: 'Portugal', group: 'K', flag: '🇵🇹'),
  WorldCupCountry(name: 'Congo DR', group: 'K', flag: '🇨🇩'),
  WorldCupCountry(name: 'Uzbekistan', group: 'K', flag: '🇺🇿'),
  WorldCupCountry(name: 'Colombia', group: 'K', flag: '🇨🇴'),

  // Group L
  WorldCupCountry(name: 'England', group: 'L', flag: '🏴\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}'), // England flag emoji
  WorldCupCountry(name: 'Croatia', group: 'L', flag: '🇭🇷'),
  WorldCupCountry(name: 'Ghana', group: 'L', flag: '🇬🇭'),
  WorldCupCountry(name: 'Panama', group: 'L', flag: '🇵🇦'),
];

// Helper to get country by name
WorldCupCountry? getCountryByName(String name) {
  return worldCupCountries.firstWhere(
    (c) => c.name.toLowerCase() == name.toLowerCase(),
    orElse: () => WorldCupCountry(name: name, group: '?', flag: '🏳️'),
  );
}
