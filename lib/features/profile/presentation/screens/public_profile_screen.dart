import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';

class PublicProfileModel {
  final int id;
  final String username;
  final String? avatarUrl;
  final String country;
  final double totalPoints;
  final int totalPredictions;
  final int rank;
  final double seasonPoints;
  final String contextLabel;

  const PublicProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.country,
    required this.totalPoints,
    required this.totalPredictions,
    required this.rank,
    required this.seasonPoints,
    this.contextLabel = 'Global',
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      country: json['country'] ?? '',
      totalPoints: _parseNum(json['total_points'])?.toDouble() ?? 0.0,
      totalPredictions: _parseNum(json['total_predictions'])?.toInt() ?? 0,
      rank: _parseNum(json['rank'])?.toInt() ?? 0,
      seasonPoints: _parseNum(json['season_points'])?.toDouble() ?? 0.0,
      contextLabel: json['context_label'] ?? 'Global',
    );
  }

  static num? _parseNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }
}

typedef ProfileArgs = ({int userId, int? leagueId, int? roomId});

final publicProfileProvider = FutureProvider.autoDispose.family<PublicProfileModel, ProfileArgs>((ref, args) async {
  final queryParams = <String, dynamic>{};
  if (args.leagueId != null) queryParams['league_id'] = args.leagueId;
  if (args.roomId != null) queryParams['room_id'] = args.roomId;
  
  final res = await ApiClient.instance.get('/auth/profile/${args.userId}', params: queryParams);
  return PublicProfileModel.fromJson(res.data);
});

class PublicProfileScreen extends ConsumerWidget {
  final int userId;
  final String? fallbackUsername;
  final int? leagueId;
  final int? roomId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.fallbackUsername,
    this.leagueId,
    this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (userId: userId, leagueId: leagueId, roomId: roomId);
    final profileAsync = ref.watch(publicProfileProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text(fallbackUsername ?? 'Profile'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (profile) => _buildProfile(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Profile unavailable or hidden',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, PublicProfileModel profile) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.decimalPattern();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 56,
            backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 56)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (profile.country.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  profile.country,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  label: '${profile.contextLabel} Rank',
                  value: '#${fmt.format(profile.rank)}',
                ),
                const Divider(height: 24),
                _StatRow(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.tealAccent,
                  label: '${profile.contextLabel} Points',
                  value: fmt.format(profile.totalPoints),
                ),
                const Divider(height: 24),
                _StatRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: Colors.lightBlue,
                  label: 'Points This Season',
                  value: fmt.format(profile.seasonPoints),
                ),
                const Divider(height: 24),
                _StatRow(
                  icon: Icons.analytics_rounded,
                  iconColor: Colors.purpleAccent,
                  label: 'Total Predictions',
                  value: fmt.format(profile.totalPredictions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
