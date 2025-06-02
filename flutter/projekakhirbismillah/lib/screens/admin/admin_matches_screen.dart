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
    final Color primaryGreen = Colors.green[700]!;
    final Color bgColor = Colors.green[50]!;

    return Consumer<MatchProvider>(
      builder: (context, matchProvider, child) {
        return Scaffold(
          backgroundColor: bgColor,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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
                backgroundColor: primaryGreen,
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
    final Color primaryGreen = Colors.green[700]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      // Team 1 logo
                      if (match.team1?.logoUrl != null &&
                          match.team1!.logoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipOval(
                            child: Image.network(
                              match.team1!.logoUrl!,
                              height: 32,
                              width: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.sports_soccer,
                                    size: 32, color: Colors.green);
                              },
                            ),
                          ),
                        ),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              match.team2?.name ?? 'Team 2',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                            // Team 2 logo
                            if (match.team2?.logoUrl != null &&
                                match.team2!.logoUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ClipOval(
                                  child: Image.network(
                                    match.team2!.logoUrl!,
                                    height: 32,
                                    width: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.sports_soccer,
                                          size: 32, color: Colors.green);
                                    },
                                  ),
                                ),
                              ),
                          ],
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
                color: match.isFinished ? primaryGreen : Colors.orange,
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
