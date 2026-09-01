import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/widgets/feedback_dialog.dart';

class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0B1120),
              Color(0xFF070B14),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEEF2F6),
              Color(0xFFE2E8F0),
            ],
          );

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.8);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1).withOpacity(0.6);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
          border: Border(
            right: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header with Logo & User info
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: Border.all(
                              color: AppColors.stadiumNeonGreen.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.stadiumNeonGreen.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.sports_soccer_rounded,
                                color: AppColors.stadiumNeonGreen,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WhoWillWin',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: textColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.stadiumNeonGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SEASON 2025/26',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.stadiumNeonGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    if (user != null) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/profile');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF2563EB).withOpacity(0.2),
                                backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                    ? Text(
                                        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF38BDF8),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.username,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${user.totalPoints} pts • Rank #${user.rank}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: secondaryTextColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Drawer Navigation Items List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _SectionTitle(title: 'NAVIGATION', isDark: isDark),
                    _DrawerNavTile(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Competitions & Matches',
                      subtitle: 'Browse all leagues',
                      color: AppColors.stadiumNeonGreen,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.assignment_rounded,
                      title: 'My Predictions',
                      subtitle: 'Active & past slips',
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/predictions');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.groups_rounded,
                      title: 'Mini Leagues',
                      subtitle: 'Play with friends',
                      color: const Color(0xFFA855F7),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/mini-leagues');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.leaderboard_rounded,
                      title: 'Leaderboard',
                      subtitle: 'Global rankings & points',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/leaderboard');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.live_tv_rounded,
                      title: 'Live Scores',
                      subtitle: 'Real-time match updates',
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home/live');
                      },
                    ),

                    const SizedBox(height: 8),
                    _SectionTitle(title: 'QUICK LEAGUES', isDark: isDark),
                    _LeagueQuickTile(
                      emoji: '🏆',
                      title: 'Champions League',
                      leagueId: '2',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home/fixtures?leagueId=2&leagueName=UEFA%20Champions%20League');
                      },
                    ),
                    _LeagueQuickTile(
                      emoji: '🦁',
                      title: 'Premier League',
                      leagueId: '39',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home/fixtures?leagueId=39&leagueName=Premier%20League');
                      },
                    ),
                    _LeagueQuickTile(
                      emoji: '🇪🇸',
                      title: 'La Liga',
                      leagueId: '140',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home/fixtures?leagueId=140&leagueName=La%20Liga');
                      },
                    ),
                    _LeagueQuickTile(
                      emoji: '🌍',
                      title: 'World Cup 2026',
                      leagueId: '1',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/home/fixtures?leagueId=1&leagueName=World%20Cup%202026');
                      },
                    ),

                    const SizedBox(height: 8),
                    _SectionTitle(title: 'HELP & SETTINGS', isDark: isDark),
                    _DrawerNavTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Rules & Scoring',
                      subtitle: 'How points are calculated',
                      color: const Color(0xFF14B8A6),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showRulesDialog(context);
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.rate_review_outlined,
                      title: 'Send Feedback',
                      subtitle: 'Tell us your thoughts',
                      color: const Color(0xFF0284C7),
                      onTap: () {
                        Navigator.of(context).pop();
                        FeedbackDialog.show(context);
                      },
                    ),
                    _DrawerNavTile(
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      title: isDark ? 'Dark Theme' : 'Light Theme',
                      subtitle: 'Toggle app appearance',
                      color: AppColors.primary,
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeColor: AppColors.stadiumNeonGreen,
                        onChanged: (_) => themeNotifier.toggleTheme(),
                      ),
                      onTap: () => themeNotifier.toggleTheme(),
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      _SectionTitle(title: 'ADMINISTRATION', isDark: isDark),
                      _DrawerNavTile(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Admin Dashboard',
                        subtitle: 'Matches, feeds & users',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/admin');
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Footer with app version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WhoWillWin v1.0.20',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/privacy-policy');
                      },
                      child: Text(
                        'Privacy',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_score_rounded, color: Color(0xFF14B8A6), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Scoring Rules',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ruleItem('🎯 Exact Score Prediction', '+3 Points (e.g. Predicted 2-1 and match finished 2-1)'),
                const SizedBox(height: 10),
                _ruleItem('⚽ Correct Outcome (W/D/L)', '+1 Point (e.g. Predicted 3-0 and match finished 1-0)'),
                const SizedBox(height: 10),
                _ruleItem('🔥 Bonus Goalscorer Prediction', '+2 Points (If your selected goalscorer scores)'),
                const SizedBox(height: 10),
                _ruleItem('🏆 League Season Challenges', 'Earn up to +25 bonus points at the end of each tournament!'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got It!'),
            ),
          ],
        );
      },
    );
  }

  Widget _ruleItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueQuickTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String leagueId;
  final VoidCallback onTap;

  const _LeagueQuickTile({
    required this.emoji,
    required this.title,
    required this.leagueId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
