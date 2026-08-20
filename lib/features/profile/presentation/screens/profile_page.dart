import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/demo/demo_mode_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/edit_profile_dialog.dart';

/// Production profile screen backed by Firestore `users/{uid}` and Firebase Auth.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  static const _notificationsPrefsKey = 'profile_notifications_enabled';
  static const _languagePrefsKey = 'profile_language_code';

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _linkingFirebase = false;
  String? _firebaseLinkError;
  bool _seedScheduled = false;
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureFirebaseUser();
      _loadNotificationPref();
    });
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(ProfilePage._notificationsPrefsKey) ?? true;
    });
  }

  Future<void> _setNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ProfilePage._notificationsPrefsKey, value);
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Select language'.tr(ref)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: Text('English'.tr(ref)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ar'),
            child: Text('العربية'.tr(ref)),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await ref.read(localeProvider.notifier).setLocale(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language saved'.tr(ref))),
    );
  }

  Future<void> _ensureFirebaseUser() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    final apiUser = ref.read(authStateProvider).value;
    final demo = ref.read(demoModeProvider);
    if (apiUser == null && !demo) return;

    setState(() {
      _linkingFirebase = true;
      _firebaseLinkError = null;
    });
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() => _firebaseLinkError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _linkingFirebase = false);
    }
  }

  Future<void> _seedOrSyncUserDocument(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final apiUser = ref.read(authStateProvider).value;
      
      final Map<String, dynamic> data = {
        'totalPoints': apiUser?.totalPoints ?? 0,
        'totalPredictions': apiUser?.totalPredictions ?? 0,
        'exactScores': apiUser?.exactScores ?? 0,
        'correctWinners': apiUser?.correctResults ?? 0,
      };

      if (!snap.exists) {
        data['username'] = apiUser?.username ?? 'Player';
        data['email'] = apiUser?.email ?? '';
        data['profileImageUrl'] = apiUser?.avatarUrl ?? '';
        data['country'] = kProfileCountryOptions.first;
        data['leaguesJoined'] = 0;
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Failed to seed or sync user document: $e');
    }
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse('$v') ?? 0;
  }

  String _accuracyPercent(int tp, int cw) {
    if (tp <= 0) return '0%';
    return '${(cw / tp * 100).clamp(0, 100).toStringAsFixed(0)}%';
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await ref.read(authStateProvider.notifier).logout();
    ref.read(demoModeProvider.notifier).state = false;
    if (mounted) context.go('/login');
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log out'.tr(ref)),
        content: Text('Are you sure you want to log out?'.tr(ref)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel'.tr(ref))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log out'.tr(ref)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _logout();
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete account'.tr(ref)),
        content: Text(
          'This removes your Firestore profile document and Firebase user when possible, then signs you out. This cannot be undone.'.tr(ref),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel'.tr(ref))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'.tr(ref)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }
    } catch (_) {}

    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }

    await ref.read(authStateProvider.notifier).logout();
    ref.read(demoModeProvider.notifier).state = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account session cleared')),
      );
      context.go('/login');
    }
  }

  Future<void> _openEditProfile({
    required String uid,
    required String username,
    required String country,
    required bool hideUsername,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditProfileDialog(
        uid: uid,
        initialUsername: username,
        initialCountry: country,
        initialHideUsername: hideUsername,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _toggleHideUsername(bool value, String username, String avatarUrl) async {
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            username: username,
            avatarUrl: avatarUrl,
            hideUsername: value,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update privacy setting: $e')),
        );
      }
    }
  }

  Future<void> _pickProfileImage({
    required String uid,
    required String username,
    required bool hideUsername,
  }) async {
    final ImagePicker picker = ImagePicker();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Change Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Selfie'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      
      // Limit file size to 2MB to save bandwidth and storage
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large. Please select an image under 2MB.')),
          );
        }
        return;
      }

      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Update Firebase
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'profileImageUrl': base64String},
        SetOptions(merge: true),
      );

      // Update Postgres
      await ref.read(authStateProvider.notifier).updateProfile(
            username: username,
            avatarUrl: base64String,
            hideUsername: hideUsername,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final apiUser = ref.watch(authStateProvider).value;
    final themeNotifier = ref.read(themeProvider.notifier);

    if (_linkingFirebase) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'.tr(ref))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'.tr(ref))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _firebaseLinkError ?? 'Sign in to view your cloud profile.'.tr(ref),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 15),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _firebaseLinkError = null;
                    });
                    _ensureFirebaseUser();
                  },
                  child: Text('Retry'.tr(ref)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final uid = fbUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'.tr(ref)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () {
                if (apiUser == null) return;
                final rankStr = apiUser.rank > 0 ? ' (Rank #${apiUser.rank})' : '';
                final pointsStr = '${apiUser.totalPoints.toInt()} pts';
                final shareText = 'I have $pointsStr$rankStr on Leagues Predictor! Think you can beat me? Join here: https://whowillwinapp.com';
                Share.share(shareText);
              },
              tooltip: 'Share stats',
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load profile.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_seedScheduled) {
            _seedScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _seedOrSyncUserDocument(uid);
              if (mounted) setState(() {});
            });
          }

          final data = doc.data() ?? {};
          final username = (data['username'] as String?)?.trim().isNotEmpty == true
              ? data['username'] as String
              : 'Player';
          final email = (data['email'] as String?) ?? '';
          final profileImageUrl = (data['profileImageUrl'] as String?) ?? '';
          final country = (data['country'] as String?) ?? '';
          final totalPoints = apiUser != null ? apiUser.totalPoints.toInt() : _readInt(data['totalPoints']);
          final totalPredictions = apiUser != null ? apiUser.totalPredictions : _readInt(data['totalPredictions']);
          final exactScores = apiUser != null ? apiUser.exactScores : _readInt(data['exactScores']);
          final correctWinners = apiUser != null ? apiUser.correctResults : _readInt(data['correctWinners']);
          final leaguesJoined = apiUser?.leaguesJoined ?? 0;
          final accuracy = _accuracyPercent(totalPredictions, correctWinners);

          final crossAxisCount = MediaQuery.sizeOf(context).width >= 720 ? 4 : 2;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UserHeaderSection(
                    profileImageUrl: profileImageUrl,
                    username: username,
                    email: email.isNotEmpty ? email : (apiUser?.email ?? '—'),
                    accuracyLabel: accuracy,
                    isAdmin: apiUser?.isAdmin ?? false,
                    onAvatarTap: () => _pickProfileImage(
                      uid: uid,
                      username: username,
                      hideUsername: apiUser?.hideUsername ?? false,
                    ),
                    onEditProfile: () => _openEditProfile(
                      uid: uid,
                      username: username,
                      country: country.isNotEmpty ? country : kProfileCountryOptions.first,
                      hideUsername: apiUser?.hideUsername ?? false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Stats'.tr(ref),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: crossAxisCount >= 4 ? 1.15 : 1.35,
                        children: [
                          _StatCard(
                            icon: Icons.emoji_events_rounded,
                            value: '$totalPoints',
                            label: 'Total Points'.tr(ref),
                            color: AppColors.accent,
                          ),
                          _StatCard(
                            icon: Icons.edit_note_rounded,
                            value: '$totalPredictions',
                            label: 'Predictions Made'.tr(ref),
                            color: AppColors.secondary,
                          ),
                          _StatCard(
                            icon: Icons.gps_fixed_rounded,
                            value: '$exactScores',
                            label: 'Exact Scores'.tr(ref),
                            color: AppColors.exactScore,
                          ),
                          _StatCard(
                            icon: Icons.sports_soccer_rounded,
                            value: '$correctWinners',
                            label: 'Correct Winners'.tr(ref),
                            color: AppColors.correctResult,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _LeaguesSummaryCard(
                    leaguesJoined: leaguesJoined,
                    onTap: () => context.go('/mini-leagues'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Account settings'.tr(ref),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: isDark ? AppColors.darkCard : theme.cardTheme.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          secondary: const Icon(Icons.notifications_active_rounded),
                          title: Text('Notifications'.tr(ref)),
                          subtitle: Text('Match reminders & updates'.tr(ref)),
                          value: _notificationsEnabled ?? true,
                          onChanged: (v) => _setNotificationPref(v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          secondary: const Icon(Icons.privacy_tip_rounded),
                          title: Text('Hide name'.tr(ref)),
                          subtitle: Text('Hide name on global leaderboard'.tr(ref)),
                          value: apiUser?.hideUsername ?? false,
                          onChanged: (v) => _toggleHideUsername(
                            v,
                            apiUser?.username ?? '',
                            apiUser?.avatarUrl ?? '',
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          secondary: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: AppColors.primary,
                          ),
                          title: Text('Dark mode'.tr(ref)),
                          subtitle: Text(isDark ? 'Dark theme on'.tr(ref) : 'Light theme on'.tr(ref)),
                          value: isDark,
                          onChanged: (_) => themeNotifier.toggleTheme(),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.language_rounded),
                          title: Text('Language'.tr(ref)),
                          subtitle: Text(ref.watch(localeProvider) == 'ar' ? 'العربية' : 'English'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _chooseLanguage,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline_rounded),
                          title: Text('Help & Support'.tr(ref)),
                          subtitle: const Text('predict.game433@gmail.com'),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'predict.game433@gmail.com'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Email copied to clipboard'.tr(ref))),
                              );
                            },
                          ),
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: 'predict.game433@gmail.com'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Email copied to clipboard'.tr(ref))),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.shield_outlined),
                          title: Text('Privacy Policy'.tr(ref)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text('Terms of Service'.tr(ref)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/terms-of-service'),
                        ),
                      ],
                    ),
                  ),
                  if (apiUser?.isAdmin == true) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: isDark ? AppColors.darkCard : theme.cardTheme.color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.secondary),
                        title: Text('Admin panel'.tr(ref), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Manage matches & results'.tr(ref)),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () => context.push('/admin'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Account'.tr(ref),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('Log out'.tr(ref)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    label: Text('Delete account'.tr(ref), style: const TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Live updates from Firestore'.tr(ref),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserHeaderSection extends ConsumerStatefulWidget {
  const _UserHeaderSection({
    required this.profileImageUrl,
    required this.username,
    required this.email,
    required this.accuracyLabel,
    required this.isAdmin,
    required this.onEditProfile,
    required this.onAvatarTap,
  });

  final String profileImageUrl;
  final String username;
  final String email;
  final String accuracyLabel;
  final bool isAdmin;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;

  @override
  ConsumerState<_UserHeaderSection> createState() => _UserHeaderSectionState();
}

class _UserHeaderSectionState extends ConsumerState<_UserHeaderSection> {
  bool _obscureEmail = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = widget.profileImageUrl.trim().isNotEmpty;

    return Card(
      color: theme.brightness == Brightness.dark ? AppColors.darkCard : theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: widget.onAvatarTap,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.darkSurface,
                    child: ClipOval(
                      child: hasImage
                          ? (widget.profileImageUrl.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(widget.profileImageUrl.split(',').last),
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: widget.profileImageUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ))
                          : Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardTheme.color ?? AppColors.darkCard, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.username,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (widget.isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      'ADMIN',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _obscureEmail ? '••••••••••••@••••.•••' : widget.email,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.62),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _obscureEmail = !_obscureEmail),
                  child: Icon(
                    _obscureEmail ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy'.tr(ref) + ': ${widget.accuracyLabel}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 140,
              height: 38,
              child: FilledButton.icon(
                onPressed: widget.onEditProfile,
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: Text('Edit profile'.tr(ref)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.62),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LeaguesSummaryCard extends ConsumerWidget {
  const _LeaguesSummaryCard({
    required this.leaguesJoined,
    required this.onTap,
  });

  final int leaguesJoined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mini leagues'.tr(ref),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.62),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$leaguesJoined ' + 'leagues joined'.tr(ref),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
