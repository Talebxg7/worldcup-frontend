import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late AuthRepository _repo;

  @override
  Future<UserModel?> build() async {
    _repo = ref.read(authRepositoryProvider);
    return await _repo.getCurrentUser();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.login(username, password);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> googleLogin() async {
    state = const AsyncLoading();
    try {
      final user = await _repo.googleSignIn();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> appleLogin() async {
    state = const AsyncLoading();
    try {
      final user = await _repo.appleSignIn();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> register(String username, String password, {String? email}) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.register(username, password, email: email);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }

  Future<void> refreshUser() async {
    final user = await _repo.getCurrentUser();
    state = AsyncData(user);
  }

  Future<void> updateProfile({
    required String username,
    required String avatarUrl,
    required bool hideUsername,
  }) async {
    try {
      await _repo.updateProfile(username: username, avatarUrl: avatarUrl, hideUsername: hideUsername);
      await refreshUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAnnouncementAsSeen() async {
    try {
      await _repo.seenAnnouncement();
      final currentUser = state.value;
      if (currentUser != null) {
        state = AsyncData(currentUser.copyWith(
          lastSeenAnnouncement: DateTime.now(),
        ));
      }
    } catch (e) {
      final currentUser = state.value;
      if (currentUser != null) {
        state = AsyncData(currentUser.copyWith(
          lastSeenAnnouncement: DateTime.now(),
        ));
      }
      rethrow;
    }
  }
}
