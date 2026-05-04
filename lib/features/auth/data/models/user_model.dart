class UserModel {
  final int id;
  final String username;
  final String? email;
  final bool isAdmin;
  final bool isPremium;
  final num totalPoints;
  final int rank;
  final int totalPredictions;
  final int exactScores;
  final int correctResults;
  final String? avatarUrl;
  final bool hideUsername;
  final int leaguesJoined;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.isAdmin,
    required this.isPremium,
    required this.totalPoints,
    required this.rank,
    required this.totalPredictions,
    required this.exactScores,
    required this.correctResults,
    this.avatarUrl,
    this.hideUsername = false,
    this.leaguesJoined = 0,
    required this.createdAt,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return num.tryParse(value)?.toInt() ?? fallback;
    return fallback;
  }

  static num _toNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? fallback;
    return fallback;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      username: json['username'] as String,
      email: json['email'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      totalPoints: _toNum(json['total_points']),
      rank: _toInt(json['rank']),
      totalPredictions: _toInt(json['total_predictions']),
      exactScores: _toInt(json['exact_scores']),
      correctResults: _toInt(json['correct_results']),
      avatarUrl: json['avatar_url'] as String?,
      hideUsername: json['hide_username'] as bool? ?? false,
      leaguesJoined: _toInt(json['leagues_joined']),
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_admin': isAdmin,
      'is_premium': isPremium,
      'total_points': totalPoints,
      'rank': rank,
      'total_predictions': totalPredictions,
      'exact_scores': exactScores,
      'correct_results': correctResults,
      'avatar_url': avatarUrl,
      'hide_username': hideUsername,
      'leagues_joined': leaguesJoined,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    bool? isAdmin,
    bool? isPremium,
    int? totalPoints,
    int? rank,
    int? totalPredictions,
    int? exactScores,
    int? correctResults,
    String? avatarUrl,
    bool? hideUsername,
    int? leaguesJoined,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isPremium: isPremium ?? this.isPremium,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      totalPredictions: totalPredictions ?? this.totalPredictions,
      exactScores: exactScores ?? this.exactScores,
      correctResults: correctResults ?? this.correctResults,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hideUsername: hideUsername ?? this.hideUsername,
      leaguesJoined: leaguesJoined ?? this.leaguesJoined,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
