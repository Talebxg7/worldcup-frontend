import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/match_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/demo/demo_mode_provider.dart';
import '../../../../services/football_api_service.dart';
import '../../../competitions/presentation/widgets/live_fixtures_marquee.dart';

final matchesProvider = AsyncNotifierProvider<MatchesNotifier, List<MatchModel>>(
  MatchesNotifier.new,
);

final matchByIdProvider = FutureProvider.family<MatchModel, String>((ref, id) async {
  final matchId = int.tryParse(id);
  if (matchId != null) {
    // 1. Check ticker match cache
    try {
      final tickerAsync = ref.read(tickerMatchesProvider);
      final tickerList = tickerAsync.value ?? [];
      final matchInTicker = tickerList.where((m) => m.id == matchId);
      if (matchInTicker.isNotEmpty) {
        final t = matchInTicker.first;
        return MatchModel(
          id: t.id,
          homeTeam: t.homeTeam,
          awayTeam: t.awayTeam,
          homeTeamFlag: t.homeLogo ?? '',
          awayTeamFlag: t.awayLogo ?? '',
          venue: 'Stadium',
          city: '',
          country: '',
          kickoffTime: t.kickoffTime,
          stage: t.leagueName,
          group: null,
          status: t.isLive ? MatchStatus.live : (t.isFinished ? MatchStatus.finished : MatchStatus.upcoming),
          liveMinute: t.liveMinute,
          homeScore: t.homeScore,
          awayScore: t.awayScore,
          totalPredictions: 0,
          myPrediction: null,
        );
      }
    } catch (_) {}

    // 2. Check API
    try {
      final response = await ApiClient.instance.get('/matches/$id');
      if (response.data is Map<String, dynamic>) {
        return MatchModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}

    try {
      final response = await ApiClient.instance.get('/matches');
      if (response.data is List) {
        final list = (response.data as List)
            .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final found = list.where((m) => m.id == matchId);
        if (found.isNotEmpty) return found.first;
      }
    } catch (_) {}
  }

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
          status: 'NS',
        );
        return fixtures.map((f) => _fixtureToMatch(f, l, localPredictions[f.id])).toList();
      } catch (e) {
        return <MatchModel>[];
      }
    });

    final results = await Future.wait(requests);
    final allMatches = results.expand((x) => x).toList();

    if (allMatches.isEmpty) {
      return _demoMatches();
    }

    allMatches.sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));
    return allMatches;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMatches());
  }

  Future<void> savePrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    final current = state.value ?? [];
    final prediction = PredictionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      matchId: matchId,
      userId: 0,
      homeScore: homeScore,
      awayScore: awayScore,
      pointsEarned: null,
      submittedAt: DateTime.now(),
    );

    await _saveLocalPrediction(matchId, prediction);

    state = AsyncValue.data(
      current.map((m) {
        if (m.id == matchId) {
          return m.copyWith(
            myPrediction: prediction,
            totalPredictions: m.totalPredictions + (m.myPrediction == null ? 1 : 0),
          );
        }
        return m;
      }).toList(),
    );
  }

  static const _storageKey = 'local_predictions_v1';

  Future<Map<int, PredictionModel>> _readLocalPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(
          int.parse(k),
          PredictionModel.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalPrediction(int matchId, PredictionModel p) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readLocalPredictions();
    map[matchId] = p;
    await prefs.setString(
      _storageKey,
      jsonEncode(map.map((k, v) => MapEntry(k.toString(), v.toJson()))),
    );
  }
}

class _TrackedLeagueConfig {
  final int leagueId;
  final int season;
  final String title;
  final String countryCode;

  const _TrackedLeagueConfig({
    required this.leagueId,
    required this.season,
    required this.title,
    required this.countryCode,
  });
}

const _trackedLeagues = [
  _TrackedLeagueConfig(
    leagueId: 39,
    season: 2024,
    title: 'Premier League',
    countryCode: 'gb',
  ),
  _TrackedLeagueConfig(
    leagueId: 140,
    season: 2024,
    title: 'La Liga',
    countryCode: 'es',
  ),
  _TrackedLeagueConfig(
    leagueId: 135,
    season: 2024,
    title: 'Serie A',
    countryCode: 'it',
  ),
  _TrackedLeagueConfig(
    leagueId: 78,
    season: 2024,
    title: 'Bundesliga',
    countryCode: 'de',
  ),
];

MatchModel _fixtureToMatch(
  FixtureModel fixture,
  _TrackedLeagueConfig league,
  PredictionModel? prediction,
) {
  MatchStatus status = MatchStatus.upcoming;
  final s = fixture.status?.toUpperCase() ?? 'NS';
  if (s == 'FT' || s == 'AET' || s == 'PEN') {
    status = MatchStatus.finished;
  } else if (s == '1H' || s == '2H' || s == 'HT' || s == 'ET' || s == 'P' || s == 'LIVE') {
    status = MatchStatus.live;
  }

  return MatchModel(
    id: fixture.id,
    homeTeam: fixture.homeTeam,
    awayTeam: fixture.awayTeam,
    homeTeamFlag: league.countryCode,
    awayTeamFlag: league.countryCode,
    venue: fixture.venueName ?? 'Stadium',
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
  ];
}
