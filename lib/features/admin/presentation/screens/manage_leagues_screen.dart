import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

class ManageLeaguesScreen extends StatefulWidget {
  const ManageLeaguesScreen({super.key});

  @override
  State<ManageLeaguesScreen> createState() => _ManageLeaguesScreenState();
}

class _ManageLeaguesScreenState extends State<ManageLeaguesScreen> {
  List<dynamic> _leagues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeagues();
  }

  Future<void> _fetchLeagues() async {
    try {
      final res = await ApiClient.instance.get('/leagues/all');
      setState(() {
        _leagues = res.data as List;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leagues: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLeague(int apiLeagueId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete League?'),
        content: const Text('Are you sure you want to delete this league? Users will no longer see it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiClient.instance.delete('/admin/leagues/$apiLeagueId');
      _fetchLeagues();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _toggleLeague(int apiLeagueId, bool currentEnabled) async {
    try {
      await ApiClient.instance.put('/admin/leagues/$apiLeagueId', data: {'is_enabled': !currentEnabled});
      _fetchLeagues();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to toggle: $e')));
    }
  }

  void _showAddLeagueDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add League'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'API-Sports League ID'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Premier League)')),
              const SizedBox(height: 8),
              TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji Flag (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiClient.instance.post('/admin/leagues', data: {
                  'api_league_id': int.tryParse(idCtrl.text),
                  'name': nameCtrl.text,
                  'emoji': emojiCtrl.text,
                  'is_enabled': true,
                });
                Navigator.pop(ctx);
                _fetchLeagues();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Leagues'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddLeagueDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _leagues.length,
              itemBuilder: (context, index) {
                final league = _leagues[index];
                final isEnabled = league['is_enabled'] ?? false;
                return ListTile(
                  leading: Text(league['emoji'] ?? '⚽', style: const TextStyle(fontSize: 24)),
                  title: Text(league['name']),
                  subtitle: Text('ID: ${league['api_league_id']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isEnabled,
                        onChanged: (v) => _toggleLeague(league['api_league_id'], isEnabled),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteLeague(league['api_league_id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
