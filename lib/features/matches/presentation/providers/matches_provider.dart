import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/match_model.dart';
import '../../../../core/demo/demo_mode_provider.dart';
import '../../../../services/football_api_service.dart';

final matchesProvider = AsyncNotifierProvider<MatchesNotifier, List<MatchModel>>(
  MatchesNotifier.new,
);

final matchByIdProvider = FutureProvider.family<MatchModel, String>((ref, id) async {
  final matchId = int.tryParse(id);
  final all = await ref.watch(matchesProvider.future);
  if (matchId == null) return all.first;
  return all.firstWhere(
    (m) => m.id == matchId,
    orElse: () => all.first,
  );
});

final matchFilterProvider = StateProvider<String>((ref) => 'all'); // all, upcoming, finished

/// Selected competition/league name (we use MatchModel.stage as the category label).
/// Use 'All' to disable filtering.
final competitionFilterProvider = StateProvider<String>((ref) => 'All');

class MatchesNotifier extends AsyncNotifier<List<MatchModel>> {
  @override
  Future<List<MatchModel>> build() async {
    return _fetchMatches();
  }

  Future<List<MatchModel>> _fetchMatches() async {
    final isDemo = ref.read(demoModeProvider);
    if (isDemo) return _demoMatches();

    final localPredictions = await _readLocalPredictions();
    final requests = _trackedLeagues.map((l) async {
      try {
        final fixtures = await FootballApiService.getFixtures(
          league: l.leagueId,
          season: l.season,
        );
        return fixtures.map((f) => _toMatchModel(f, l, localPredictions)).toList();
      } catch (e) {
        print('Error fetching league ${l.title}: $e');
        return <MatchModel>[];
      }
    }).toList();

    final groups = await Future.wait(requests);
    final all = groups.expand((e) => e).toList()
      ..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));
    return all;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchMatches);
  }

  Future<void> savePrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localPredictionsKey);
    final data = _decodePredictions(raw);
    data['$matchId'] = {
      'home_score': homeScore,
      'away_score': awayScore,
      'submitted_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_localPredictionsKey, _encodePredictions(data));
    ref.invalidateSelf();
  }
}

const _localPredictionsKey = 'api_football_local_predictions';

class _TrackedLeague {
  final int leagueId;
  final int season;
  final String title;
  final String countryCode;

  const _TrackedLeague({
    required this.leagueId,
    required this.season,
    required this.title,
    required this.countryCode,
  });
}

const _trackedLeagues = [
  _TrackedLeague(leagueId: 39, season: 2024, title: 'Premier League', countryCode: 'gb'),
  _TrackedLeague(leagueId: 140, season: 2024, title: 'La Liga', countryCode: 'es'),
  _TrackedLeague(leagueId: 135, season: 2024, title: 'Serie A', countryCode: 'it'),
  _TrackedLeague(leagueId: 78, season: 2024, title: 'Bundesliga', countryCode: 'de'),
  _TrackedLeague(leagueId: 94, season: 2024, title: 'Primeira Liga', countryCode: 'pt'),
  _TrackedLeague(leagueId: 233, season: 2024, title: 'Egyptian Premier League', countryCode: 'eg'),
  _TrackedLeague(leagueId: 307, season: 2024, title: 'Saudi Pro League', countryCode: 'sa'),
  _TrackedLeague(leagueId: 269, season: 2024, title: 'Qatar Stars League', countryCode: 'qa'),
  _TrackedLeague(leagueId: 387, season: 2025, title: 'Jordanian Pro League', countryCode: 'jo'),
];

Map<String, Map<String, dynamic>> _decodePredictions(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = raw;
    final map = Map<String, dynamic>.from(const JsonDecoder().convert(decoded) as Map);
    return map.map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  } catch (_) {
    return {};
  }
}

String _encodePredictions(Map<String, Map<String, dynamic>> data) {
  return const JsonEncoder().convert(data);
}

Future<Map<String, Map<String, dynamic>>> _readLocalPredictions() async {
  final prefs = await SharedPreferences.getInstance();
  return _decodePredictions(prefs.getString(_localPredictionsKey));
}

PredictionModel? _predictionFor(
  int matchId,
  Map<String, Map<String, dynamic>> saved,
  int? homeGoals,
  int? awayGoals,
) {
  final item = saved['$matchId'];
  if (item == null) return null;
  final home = (item['home_score'] as num?)?.toInt();
  final away = (item['away_score'] as num?)?.toInt();
  if (home == null || away == null) return null;

  int? points;
  if (homeGoals != null && awayGoals != null) {
    if (home == homeGoals && away == awayGoals) {
      points = 3;
    } else {
      final actual = homeGoals == awayGoals ? 'D' : (homeGoals > awayGoals ? 'H' : 'A');
      final predicted = home == away ? 'D' : (home > away ? 'H' : 'A');
      points = actual == predicted ? 1 : 0;
    }
  }

  return PredictionModel(
    id: -matchId,
    matchId: matchId,
    userId: 0,
    homeScore: home,
    awayScore: away,
    pointsEarned: points,
    submittedAt: DateTime.tryParse(item['submitted_at'] as String? ?? '') ?? DateTime.now(),
  );
}

MatchStatus _statusFromApi(String? short) {
  const liveShort = {
    '1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE', 'INT',
  };
  const finishedShort = {'FT', 'AET', 'PEN', 'CANC', 'PST', 'ABD', 'AWD', 'WO'};

  if (short == null) return MatchStatus.upcoming;
  if (liveShort.contains(short)) return MatchStatus.live;
  if (finishedShort.contains(short)) return MatchStatus.finished;
  return MatchStatus.upcoming;
}

MatchModel _toMatchModel(
  FixtureModel fixture,
  _TrackedLeague league,
  Map<String, Map<String, dynamic>> localPredictions,
) {
  final status = _statusFromApi(fixture.status);
  final prediction = _predictionFor(
    fixture.id,
    localPredictions,
    fixture.homeGoals,
    fixture.awayGoals,
  );

  return MatchModel(
    id: fixture.id,
    homeTeam: fixture.homeTeam,
    awayTeam: fixture.awayTeam,
    homeTeamFlag: league.countryCode,
    awayTeamFlag: league.countryCode,
    venue: fixture.venueName ?? '',
    city: fixture.venueCity ?? '',
    country: league.countryCode.toUpperCase(),
    kickoffTime: fixture.date ?? DateTime.now(),
    stage: fixture.leagueName ?? league.title,
    group: null,
    status: status,
    liveMinute: fixture.minute,
    homeScore: fixture.homeGoals,
    awayScore: fixture.awayGoals,
    totalPredictions: 0,
    myPrediction: prediction,
  );
}

List<MatchModel> _demoMatches() {
  final now = DateTime.now();
  return [
    // World Cup
    MatchModel(
      id: 1,
      homeTeam: 'USA',
      awayTeam: 'Mexico',
      homeTeamFlag: 'us',
      awayTeamFlag: 'mx',
      venue: 'MetLife Stadium',
      city: 'New York',
      country: 'USA',
      kickoffTime: now.add(const Duration(days: 2, hours: 3)),
      stage: 'World Cup 2026',
      group: 'A',
      status: MatchStatus.upcoming,
      totalPredictions: 128,
      myPrediction: null,
    ),
    MatchModel(
      id: 2,
      homeTeam: 'Argentina',
      awayTeam: 'France',
      homeTeamFlag: 'ar',
      awayTeamFlag: 'fr',
      venue: 'SoFi Stadium',
      city: 'Los Angeles',
      country: 'USA',
      kickoffTime: now.add(const Duration(days: 5, hours: 6)),
      stage: 'World Cup 2026',
      group: 'B',
      status: MatchStatus.upcoming,
      totalPredictions: 302,
      myPrediction: PredictionModel(
        id: 1,
        matchId: 2,
        userId: 0,
        homeScore: 2,
        awayScore: 1,
        pointsEarned: null,
        submittedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ),
    MatchModel(
      id: 3,
      homeTeam: 'Brazil',
      awayTeam: 'Germany',
      homeTeamFlag: 'br',
      awayTeamFlag: 'de',
      venue: 'AT&T Stadium',
      city: 'Dallas',
      country: 'USA',
      kickoffTime: now.subtract(const Duration(days: 1)),
      stage: 'World Cup 2026',
      group: 'C',
      status: MatchStatus.finished,
      homeScore: 1,
      awayScore: 1,
      totalPredictions: 411,
      myPrediction: PredictionModel(
        id: 2,
        matchId: 3,
        userId: 0,
        homeScore: 1,
        awayScore: 1,
        pointsEarned: 3,
        submittedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ),
    // League samples
    MatchModel(
      id: 4,
      homeTeam: 'Real Madrid',
      awayTeam: 'Barcelona',
      homeTeamFlag: 'es',
      awayTeamFlag: 'es',
      venue: 'Santiago Bernabéu',
      city: 'Madrid',
      country: 'Spain',
      kickoffTime: now.add(const Duration(days: 3, hours: 2)),
      stage: 'La Liga',
      group: null,
      status: MatchStatus.upcoming,
      totalPredictions: 520,
      myPrediction: null,
    ),
    MatchModel(
      id: 5,
      homeTeam: 'Manchester City',
      awayTeam: 'Liverpool',
      homeTeamFlag: 'gb',
      awayTeamFlag: 'gb',
      venue: 'Etihad Stadium',
      city: 'Manchester',
      country: 'England',
      kickoffTime: now.add(const Duration(days: 1, hours: 5)),
      stage: 'Premier League',
      group: null,
      status: MatchStatus.upcoming,
      totalPredictions: 610,
      myPrediction: null,
    ),
    MatchModel(
      id: 6,
      homeTeam: 'Inter',
      awayTeam: 'Juventus',
      homeTeamFlag: 'it',
      awayTeamFlag: 'it',
      venue: 'San Siro',
      city: 'Milan',
      country: 'Italy',
      kickoffTime: now.subtract(const Duration(days: 2)),
      stage: 'Serie A',
      group: null,
      status: MatchStatus.finished,
      homeScore: 2,
      awayScore: 2,
      totalPredictions: 430,
      myPrediction: null,
    ),
  ];
}
