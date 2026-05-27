class WorldCupWinnerPredictionModel {
  final String predictedWinner;
  final double? pointsEarned;

  WorldCupWinnerPredictionModel({
    required this.predictedWinner,
    this.pointsEarned,
  });

  factory WorldCupWinnerPredictionModel.fromJson(Map<String, dynamic> json) {
    return WorldCupWinnerPredictionModel(
      predictedWinner: json['predictedWinner'] as String,
      pointsEarned: json['winnerPointsEarned'] != null
          ? double.tryParse(json['winnerPointsEarned'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predicted_winner_country': predictedWinner,
    };
  }
}

class WorldCupGroupPredictionModel {
  final String groupLetter;
  final List<String> predictedQualifiers;
  final double? pointsEarned;

  WorldCupGroupPredictionModel({
    required this.groupLetter,
    required this.predictedQualifiers,
    this.pointsEarned,
  });

  factory WorldCupGroupPredictionModel.fromJson(Map<String, dynamic> json) {
    final list = json['predictedQualifiers'] as List<dynamic>? ?? [];
    return WorldCupGroupPredictionModel(
      groupLetter: json['groupLetter'] as String,
      predictedQualifiers: list.map((e) => e.toString()).toList(),
      pointsEarned: json['pointsEarned'] != null
          ? double.tryParse(json['pointsEarned'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_letter': groupLetter,
      'predicted_qualifiers': predictedQualifiers,
    };
  }
}

class WorldCupPredictionsResponse {
  final WorldCupWinnerPredictionModel? winner;
  final List<WorldCupGroupPredictionModel> groups;
  final bool locked;
  final DateTime lockTime;

  WorldCupPredictionsResponse({
    this.winner,
    required this.groups,
    required this.locked,
    required this.lockTime,
  });

  factory WorldCupPredictionsResponse.fromJson(Map<String, dynamic> json) {
    final winnerJson = json['winner'] as Map<String, dynamic>?;
    final groupsList = json['groups'] as List<dynamic>? ?? [];
    
    return WorldCupPredictionsResponse(
      winner: winnerJson != null ? WorldCupWinnerPredictionModel.fromJson(winnerJson) : null,
      groups: groupsList.map((e) => WorldCupGroupPredictionModel.fromJson(e as Map<String, dynamic>)).toList(),
      locked: json['locked'] as bool? ?? false,
      lockTime: DateTime.tryParse(json['lockTime']?.toString() ?? '') ?? DateTime(2026, 6, 11, 19),
    );
  }
}
