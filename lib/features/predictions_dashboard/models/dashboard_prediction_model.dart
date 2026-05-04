/// Dashboard row for a saved fixture prediction (local + optional Firestore later).
/// Named to avoid clashing with [PredictionModel] in `match_model.dart`.
class DashboardPredictionModel {
  final String fixtureId;
  final String leagueId;
  final String? leagueName;

  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeTeamId;
  final int? awayTeamId;
  final String kickoffIso;

  final int homeScore;
  final int awayScore;
  /// `HOME` | `DRAW` | `AWAY`
  final String predictedWinner;
  final bool jokerUsed;

  /// `UPCOMING` | `LIVE` | `FINISHED`
  final String matchStatus;

  final int? pointsEarned;
  final int? actualHomeGoals;
  final int? actualAwayGoals;

  /// When the user saved this prediction (for weekly progress).
  final String savedAtIso;

  const DashboardPredictionModel({
    required this.fixtureId,
    required this.leagueId,
    this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    this.homeTeamId,
    this.awayTeamId,
    required this.kickoffIso,
    required this.homeScore,
    required this.awayScore,
    required this.predictedWinner,
    required this.jokerUsed,
    required this.matchStatus,
    this.pointsEarned,
    this.actualHomeGoals,
    this.actualAwayGoals,
    required this.savedAtIso,
  });

  DateTime get kickoff => DateTime.tryParse(kickoffIso) ?? DateTime.now();
  DateTime get savedAt => DateTime.tryParse(savedAtIso) ?? DateTime.now();

  DashboardPredictionModel copyWith({
    String? matchStatus,
    int? pointsEarned,
    int? actualHomeGoals,
    int? actualAwayGoals,
  }) {
    return DashboardPredictionModel(
      fixtureId: fixtureId,
      leagueId: leagueId,
      leagueName: leagueName,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      kickoffIso: kickoffIso,
      homeScore: homeScore,
      awayScore: awayScore,
      predictedWinner: predictedWinner,
      jokerUsed: jokerUsed,
      matchStatus: matchStatus ?? this.matchStatus,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      actualHomeGoals: actualHomeGoals ?? this.actualHomeGoals,
      actualAwayGoals: actualAwayGoals ?? this.actualAwayGoals,
      savedAtIso: savedAtIso,
    );
  }

  /// Firestore: `users/{userId}/predictions/{fixtureId}`
  Map<String, dynamic> toFirestoreMap() => {
        'fixtureId': fixtureId,
        'leagueId': leagueId,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'winner': predictedWinner,
        'jokerUsed': jokerUsed,
        'pointsEarned': pointsEarned,
        'matchStatus': matchStatus,
        'leagueName': leagueName,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'kickoff': kickoffIso,
        'savedAt': savedAtIso,
      };

  Map<String, dynamic> toJson() => {
        ...toFirestoreMap(),
        'homeLogo': homeLogo,
        'awayLogo': awayLogo,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'actualHomeGoals': actualHomeGoals,
        'actualAwayGoals': actualAwayGoals,
      };

  factory DashboardPredictionModel.fromJson(Map<String, dynamic> json) {
    return DashboardPredictionModel(
      fixtureId: '${json['fixtureId'] ?? ''}',
      leagueId: '${json['leagueId'] ?? ''}',
      leagueName: json['leagueName'] as String?,
      homeTeam: (json['homeTeam'] as String?) ?? '',
      awayTeam: (json['awayTeam'] as String?) ?? '',
      homeLogo: json['homeLogo'] as String?,
      awayLogo: json['awayLogo'] as String?,
      homeTeamId: (json['homeTeamId'] as num?)?.toInt(),
      awayTeamId: (json['awayTeamId'] as num?)?.toInt(),
      kickoffIso: (json['kickoff'] as String?) ?? '',
      homeScore: (json['homeScore'] as num?)?.toInt() ?? 0,
      awayScore: (json['awayScore'] as num?)?.toInt() ?? 0,
      predictedWinner: (json['winner'] as String?) ?? 'DRAW',
      jokerUsed: (json['jokerUsed'] as bool?) ?? false,
      matchStatus: (json['matchStatus'] as String?) ?? 'UPCOMING',
      pointsEarned: (json['pointsEarned'] as num?)?.toInt(),
      actualHomeGoals: (json['actualHomeGoals'] as num?)?.toInt(),
      actualAwayGoals: (json['actualAwayGoals'] as num?)?.toInt(),
      savedAtIso: (json['savedAt'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }
}
