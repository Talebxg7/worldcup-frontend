import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/localization/app_localizations.dart';

import '../../data/payment_repository.dart';
import '../../data/room_repository.dart';
import '../../models/room_models.dart';
import 'payment_checkout_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/create_league_dialog.dart';

class MiniLeagueScreen extends ConsumerStatefulWidget {
  const MiniLeagueScreen({super.key});

  @override
  ConsumerState<MiniLeagueScreen> createState() => _MiniLeagueScreenState();
}

class _MiniLeagueScreenState extends ConsumerState<MiniLeagueScreen>
    with SingleTickerProviderStateMixin {
  final _roomRepo = RoomRepository();
  final _paymentRepo = RoomPaymentRepository();
  late final TabController _tabs;
  late Future<List<RoomModel>> _myRoomsFuture;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _myRoomsFuture = _roomRepo.getMyRooms();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _myRoomsFuture = _roomRepo.getMyRooms();
    });
    await _myRoomsFuture;
  }

  Future<void> _createLeagueDialog() async {
    final input = await showDialog<CreateLeagueInput>(
      context: context,
      builder: (ctx) => const CreateLeagueDialog(),
    );
    if (input == null || !mounted) return;

    try {
      final user = ref.read(authStateProvider).value;
      final isPremium = true; // TEMPORARY: Free testing for all

      if (isPremium) {
        final room = await _roomRepo.createRoom(
          name: input.leagueName,
          leagueId: _competitionToLeagueId(input.competition),
          maxMembers: input.maxMembers,
          paymentId: null,
        );
        await _refresh();
        if (!mounted) return;
        context.push('/room/${room.id}');
        return;
      }

      final payment = await _paymentRepo.createRoomPayment(
        provider: input.paymentProvider,
      );

      if (payment.checkoutUrl == null || payment.checkoutUrl!.isEmpty) {
          throw Exception('Checkout URL is missing');
        }
        PaymentCheckoutResult? result;
        try {
          result = await Navigator.of(context).push<PaymentCheckoutResult>(
            MaterialPageRoute(
              builder: (_) => PaymentCheckoutScreen(checkoutUrl: payment.checkoutUrl!),
            ),
          );
        } catch (_) {
          // Fallback (e.g. desktop platforms): open in external browser.
          final uri = Uri.parse(payment.checkoutUrl!);
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) throw Exception('Could not open payment page');
          return;
        }
        if (result == null || result.cancelled) return;

      final paid = await _paymentRepo.confirmRoomPayment(payment.paymentId);
      if (!paid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment not completed yet. Please try confirm again.')),
        );
        return;
      }

      final room = await _roomRepo.createRoom(
        name: input.leagueName,
        leagueId: _competitionToLeagueId(input.competition),
        maxMembers: input.maxMembers,
        paymentId: payment.paymentId,
      );
      // Increment in Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'leaguesJoined': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
      await _refresh();
      if (!mounted) return;
      context.push('/room/${room.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  Future<void> _joinLeagueDialog() async {
    final controller = TextEditingController();
    try {
      final code = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Join league'.tr(ref)),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Invite code'.tr(ref),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Cancel'.tr(ref)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text('Join'.tr(ref)),
            ),
          ],
        ),
      );
      if (code == null) return;
      if (code.trim().isEmpty) return;

      final room = await _roomRepo.joinRoom(
        joinCode: code.trim(),
      );
      // Increment in Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'leaguesJoined': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      context.push('/room/${room.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join failed: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Mini Leagues'.tr(ref)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: 'My Leagues'.tr(ref)),
              Tab(text: 'Join League'.tr(ref)),
            ],
          ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createLeagueDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Create'.tr(ref), style: const TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          FutureBuilder<List<RoomModel>>(
            future: _myRoomsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final rooms = snap.data ?? [];
              if (rooms.isEmpty) {
                return Center(
                  child: Text('No leagues yet. Create one!'.tr(ref)),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, i) {
                    final r = rooms[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(r.name),
                        subtitle: Text(
                          '${r.leagueName.tr(ref)} · ${r.membersCount}/${r.maxMembers} ${'members'.tr(ref)} · ${r.joinCode}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/room/${r.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_add_rounded, size: 72, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 14),
                  Text(
                    'Join a league with an invite code'.tr(ref),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _joinLeagueDialog,
                    icon: const Icon(Icons.key_rounded, color: Colors.white),
                    label: Text('Enter invite code'.tr(ref), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _competitionToLeagueId(String name) {
    switch (name) {
      case 'Premier League':
        return 39;
      case 'La Liga':
        return 140;
      case 'Serie A':
        return 135;
      case 'Bundesliga':
        return 78;
      case 'Ligue 1':
        return 61;
      case 'Egyptian Premier League':
        return 233;
      case 'Primeira Liga':
        return 94;
      case 'FIFA World Cup':
        return 1;
      case 'UEFA Champions League':
        return 2;
      case 'UEFA Europa League':
        return 3;
      case 'AFCON':
        return 6;
      case 'Copa America':
        return 9;
      case 'Saudi Pro League':
        return 307;
      case 'Qatar Stars League':
        return 305;
      default:
        return 39;
    }
  }
}

