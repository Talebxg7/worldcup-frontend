class RoomModel {
  final int id;
  final String name;
  final int leagueId;
  final String leagueName;
  final int hostId;
  final String joinCode;
  final int maxMembers;
  final int membersCount;
  final bool isHost;

  const RoomModel({
    required this.id,
    required this.name,
    required this.leagueId,
    required this.leagueName,
    required this.hostId,
    required this.joinCode,
    required this.maxMembers,
    required this.membersCount,
    required this.isHost,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      leagueId: (json['league_id'] as num?)?.toInt() ?? 39,
      leagueName: (json['league_name'] as String?) ?? 'Premier League',
      hostId: (json['host_id'] as num?)?.toInt() ?? 0,
      joinCode: (json['join_code'] as String?) ?? '',
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 20,
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      isHost: (json['is_host'] as bool?) ?? false,
    );
  }
}

class RoomMemberModel {
  final int userId;
  final String username;

  const RoomMemberModel({
    required this.userId,
    required this.username,
  });

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      userId: (json['id'] as num?)?.toInt() ??
          (json['user_id'] as num?)?.toInt() ??
          0,
      username: (json['username'] as String?) ?? 'Member',
    );
  }
}

class RoomLeaderboardRowModel {
  final int rank;
  final int userId;
  final String username;
  final String? avatarUrl;
  final int points;

  const RoomLeaderboardRowModel({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.points,
  });

  factory RoomLeaderboardRowModel.fromJson(Map<String, dynamic> json) {
    return RoomLeaderboardRowModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      points: _parseNum(json['points'])?.toInt() ?? 0,
    );
  }

  static num? _parseNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }
}

class RoomPredictionPeekModel {
  final int userId;
  final String username;
  final String? avatarUrl;
  final int matchId;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamFlag;
  final String? awayTeamFlag;
  final DateTime? kickoffTime;
  final bool hidden;
  final int? homeScore;
  final int? awayScore;
  final bool? redCard;
  final bool? penalty;
  final bool? joker;
  final int? actualHomeScore;
  final int? actualAwayScore;
  final int? pointsEarned;
  final String? status;

  const RoomPredictionPeekModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamFlag,
    this.awayTeamFlag,
    required this.kickoffTime,
    required this.hidden,
    required this.homeScore,
    required this.awayScore,
    this.redCard,
    this.penalty,
    this.joker,
    this.actualHomeScore,
    this.actualAwayScore,
    this.pointsEarned,
    this.status,
  });

  factory RoomPredictionPeekModel.fromJson(Map<String, dynamic> json) {
    return RoomPredictionPeekModel(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      matchId: (json['match_id'] as num?)?.toInt() ?? 0,
      homeTeam: (json['home_team'] as String?) ?? '',
      awayTeam: (json['away_team'] as String?) ?? '',
      homeTeamFlag: json['home_team_flag'] as String?,
      awayTeamFlag: json['away_team_flag'] as String?,
      kickoffTime: DateTime.tryParse((json['kickoff_time'] as String?) ?? ''),
      hidden: (json['hidden'] as bool?) ?? false,
      homeScore: (json['home_score'] as num?)?.toInt(),
      awayScore: (json['away_score'] as num?)?.toInt(),
      redCard: json['red_card'] as bool?,
      penalty: json['penalty'] as bool?,
      joker: json['joker'] as bool?,
      actualHomeScore: (json['actual_home_score'] as num?)?.toInt(),
      actualAwayScore: (json['actual_away_score'] as num?)?.toInt(),
      pointsEarned: RoomLeaderboardRowModel._parseNum(json['points_earned'])?.toInt(),
      status: json['status'] as String?,
    );
  }
}

class RoomDetailsModel {
  final RoomModel room;
  final List<RoomMemberModel> members;
  final List<RoomPredictionPeekModel> predictions;

  const RoomDetailsModel({
    required this.room,
    required this.members,
    required this.predictions,
  });

  factory RoomDetailsModel.fromJson(Map<String, dynamic> json) {
    final room = RoomModel.fromJson(json);
    final members = ((json['members'] as List?) ?? const [])
        .map((e) => RoomMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final predictions = ((json['predictions'] as List?) ?? const [])
        .map((e) =>
            RoomPredictionPeekModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return RoomDetailsModel(room: room, members: members, predictions: predictions);
  }
}
