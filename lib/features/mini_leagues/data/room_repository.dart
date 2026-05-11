import '../../../core/network/api_client.dart';
import '../models/room_models.dart';

class RoomRepository {
  Future<List<RoomModel>> getMyRooms() async {
    final res = await ApiClient.instance.get('/rooms/mine');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => RoomModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<RoomModel> createRoom({
    required String name,
    required int leagueId,
    required int maxMembers,
    int? paymentId,
  }) async {
    final res = await ApiClient.instance.post(
      '/rooms/create',
      data: {
        'name': name,
        'league_id': leagueId,
        'max_members': maxMembers,
        if (paymentId != null) 'payment_id': paymentId,
      },
    );
    return RoomModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<RoomModel> joinRoom({
    required String joinCode,
  }) async {
    final res = await ApiClient.instance.post(
      '/rooms/join',
      data: {
        'join_code': joinCode.trim().toUpperCase(),
      },
    );
    return RoomModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<RoomDetailsModel> getRoom(int roomId) async {
    final res = await ApiClient.instance.get('/rooms/$roomId');
    return RoomDetailsModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<RoomLeaderboardRowModel>> getLeaderboard(int roomId) async {
    final res = await ApiClient.instance.get('/rooms/$roomId/leaderboard');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) =>
            RoomLeaderboardRowModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> kickMember({
    required int roomId,
    required int userId,
  }) async {
    await ApiClient.instance.delete('/rooms/$roomId/members/$userId');
  }

  Future<void> updateMaxMembers({
    required int roomId,
    required int maxMembers,
  }) async {
    await ApiClient.instance.put(
      '/rooms/$roomId/max-members',
      data: {'max_members': maxMembers},
    );
  }

  Future<void> leaveRoom(int roomId) async {
    await ApiClient.instance.delete('/rooms/$roomId/leave');
  }
}
