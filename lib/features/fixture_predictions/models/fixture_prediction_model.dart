enum PredictedWinner { home, draw, away }

class FixturePredictionModel {
  final int fixtureId;

  final int? homeScore;
  final int? awayScore;
  final PredictedWinner winner;

  final bool jokerUsed;

  final bool redCardYesNo;

  final bool penaltyYesNo;

  const FixturePredictionModel({
    required this.fixtureId,
    this.homeScore,
    this.awayScore,
    required this.winner,
    required this.jokerUsed,
    required this.redCardYesNo,
    required this.penaltyYesNo,
  });

  factory FixturePredictionModel.initial(int fixtureId) {
    return FixturePredictionModel(
      fixtureId: fixtureId,
      homeScore: null,
      awayScore: null,
      winner: PredictedWinner.draw,
      jokerUsed: false,
      redCardYesNo: false,
      penaltyYesNo: false,
    );
  }

  FixturePredictionModel copyWith({
    int? homeScore,
    int? awayScore,
    PredictedWinner? winner,
    bool? jokerUsed,
    bool? redCardYesNo,
    bool? penaltyYesNo,
  }) {
    return FixturePredictionModel(
      fixtureId: fixtureId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      winner: winner ?? this.winner,
      jokerUsed: jokerUsed ?? this.jokerUsed,
      redCardYesNo: redCardYesNo ?? this.redCardYesNo,
      penaltyYesNo: penaltyYesNo ?? this.penaltyYesNo,
    );
  }

  /// Copies but allows explicitly setting homeScore/awayScore to null if needed
  FixturePredictionModel copyWithNullableScores({
    int? homeScore,
    int? awayScore,
  }) {
    return FixturePredictionModel(
      fixtureId: fixtureId,
      homeScore: homeScore,
      awayScore: awayScore,
      winner: winner,
      jokerUsed: jokerUsed,
      redCardYesNo: redCardYesNo,
      penaltyYesNo: penaltyYesNo,
    );
  }

  static PredictedWinner winnerFromScore(int home, int away) {
    if (home == away) return PredictedWinner.draw;
    return home > away ? PredictedWinner.home : PredictedWinner.away;
  }

  Map<String, dynamic> toJson() => {
        'fixtureId': fixtureId,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'winner': winner.name,
        'jokerUsed': jokerUsed,
        'redCardYesNo': redCardYesNo,
        'penaltyYesNo': penaltyYesNo,
      };

  factory FixturePredictionModel.fromJson(Map<String, dynamic> json) {
    final w = (json['winner'] as String?) ?? PredictedWinner.draw.name;
    final parsedWinner = PredictedWinner.values.firstWhere(
      (e) => e.name == w,
      orElse: () => PredictedWinner.draw,
    );

    return FixturePredictionModel(
      fixtureId: (json['fixtureId'] as num?)?.toInt() ?? 0,
      homeScore: (json['homeScore'] as num?)?.toInt(),
      awayScore: (json['awayScore'] as num?)?.toInt(),
      winner: parsedWinner,
      jokerUsed: (json['jokerUsed'] as bool?) ?? false,
      redCardYesNo: (json['redCardYesNo'] as bool?) ?? false,
      penaltyYesNo: (json['penaltyYesNo'] as bool?) ?? false,
    );
  }

}

