class LeagueModel {
  final String leagueId;
  final String leagueName;
  final String ownerUserId;
  final String inviteCode;
  final List<String> members;
  final DateTime createdAt;
  final String competition;
  final bool isPrivate;
  /// Total member slots (including the owner). Capped at 20.
  final int maxMembers;

  const LeagueModel({
    required this.leagueId,
    required this.leagueName,
    required this.ownerUserId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
    this.competition = 'Premier League',
    this.isPrivate = false,
    this.maxMembers = 20,
  });

  LeagueModel copyWith({
    String? leagueName,
    String? ownerUserId,
    String? inviteCode,
    List<String>? members,
    String? competition,
    bool? isPrivate,
    int? maxMembers,
  }) {
    return LeagueModel(
      leagueId: leagueId,
      leagueName: leagueName ?? this.leagueName,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      createdAt: createdAt,
      competition: competition ?? this.competition,
      isPrivate: isPrivate ?? this.isPrivate,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }

  Map<String, dynamic> toJson() => {
        'leagueId': leagueId,
        'leagueName': leagueName,
        'ownerUserId': ownerUserId,
        'inviteCode': inviteCode,
        'members': members,
        'createdAt': createdAt.toIso8601String(),
        'competition': competition,
        'isPrivate': isPrivate,
        'maxMembers': maxMembers,
      };

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(
      leagueId: (json['leagueId'] as String?) ?? '',
      leagueName: (json['leagueName'] as String?) ?? '',
      ownerUserId: (json['ownerUserId'] as String?) ?? '',
      inviteCode: (json['inviteCode'] as String?) ?? '',
      members: ((json['members'] as List?) ?? const []).cast<String>(),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      competition: (json['competition'] as String?) ?? 'Premier League',
      isPrivate: (json['isPrivate'] as bool?) ?? false,
      maxMembers: sanitizeMaxMembers(json['maxMembers']),
    );
  }

  /// Parses Firestore / JSON; defaults to 20, clamps to [1, 20].
  static int sanitizeMaxMembers(dynamic raw) {
    final n = raw is int ? raw : int.tryParse('$raw');
    if (n == null || n < 1) return 20;
    return n > 20 ? 20 : n;
  }
}

class LeagueLeaderboardRow {
  final String userId;
  final String username;
  final int points;

  const LeagueLeaderboardRow({
    required this.userId,
    required this.username,
    required this.points,
  });
}

