import 'package:flutter/material.dart';
import '../../../../services/football_api_service.dart';

class FixturesScreen extends StatefulWidget {
  const FixturesScreen({super.key});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  late Future<List<FixtureModel>> _fixturesFuture;

  @override
  void initState() {
    super.initState();
    _fixturesFuture = FootballApiService.getFixtures(league: 39, season: 2024);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fixtures')),
      body: FutureBuilder<List<FixtureModel>>(
        future: _fixturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final fixtures = snapshot.data ?? [];
          if (fixtures.isEmpty) {
            return const Center(child: Text('No fixtures found'));
          }

          return ListView.separated(
            itemCount: fixtures.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = fixtures[index];
              return ListTile(
                title: Text('${f.homeTeam} vs ${f.awayTeam}'),
                subtitle: Text(
                  '${f.date?.toLocal() ?? ''}  •  ${f.status ?? '-'}',
                ),
                trailing: Text(
                  '${f.homeGoals ?? '-'} - ${f.awayGoals ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

