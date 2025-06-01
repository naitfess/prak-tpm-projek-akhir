import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../models/match_schedule.dart';
import 'add_match_screen.dart';
import 'edit_match_screen.dart';
import 'add_team_screen.dart';

class AdminMatchesScreen extends StatefulWidget {
  const AdminMatchesScreen({super.key});

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      matchProvider.loadMatches();
      matchProvider.loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, matchProvider, child) {
        return Scaffold(
          body: matchProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : matchProvider.errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${matchProvider.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => matchProvider.loadMatches(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : matchProvider.matches.isEmpty
                      ? const Center(
                          child: Text('No matches available'),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await matchProvider.loadMatches();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: matchProvider.matches.length,
                            itemBuilder: (context, index) {
                              final match = matchProvider.matches[index];
                              return _buildMatchCard(context, match);
                            },
                          ),
                        ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "add_team",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTeamScreen()),
                  );
                },
                backgroundColor: Colors.green,
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: "add_match",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMatchScreen()),
                  );
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchSchedule match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.team1?.name ?? 'Team 1',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (match.isFinished)
                        Text(
                          '${match.skor1} - ${match.skor2}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      else
                        const Text('VS',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.team2?.name ?? 'Team 2',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMatchScreen(match: match),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${match.date.day}/${match.date.month}/${match.date.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  match.time,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: match.isFinished ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                match.isFinished
                    ? 'Pemenang: ${match.winner}'
                    : 'Status: ${match.winner}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
