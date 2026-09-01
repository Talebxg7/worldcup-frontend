import 'package:equatable/equatable.dart';

enum MatchStatus { upcoming, live, finished }

class MatchModel extends Equatable {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamFlag;
  final String awayTeamFlag;
  final String venue;
  final String city;
  final String country;
  final DateTime kickoffTime;
  final String stage;
  final String? group;
  final MatchStatus status;
  final int? liveMinute;
  final int? homeScore;
  final int? awayScore;
  final int totalPredictions;
  final PredictionModel? myPrediction;

  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamFlag,
    required this.awayTeamFlag,
    required this.venue,
    required this.city,
    required this.country,
    required this.kickoffTime,
    required this.stage,
    this.group,
    required this.status,
    this.liveMinute,
    this.homeScore,
    this.awayScore,
    required this.totalPredictions,
    this.myPrediction,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as int,
      homeTeam: json['home_team'] as String,
      awayTeam: json['away_team'] as String,
      homeTeamFlag: json['home_team_flag'] as String? ?? '',
      awayTeamFlag: json['away_team_flag'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      kickoffTime: DateTime.parse(json['kickoff_time'] as String),
      stage: json['stage'] as String,
      group: json['group'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'upcoming'),
      liveMinute: (json['live_minute'] as num?)?.toInt(),
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      totalPredictions: json['total_predictions'] as int? ?? 0,
      myPrediction: json['my_prediction'] != null
          ? PredictionModel.fromJson(json['my_prediction'] as Map<String, dynamic>)
          : null,
    );
  }

  MatchModel copyWith({
    int? id,
    String? homeTeam,
    String? awayTeam,
    String? homeTeamFlag,
    String? awayTeamFlag,
    String? venue,
    String? city,
    String? country,
    DateTime? kickoffTime,
    String? stage,
    String? group,
    MatchStatus? status,
    int? liveMinute,
    int? homeScore,
    int? awayScore,
    int? totalPredictions,
    PredictionModel? myPrediction,
  }) {
    return MatchModel(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeTeamFlag: homeTeamFlag ?? this.homeTeamFlag,
      awayTeamFlag: awayTeamFlag ?? this.awayTeamFlag,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      country: country ?? this.country,
      kickoffTime: kickoffTime ?? this.kickoffTime,
      stage: stage ?? this.stage,
      group: group ?? this.group,
      status: status ?? this.status,
      liveMinute: liveMinute ?? this.liveMinute,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      totalPredictions: totalPredictions ?? this.totalPredictions,
      myPrediction: myPrediction ?? this.myPrediction,
    );
  }

  static MatchStatus _parseStatus(String s) {
    switch (s) {
      case 'live':
        return MatchStatus.live;
      case 'finished':
        return MatchStatus.finished;
      default:
        return MatchStatus.upcoming;
    }
  }

  bool get canPredict {
    if (status != MatchStatus.upcoming) return false;
    final deadline = kickoffTime.subtract(const Duration(hours: 2));
    return DateTime.now().isBefore(deadline);
  }

  Duration get timeUntilKickoff => kickoffTime.difference(DateTime.now());
  Duration get timeUntilDeadline => kickoffTime
      .subtract(const Duration(hours: 2))
      .difference(DateTime.now());

  String get displayStage {
    if (group != null) return 'Group $group';
    return stage;
  }

  @override
  List<Object?> get props => [id, status, liveMinute, homeScore, awayScore, myPrediction];
}

class PredictionModel extends Equatable {
  final int id;
  final int matchId;
  final int userId;
  final int homeScore;
  final int awayScore;
  final int? pointsEarned;
  final DateTime submittedAt;

  const PredictionModel({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.homeScore,
    required this.awayScore,
    this.pointsEarned,
    required this.submittedAt,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'] as int,
      matchId: json['match_id'] as int,
      userId: json['user_id'] as int,
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      pointsEarned: _parseNum(json['points_earned'])?.toInt(),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }

  static num? _parseNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'match_id': matchId,
    'home_score': homeScore,
    'away_score': awayScore,
  };

  @override
  List<Object?> get props => [id, homeScore, awayScore, pointsEarned];
}
