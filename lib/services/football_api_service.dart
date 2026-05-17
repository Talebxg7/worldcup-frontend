import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FootballApiService {
  static const String baseUrl = 'https://v3.football.api-sports.io/';

  static const String _apiKey = '408d9d10fc95b8c8b0c2f7c424b3bce9';

  static Map<String, String> _headers() {
    return {
      'x-apisports-key': _apiKey,
      'content-type': 'application/json',
    };
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    if (kIsWeb && !Uri.base.host.contains('localhost')) {
      // Use corsproxy to bypass CORS on GitHub Pages
      return Uri.parse('https://corsproxy.io/?https://v3.football.api-sports.io/$path').replace(queryParameters: query);
    }
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  static Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await http.get(
      _uri(path, query),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API request failed (${response.statusCode}): ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
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

  const FixtureStatisticsModel({
    required this.teamId,
    required this.teamName,
    required this.shotsTotal,
    required this.shotsOnGoal,
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

