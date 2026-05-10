import '../../../../services/football_api_service.dart';
import '../models/dashboard_prediction_model.dart';

/// Enriches stored rows with live API status, scores, and simple points.
class PredictionDashboardService {
  static const _liveStatuses = {
    '1H',
    '2H',
    'HT',
    'ET',
    'BT',
    'P',
    'LIVE',
    'INT',
  };

  static const _finishedStatuses = {
    'FT',
    'AET',
    'PEN',
    'AWD',
    'WO',
  };

  Future<DashboardPredictionModel> enrichOne(DashboardPredictionModel row) async {
    try {
      final id = int.tryParse(row.fixtureId);
      if (id == null) return row;
      final f = await FootballApiService.getFixtureById(id);
      if (f == null) return row;

      final st = (f.status ?? '').toUpperCase();
      final now = DateTime.now();
      final kickoff = row.kickoff;

      String matchStatus;
      if (_finishedStatuses.contains(st)) {
        matchStatus = 'FINISHED';
      } else if (_liveStatuses.contains(st) || st == 'INPLAY') {
        matchStatus = 'LIVE';
      } else if (kickoff.isAfter(now)) {
        matchStatus = 'UPCOMING';
      } else {
        // Kickoff passed but not FT
        if (st == 'NS' || st == 'TBD') {
           if (kickoff.isBefore(now.subtract(const Duration(hours: 4)))) {
               matchStatus = 'FINISHED';
           } else {
               matchStatus = 'LIVE';
           }
        } else {
           matchStatus = 'LIVE';
        }
      }

      final ah = f.homeGoals;
      final aw = f.awayGoals;
      int? points;
      if (matchStatus == 'FINISHED' && ah != null && aw != null) {
        points = _computePoints(row, ah, aw);
      }

      return DashboardPredictionModel(
        fixtureId: row.fixtureId,
        leagueId: row.leagueId,
        leagueName: row.leagueName,
        homeTeam: row.homeTeam,
        awayTeam: row.awayTeam,
        homeLogo: row.homeLogo,
        awayLogo: row.awayLogo,
        homeTeamId: row.homeTeamId,
        awayTeamId: row.awayTeamId,
        kickoffIso: row.kickoffIso,
        homeScore: row.homeScore,
        awayScore: row.awayScore,
        predictedWinner: row.predictedWinner,
        jokerUsed: row.jokerUsed,
        matchStatus: matchStatus,
        pointsEarned: matchStatus == 'FINISHED' ? points : null,
        actualHomeGoals: ah,
        actualAwayGoals: aw,
        savedAtIso: row.savedAtIso,
      );
    } catch (_) {
      return row;
    }
  }

  Future<List<DashboardPredictionModel>> enrichAll(
    List<DashboardPredictionModel> rows,
  ) async {
    final out = <DashboardPredictionModel>[];
    for (final r in rows) {
      out.add(await enrichOne(r));
    }
    return out;
  }

  int _computePoints(DashboardPredictionModel p, int ah, int aw) {
    // New rules:
    // +2 for correct home score
    // +2 for correct away score
    // +2 for correct winner (HOME/DRAW/AWAY)
    // Joker ×2 applies to the exact-score block only.
    var base = 0;
    if (p.homeScore == ah) base += 2;
    if (p.awayScore == aw) base += 2;
    final exactScoreBlock = p.jokerUsed ? base * 2 : base;
    final winnerPoints = _winnerCode(ah, aw) == p.predictedWinner.toUpperCase() ? 2 : 0;
    return exactScoreBlock + winnerPoints;
  }

  String _winnerCode(int home, int away) {
    if (home == away) return 'DRAW';
    return home > away ? 'HOME' : 'AWAY';
  }

  /// Count finished predictions with any positive points.
  int countCorrectWinners(List<DashboardPredictionModel> rows) {
    var n = 0;
    for (final p in rows) {
      if (p.matchStatus != 'FINISHED') continue;
      final ah = p.actualHomeGoals;
      final aw = p.actualAwayGoals;
      if (ah == null || aw == null) continue;
      if ((p.pointsEarned ?? 0) > 0) n++;
    }
    return n;
  }

  int countExactScores(List<DashboardPredictionModel> rows) {
    var n = 0;
    for (final p in rows) {
      if (p.matchStatus != 'FINISHED') continue;
      final ah = p.actualHomeGoals;
      final aw = p.actualAwayGoals;
      if (ah == null || aw == null) continue;
      if (p.homeScore == ah && p.awayScore == aw) n++;
    }
    return n;
  }

  int weeklyPoints(List<DashboardPredictionModel> rows) {
    final start = _weekStart(DateTime.now());
    var sum = 0;
    for (final p in rows) {
      if (p.savedAt.isBefore(start)) continue;
      sum += p.pointsEarned ?? 0;
    }
    return sum;
  }

  int weeklyPredictedCount(List<DashboardPredictionModel> rows) {
    final start = _weekStart(DateTime.now());
    return rows.where((p) => !p.savedAt.isBefore(start)).length;
  }

  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
