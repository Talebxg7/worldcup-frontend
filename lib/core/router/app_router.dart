import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/verification_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_of_service_screen.dart';
import '../shell/main_shell.dart';
import '../../features/competitions/presentation/screens/competition_selection_screen.dart';
import '../../features/matches/presentation/screens/match_detail_screen.dart';
import '../../features/matches/presentation/screens/prediction_fixtures_screen.dart';
import '../../features/matches/presentation/screens/standings_screen.dart';
import '../../features/matches/presentation/screens/live_screen.dart';
import '../../features/predictions_dashboard/presentation/screens/predictions_dashboard_screen.dart';
import '../../features/competitions/presentation/screens/season_challenges_screen.dart';
import '../../features/competitions/presentation/screens/league_challenge_detail_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/profile/presentation/screens/profile_page.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/admin/presentation/screens/add_match_screen.dart';
import '../../features/admin/presentation/screens/enter_result_screen.dart';
import '../../features/admin/presentation/screens/manage_leagues_screen.dart';
import '../demo/demo_mode_provider.dart';
import '../../features/mini_leagues/presentation/screens/mini_league_screen.dart';
import '../../features/mini_leagues/presentation/screens/room_screen.dart';
import '../../features/mini_leagues/presentation/screens/room_live_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isDemoMode = ref.read(demoModeProvider);

      // Avoid redirect flicker/loops while auth state is still resolving.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null || isDemoMode;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password' ||
          state.matchedLocation == '/verify-email' ||
          state.matchedLocation == '/privacy-policy' ||
          state.matchedLocation == '/terms-of-service' ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/forgot-password' ||
              state.matchedLocation == '/reset-password' ||
              state.matchedLocation == '/verify-email')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (ctx, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (ctx, state) => ResetPasswordScreen(
          prefilledEmail: state.uri.queryParameters['email'],
          prefilledToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(path: '/privacy-policy', builder: (ctx, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms-of-service', builder: (ctx, state) => const TermsOfServiceScreen()),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: CompetitionSelectionScreen()),
            routes: [
              GoRoute(
                path: 'fixtures',
                builder: (ctx, state) {
                  final leagueId = int.parse(state.uri.queryParameters['leagueId'] ?? '39');
                  final leagueName = state.uri.queryParameters['leagueName'] ?? 'League';
                  return PredictionFixturesScreen(leagueId: leagueId, leagueName: leagueName);
                },
              ),
              GoRoute(
                path: 'standings',
                builder: (ctx, state) => const StandingsScreen(),
              ),
              GoRoute(
                path: 'live',
                builder: (ctx, state) => const LiveScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/predictions',
            pageBuilder: (ctx, state) => const NoTransitionPage(child: PredictionsDashboardScreen()),
          ),
          GoRoute(
            path: '/worldcup',
            pageBuilder: (ctx, state) {
              final roomId = int.tryParse(state.uri.queryParameters['roomId'] ?? '');
              return NoTransitionPage(child: SeasonChallengesScreen(roomId: roomId));
            },
          ),
          GoRoute(
            path: '/challenge/league/:leagueId',
            pageBuilder: (ctx, state) {
              final leagueId = int.parse(state.pathParameters['leagueId']!);
              return NoTransitionPage(child: LeagueChallengeDetailScreen(leagueId: leagueId));
            },
          ),

          GoRoute(
            path: '/leaderboard',
            pageBuilder: (ctx, state) => const NoTransitionPage(child: LeaderboardScreen()),
          ),
          GoRoute(
            path: '/mini-leagues',
            pageBuilder: (ctx, state) => const NoTransitionPage(child: MiniLeagueScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (ctx, state) => const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      GoRoute(
        path: '/public-profile/:id',
        builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'];
          final leagueId = int.tryParse(state.uri.queryParameters['leagueId'] ?? '');
          final roomId = int.tryParse(state.uri.queryParameters['roomId'] ?? '');
          return PublicProfileScreen(
            userId: id,
            fallbackUsername: name,
            leagueId: leagueId,
            roomId: roomId,
          );
        },
      ),
      GoRoute(
        path: '/match/:id',
        builder: (ctx, state) => MatchDetailScreen(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/matches/:id',
        builder: (ctx, state) => MatchDetailScreen(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin',
        builder: (ctx, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/admin/add-match',
        builder: (ctx, state) => const AddMatchScreen(),
      ),
      GoRoute(
        path: '/admin/manage-leagues',
        builder: (ctx, state) => const ManageLeaguesScreen(),
      ),
      GoRoute(
        path: '/admin/enter-result/:id',
        builder: (ctx, state) => EnterResultScreen(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (ctx, state) {
          final roomId = int.tryParse(state.pathParameters['roomId'] ?? '');
          if (roomId == null) {
            return const Scaffold(body: Center(child: Text('Invalid room id')));
          }
          return RoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/room/:roomId/live',
        builder: (ctx, state) {
          final roomId = int.tryParse(state.pathParameters['roomId'] ?? '');
          if (roomId == null) {
            return const Scaffold(body: Center(child: Text('Invalid room id')));
          }
          return RoomLiveScreen(roomId: roomId);
        },
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
  
  ref.listen(authStateProvider, (_, __) => router.refresh());
  ref.listen(demoModeProvider, (_, __) => router.refresh());

  return router;
});
