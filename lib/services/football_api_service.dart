import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FootballApiService {
  static const String baseUrl = 'https://v3.football.api-sports.io/';

  static Map<String, String> _headers() {
    return {
      'content-type': 'application/json',
    };
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final innerUrl = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    // Always use our secure backend proxy to protect API keys from extraction
    return Uri.parse('https://whowillwin-api.onrender.com/api/proxy/football?url=${Uri.encodeComponent(innerUrl.toString())}');
  }

  static Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final response = await http.get(
        _uri(path, query),
        headers: _headers(),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception(
          'API request failed (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Check for API-Sports errors structure (e.g. suspended account)
      if (data['errors'] != null) {
        final errs = data['errors'];
        if (errs is Map && errs.isNotEmpty) {
          throw Exception('API-Sports Error: ${errs.values.first}');
        } else if (errs is List && errs.isNotEmpty) {
          throw Exception('API-Sports Error: ${errs.first}');
        }
      }

      return data;
    } catch (e) {
      debugPrint('FootballApiService: API request to $path failed, falling back to mock. Error: $e');
      return _getMockJson(path, query);
    }
  }

  /// 1) GET /leagues
  static Future<List<LeagueModel>> getLeagues() async {
    final json = await _getJson('leagues');
    final list = (json['response'] as List<dynamic>? ?? []);
    return list
        .map((e) => LeagueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 2) GET /fixtures?league=39&season=2024
  static Future<List<FixtureModel>> getFixtures({
    int? league,
    int? season,
    String? status,
    String? live,
  }) async {
    final query = <String, String>{};
    if (league != null) query['league'] = '$league';
    if (season != null) query['season'] = '$season';
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (live != null && live.isNotEmpty) query['live'] = live;

    final json = await _getJson(
      'fixtures',
      query: query,
    );
    final list = (json['response'] as List<dynamic>? ?? []);
    return list
        .map((e) => FixtureModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lightweight helper for "upcoming count" badges.
  static Future<int> getUpcomingCount({
    required int league,
    required int season,
  }) async {
    final json = await _getJson(
      'fixtures',
      query: {
        'league': '$league',
        'season': '$season',
        'status': 'NS',
      },
    );
    return (json['results'] as num?)?.toInt() ??
        ((json['response'] as List?)?.length ?? 0);
  }

  /// 3) GET /standings?league=39&season=2024
  static Future<List<StandingModel>> getStandings({
    int league = 39,
    int season = 2024,
  }) async {
    final json = await _getJson(
      'standings',
      query: {
        'league': '$league',
        'season': '$season',
      },
    );

    final responseList = (json['response'] as List<dynamic>? ?? []);
    if (responseList.isEmpty) return [];

    final leagueObj = responseList.first as Map<String, dynamic>;
    final leagueData = leagueObj['league'] as Map<String, dynamic>? ?? {};
    final standingsNested = leagueData['standings'] as List<dynamic>? ?? [];
    if (standingsNested.isEmpty) return [];

    final table = standingsNested.first as List<dynamic>;
    return table
        .map((e) => StandingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Extra endpoint: /teams?league=39&season=2024
  static Future<List<TeamModel>> getTeams({
    int league = 39,
    int season = 2024,
  }) async {
    final json = await _getJson(
      'teams',
      query: {
        'league': '$league',
        'season': '$season',
      },
    );
    final list = (json['response'] as List<dynamic>? ?? []);
    return list
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Extra endpoint: /fixtures?id=12345
  static Future<FixtureModel?> getFixtureById(int fixtureId) async {
    final json = await _getJson(
      'fixtures',
      query: {'id': '$fixtureId'},
    );
    final list = (json['response'] as List<dynamic>? ?? []);
    if (list.isEmpty) return null;
    return FixtureModel.fromJson(list.first as Map<String, dynamic>);
  }

  /// Extra endpoint: /fixtures/lineups?fixture=12345
  static Future<List<LineupPlayerModel>> getLineupPlayers({
    required int fixtureId,
  }) async {
    final json = await _getJson(
      'fixtures/lineups',
      query: {'fixture': '$fixtureId'},
    );
    final list = (json['response'] as List<dynamic>? ?? []);
    final out = <LineupPlayerModel>[];

    for (final item in list) {
      final obj = item as Map<String, dynamic>;
      final team = obj['team'] as Map<String, dynamic>? ?? {};
      final teamId = (team['id'] as num?)?.toInt();
      // API-FOOTBALL can vary slightly in key casing/structure; be defensive.
      final startXI = _asMapList(
        obj['startXI'] ??
            obj['startxi'] ??
            obj['lineups'] ??
            obj['lineup'] ??
            obj['Lineups'] ??
            obj['StartXI'] ??
            obj['StartXIv2'],
      );
      final subs = _asMapList(
        obj['substitutes'] ?? obj['Substitutes'] ?? obj['bench'] ?? obj['Bench'],
      );
      final all = [...startXI, ...subs];

      for (final p in all) {
        if (p is! Map) continue;
        final pObj = p as Map<String, dynamic>;

        // Common shapes:
        // - { "player": {id,name} }
        // - { "player": { "id":..., "name":... } }
        // - { "id":..., "name":... }  (rare, but we handle)
        final player = pObj['player'];
        int? id;
        String? name;

        if (player is Map) {
          final pm = player as Map<String, dynamic>;
          id = (pm['id'] as num?)?.toInt();
          name = pm['name'] as String?;
        } else {
          id = (pObj['id'] as num?)?.toInt();
          name = pObj['name'] as String?;
        }
        if (id == null || name == null) continue;
        out.add(
          LineupPlayerModel(
            id: id,
            name: name,
            teamId: teamId,
          ),
        );
      }
    }

    // De-dup by id, keep stable order.
    final seen = <int>{};
    final dedup = <LineupPlayerModel>[];
    for (final p in out) {
      if (seen.add(p.id)) dedup.add(p);
    }
    return dedup;
  }

  /// Extra endpoint: /fixtures/statistics?fixture=12345
  static Future<List<FixtureStatisticsModel>> getFixtureStatistics({
    required int fixtureId,
  }) async {
    final json = await _getJson(
      'fixtures/statistics',
      query: {'fixture': '$fixtureId'},
    );
    final list = (json['response'] as List<dynamic>? ?? []);
    return list
        .map((e) => FixtureStatisticsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Extra endpoint: /fixtures/events?fixture=12345
  static Future<List<FixtureEventModel>> getFixtureEvents({
    required int fixtureId,
  }) async {
    final json = await _getJson(
      'fixtures/events',
      query: {'fixture': '$fixtureId'},
    );
    final list = (json['response'] as List<dynamic>? ?? []);
    return list
        .map((e) => FixtureEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _getMockJson(String path, Map<String, String>? query) {
    final now = DateTime.now();
    
    if (path == 'leagues') {
      return {
        "response": [
          {
            "league": {"id": 39, "name": "Premier League", "type": "League", "logo": "https://media.api-sports.io/football/leagues/39.png"},
            "country": {"name": "England"}
          },
          {
            "league": {"id": 140, "name": "La Liga", "type": "League", "logo": "https://media.api-sports.io/football/leagues/140.png"},
            "country": {"name": "Spain"}
          },
          {
            "league": {"id": 135, "name": "Serie A", "type": "League", "logo": "https://media.api-sports.io/football/leagues/135.png"},
            "country": {"name": "Italy"}
          },
          {
            "league": {"id": 78, "name": "Bundesliga", "type": "League", "logo": "https://media.api-sports.io/football/leagues/78.png"},
            "country": {"name": "Germany"}
          }
        ]
      };
    } else if (path == 'standings') {
      final leagueId = int.tryParse(query?['league'] ?? '39') ?? 39;
      final leagueName = leagueId == 140
          ? 'La Liga'
          : leagueId == 135
              ? 'Serie A'
              : leagueId == 78
                  ? 'Bundesliga'
                  : 'Premier League';
      
      final teams = leagueId == 140 
        ? [
            {"rank": 1, "team": {"name": "Real Madrid"}, "points": 95, "all": {"played": 38, "win": 30, "draw": 5, "lose": 3}},
            {"rank": 2, "team": {"name": "Barcelona"}, "points": 85, "all": {"played": 38, "win": 26, "draw": 7, "lose": 5}},
            {"rank": 3, "team": {"name": "Girona"}, "points": 81, "all": {"played": 38, "win": 25, "draw": 6, "lose": 7}},
            {"rank": 4, "team": {"name": "Atletico Madrid"}, "points": 76, "all": {"played": 38, "win": 24, "draw": 4, "lose": 10}},
          ]
        : leagueId == 135
          ? [
              {"rank": 1, "team": {"name": "Inter"}, "points": 94, "all": {"played": 38, "win": 29, "draw": 7, "lose": 2}},
              {"rank": 2, "team": {"name": "AC Milan"}, "points": 75, "all": {"played": 38, "win": 22, "draw": 9, "lose": 7}},
              {"rank": 3, "team": {"name": "Juventus"}, "points": 71, "all": {"played": 38, "win": 19, "draw": 14, "lose": 5}},
            ]
          : leagueId == 78
            ? [
                {"rank": 1, "team": {"name": "Bayer Leverkusen"}, "points": 90, "all": {"played": 34, "win": 28, "draw": 6, "lose": 0}},
                {"rank": 2, "team": {"name": "VfB Stuttgart"}, "points": 73, "all": {"played": 34, "win": 23, "draw": 4, "lose": 7}},
                {"rank": 3, "team": {"name": "Bayern Munich"}, "points": 72, "all": {"played": 34, "win": 23, "draw": 3, "lose": 8}},
              ]
            : [
                {"rank": 1, "team": {"name": "Arsenal"}, "points": 89, "all": {"played": 38, "win": 28, "draw": 5, "lose": 5}},
                {"rank": 2, "team": {"name": "Manchester City"}, "points": 88, "all": {"played": 38, "win": 27, "draw": 7, "lose": 4}},
                {"rank": 3, "team": {"name": "Liverpool"}, "points": 82, "all": {"played": 38, "win": 24, "draw": 10, "lose": 4}},
                {"rank": 4, "team": {"name": "Aston Villa"}, "points": 68, "all": {"played": 38, "win": 20, "draw": 8, "lose": 10}},
                {"rank": 5, "team": {"name": "Chelsea"}, "points": 63, "all": {"played": 38, "win": 18, "draw": 9, "lose": 11}},
              ];
      return {
        "response": [
          {
            "league": {
              "id": leagueId,
              "name": leagueName,
              "standings": [teams]
            }
          }
        ]
      };
    } else if (path == 'fixtures') {
      final leagueId = int.tryParse(query?['league'] ?? '39') ?? 39;
      final leagueName = leagueId == 140
          ? 'La Liga'
          : leagueId == 135
              ? 'Serie A'
              : leagueId == 78
                  ? 'Bundesliga'
                  : 'Premier League';
      
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));
      final nextWeek = now.add(const Duration(days: 4));

      return {
        "response": [
          {
            "fixture": {
              "id": leagueId * 1000 + 1,
              "date": yesterday.toIso8601String(),
              "status": {"short": "FT", "long": "Match Finished", "elapsed": 90}
            },
            "teams": {
              "home": {"name": "Arsenal", "logo": "https://media.api-sports.io/football/teams/42.png", "id": 42},
              "away": {"name": "Chelsea", "logo": "https://media.api-sports.io/football/teams/49.png", "id": 49}
            },
            "goals": {"home": 3, "away": 1},
            "league": {"name": leagueName, "id": leagueId}
          },
          {
            "fixture": {
              "id": leagueId * 1000 + 2,
              "date": now.toIso8601String(),
              "status": {"short": "2H", "long": "Second Half", "elapsed": 68}
            },
            "teams": {
              "home": {"name": "Manchester City", "logo": "https://media.api-sports.io/football/teams/50.png", "id": 50},
              "away": {"name": "Liverpool", "logo": "https://media.api-sports.io/football/teams/40.png", "id": 40}
            },
            "goals": {"home": 2, "away": 2},
            "league": {"name": leagueName, "id": leagueId}
          },
          {
            "fixture": {
              "id": leagueId * 1000 + 3,
              "date": tomorrow.toIso8601String(),
              "status": {"short": "NS", "long": "Not Started", "elapsed": 0}
            },
            "teams": {
              "home": {"name": "Manchester United", "logo": "https://media.api-sports.io/football/teams/33.png", "id": 33},
              "away": {"name": "Tottenham", "logo": "https://media.api-sports.io/football/teams/47.png", "id": 47}
            },
            "goals": {"home": null, "away": null},
            "league": {"name": leagueName, "id": leagueId}
          },
          {
            "fixture": {
              "id": leagueId * 1000 + 4,
              "date": nextWeek.toIso8601String(),
              "status": {"short": "NS", "long": "Not Started", "elapsed": 0}
            },
            "teams": {
              "home": {"name": "Aston Villa", "logo": "https://media.api-sports.io/football/teams/66.png", "id": 66},
              "away": {"name": "Newcastle", "logo": "https://media.api-sports.io/football/teams/34.png", "id": 34}
            },
            "goals": {"home": null, "away": null},
            "league": {"name": leagueName, "id": leagueId}
          }
        ]
      };
    }
    return {"response": []};
  }
}

List<dynamic> _asMapList(Object? v) {
  if (v is List) return v;
  if (v is Map) {
    // Sometimes APIs nest lists under keys.
    for (final entry in v.entries) {
      if (entry.value is List) return entry.value as List<dynamic>;
    }
  }
  return const [];
}

class LeagueModel {
  final int id;
  final String name;
  final String type;
  final String? logo;
  final String? countryName;

  const LeagueModel({
    required this.id,
    required this.name,
    required this.type,
    this.logo,
    this.countryName,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    final league = json['league'] as Map<String, dynamic>? ?? {};
    final country = json['country'] as Map<String, dynamic>? ?? {};
    return LeagueModel(
      id: (league['id'] as num?)?.toInt() ?? 0,
      name: (league['name'] as String?) ?? '',
      type: (league['type'] as String?) ?? '',
      logo: league['logo'] as String?,
      countryName: country['name'] as String?,
    );
  }
}

class FixtureModel {
  final int id;
  final DateTime? date;
  final String? status;
  final String? statusLong;
  final int? minute;
  final String? leagueName;
  final int? leagueId;
  final String? venueName;
  final String? venueCity;
  final int? homeTeamId;
  final int? awayTeamId;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeGoals;
  final int? awayGoals;

  const FixtureModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamId,
    this.awayTeamId,
    this.date,
    this.status,
    this.statusLong,
    this.minute,
    this.leagueName,
    this.leagueId,
    this.venueName,
    this.venueCity,
    this.homeLogo,
    this.awayLogo,
    this.homeGoals,
    this.awayGoals,
  });

  factory FixtureModel.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] as Map<String, dynamic>? ?? {};
    final teams = json['teams'] as Map<String, dynamic>? ?? {};
    final goals = json['goals'] as Map<String, dynamic>? ?? {};
    final league = json['league'] as Map<String, dynamic>? ?? {};
    final venue = fixture['venue'] as Map<String, dynamic>? ?? {};
    final home = teams['home'] as Map<String, dynamic>? ?? {};
    final away = teams['away'] as Map<String, dynamic>? ?? {};
    final statusObj = fixture['status'] as Map<String, dynamic>? ?? {};

    return FixtureModel(
      id: (fixture['id'] as num?)?.toInt() ?? 0,
      date: fixture['date'] != null
          ? DateTime.tryParse(fixture['date'] as String)
          : null,
      status: statusObj['short'] as String?,
      statusLong: statusObj['long'] as String?,
      minute: (statusObj['elapsed'] as num?)?.toInt(),
      leagueName: league['name'] as String?,
      leagueId: (league['id'] as num?)?.toInt(),
      venueName: venue['name'] as String?,
      venueCity: venue['city'] as String?,
      homeTeamId: (home['id'] as num?)?.toInt(),
      awayTeamId: (away['id'] as num?)?.toInt(),
      homeTeam: (home['name'] as String?) ?? '',
      awayTeam: (away['name'] as String?) ?? '',
      homeLogo: home['logo'] as String?,
      awayLogo: away['logo'] as String?,
      homeGoals: (goals['home'] as num?)?.toInt(),
      awayGoals: (goals['away'] as num?)?.toInt(),
    );
  }
}

class StandingModel {
  final int rank;
  final String teamName;
  final int points;
  final int played;
  final int win;
  final int draw;
  final int lose;

  const StandingModel({
    required this.rank,
    required this.teamName,
    required this.points,
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>? ?? {};
    final all = json['all'] as Map<String, dynamic>? ?? {};
    return StandingModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      teamName: (team['name'] as String?) ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      played: (all['played'] as num?)?.toInt() ?? 0,
      win: (all['win'] as num?)?.toInt() ?? 0,
      draw: (all['draw'] as num?)?.toInt() ?? 0,
      lose: (all['lose'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeamModel {
  final int id;
  final String name;
  final String? logo;
  final String? country;

  const TeamModel({
    required this.id,
    required this.name,
    this.logo,
    this.country,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>? ?? {};
    return TeamModel(
      id: (team['id'] as num?)?.toInt() ?? 0,
      name: (team['name'] as String?) ?? '',
      logo: team['logo'] as String?,
      country: team['country'] as String?,
    );
  }
}

class LineupPlayerModel {
  final int id;
  final String name;
  final int? teamId;

  const LineupPlayerModel({
    required this.id,
    required this.name,
    required this.teamId,
  });
}

class FixtureStatisticsModel {
  final int teamId;
  final String teamName;
  final int shotsTotal;
  final int shotsOnGoal;
  final int redCards;
  final int yellowCards;

  const FixtureStatisticsModel({
    required this.teamId,
    required this.teamName,
    required this.shotsTotal,
    required this.shotsOnGoal,
    required this.redCards,
    required this.yellowCards,
  });

  factory FixtureStatisticsModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>? ?? {};
    final stats = (json['statistics'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    int readInt(String key) {
      try {
        final obj = stats.firstWhere((s) => s['type'] == key);
        final v = obj['value'];
        if (v == null) return 0;
        if (v is num) return v.toInt();
        return int.tryParse('$v') ?? 0;
      } catch (_) {
        return 0;
      }
    }

    return FixtureStatisticsModel(
      teamId: (team['id'] as num?)?.toInt() ?? 0,
      teamName: (team['name'] as String?) ?? '',
      shotsTotal: readInt('Total Shots'),
      shotsOnGoal: readInt('Shots on Goal'),
      redCards: readInt('Red Cards'),
      yellowCards: readInt('Yellow Cards'),
    );
  }
}

class FixtureEventModel {
  final String type;
  final String detail;
  final String teamName;
  final String? playerName;
  final int? elapsedMinute;

  const FixtureEventModel({
    required this.type,
    required this.detail,
    required this.teamName,
    required this.playerName,
    required this.elapsedMinute,
  });

  factory FixtureEventModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>? ?? {};
    final player = json['player'] as Map<String, dynamic>? ?? {};
    final time = json['time'] as Map<String, dynamic>? ?? {};
    return FixtureEventModel(
      type: (json['type'] as String?) ?? '',
      detail: (json['detail'] as String?) ?? '',
      teamName: (team['name'] as String?) ?? '',
      playerName: player['name'] as String?,
      elapsedMinute: (time['elapsed'] as num?)?.toInt(),
    );
  }
}

