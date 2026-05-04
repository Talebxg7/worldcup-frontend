import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mini_league_models.dart';

String generateInviteCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(
    6,
    (index) => chars[Random().nextInt(chars.length)],
  ).join();
}

class LeagueRepository {
  static const _leaguesKey = 'mini_leagues_v1';
  static const _myLeagueIdsKey = 'mini_leagues_my_ids_v1';

  /// Hard cap for league roster (including owner).
  static const int leagueMemberCap = 20;

  static int clampMaxMembers(int value) =>
      value.clamp(1, leagueMemberCap).toInt();

  Future<List<LeagueModel>> getMyLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    final myIds = prefs.getStringList(_myLeagueIdsKey) ?? const <String>[];
    final all = await _getAllLeagues();
    return all.where((l) => myIds.contains(l.leagueId)).toList();
  }

  Future<LeagueModel?> findByInviteCode(String inviteCode) async {
    final all = await _getAllLeagues();
    try {
      return all.firstWhere((l) => l.inviteCode.toUpperCase() == inviteCode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  Future<LeagueModel> createLeague({
    required String leagueName,
    required String competition,
    required bool isPrivate,
    required String ownerUserId,
    required int maxMembers,
  }) async {
    if (leagueName.trim().isEmpty) {
      throw ArgumentError('League name cannot be empty');
    }
    final cap = clampMaxMembers(maxMembers);

    final inviteCode = generateInviteCode();
    final doc = FirebaseFirestore.instance.collection('mini_leagues').doc();
    final forcePrivate = true;

    await doc.set({
      'leagueId': doc.id,
      'leagueName': leagueName.trim(),
      'competition': competition,
      'isPrivate': forcePrivate,
      'inviteCode': inviteCode,
      'ownerUserId': ownerUserId,
      'members': [ownerUserId],
      'maxMembers': cap,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snap = await doc.get();
    final data = snap.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final league = LeagueModel(
      leagueId: doc.id,
      leagueName: (data['leagueName'] as String?) ?? leagueName.trim(),
      ownerUserId: ownerUserId,
      inviteCode: (data['inviteCode'] as String?) ?? inviteCode,
      members: List<String>.from(data['members'] as List? ?? [ownerUserId]),
      createdAt: createdAt,
      competition: (data['competition'] as String?) ?? competition,
      isPrivate: (data['isPrivate'] as bool?) ?? forcePrivate,
      maxMembers: LeagueModel.sanitizeMaxMembers(data['maxMembers'] ?? cap),
    );

    final all = await _getAllLeagues();
    final withoutDup = all.where((l) => l.leagueId != league.leagueId).toList();
    final next = [...withoutDup, league];
    await _setAllLeagues(next);

    final prefs = await SharedPreferences.getInstance();
    final myIds = prefs.getStringList(_myLeagueIdsKey) ?? <String>[];
    if (!myIds.contains(league.leagueId)) {
      await prefs.setStringList(_myLeagueIdsKey, [...myIds, league.leagueId]);
    }

    return league;
  }

  Future<LeagueModel> joinLeague({
    required String inviteCode,
    required String userId,
  }) async {
    final all = await _getAllLeagues();
    final idx = all.indexWhere((l) => l.inviteCode.toUpperCase() == inviteCode.toUpperCase());
    if (idx < 0) throw Exception('League not found');

    final league = all[idx];
    if (!league.members.contains(userId) &&
        league.members.length >= league.maxMembers) {
      throw Exception(
        'This league is full (${league.maxMembers} members max)',
      );
    }
    final members = league.members.contains(userId)
        ? league.members
        : [...league.members, userId];
    final updated = league.copyWith(members: members);

    final next = [...all]..[idx] = updated;
    await _setAllLeagues(next);

    final prefs = await SharedPreferences.getInstance();
    final myIds = prefs.getStringList(_myLeagueIdsKey) ?? <String>[];
    if (!myIds.contains(updated.leagueId)) {
      await prefs.setStringList(_myLeagueIdsKey, [...myIds, updated.leagueId]);
    }

    return updated;
  }

  Future<void> leaveLeague({
    required String leagueId,
    required String userId,
  }) async {
    final all = await _getAllLeagues();
    final idx = all.indexWhere((l) => l.leagueId == leagueId);
    if (idx < 0) return;

    final league = all[idx];
    final updatedMembers = league.members.where((m) => m != userId).toList();
    final updated = league.copyWith(members: updatedMembers);
    final next = [...all]..[idx] = updated;
    await _setAllLeagues(next);

    final prefs = await SharedPreferences.getInstance();
    final myIds = prefs.getStringList(_myLeagueIdsKey) ?? <String>[];
    await prefs.setStringList(_myLeagueIdsKey, myIds.where((id) => id != leagueId).toList());
  }

  /// Placeholder leaderboard (local only).
  /// Sort descending points.
  Future<List<LeagueLeaderboardRow>> getLeaderboard({
    required LeagueModel league,
  }) async {
    // TODO: Replace with Firestore aggregation later.
    final rows = league.members.map((id) {
      return LeagueLeaderboardRow(
        userId: id,
        username: id == league.ownerUserId ? 'Owner' : 'Member',
        points: 0,
      );
    }).toList();
    rows.sort((a, b) => b.points.compareTo(a.points));
    return rows;
  }

  Future<List<LeagueModel>> _getAllLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_leaguesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(LeagueModel.fromJson).toList();
  }

  Future<void> _setAllLeagues(List<LeagueModel> leagues) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _leaguesKey,
      jsonEncode(leagues.map((e) => e.toJson()).toList()),
    );
  }

}

