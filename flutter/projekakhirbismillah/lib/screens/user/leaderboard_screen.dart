import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = Colors.green[50]!;
    final Color primaryGreen = Colors.green[700]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<LeaderboardProvider>().refreshAll();
            },
          ),
        ],
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, leaderboardProvider, child) {
          if (leaderboardProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (leaderboardProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${leaderboardProvider.errorMessage}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      leaderboardProvider.refreshAll();
                    },
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
            );
          }

          return RefreshIndicator(
            onRefresh: () => leaderboardProvider.refreshAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leaderboardProvider.userRank != null)
                    _buildUserRankCard(leaderboardProvider.userRank!),
                  const SizedBox(height: 24),
                  if (leaderboardProvider.stats != null)
                    _buildStatsCard(leaderboardProvider.stats!),
                  const SizedBox(height: 24),
                  const Text(
                    'Top 10 Players',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (leaderboardProvider.leaderboard.isEmpty)
                    const Center(
                      child: Text(
                        'No leaderboard data available',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    Column(
                      children: leaderboardProvider.leaderboard
                          .map((entry) => _buildLeaderboardItem(entry))
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserRankCard(UserRank userRank) {
    return Card(
      elevation: 6,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Position',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${userRank.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userRank.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${userRank.poin} points',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${userRank.rank} of ${userRank.totalUsers}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(LeaderboardStats stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Players',
                    stats.totalUsers.toString(),
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Highest Score',
                    stats.highestScore.toString(),
                    Icons.star,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average Score',
                    stats.averageScore.toStringAsFixed(1),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Points',
                    stats.totalPoints.toString(),
                    Icons.assessment,
                  ),
                ),
              ],
            ),
            if (stats.topUser != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Top Player: ${stats.topUser!.username} (${stats.topUser!.poin} pts)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.green),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    Color rankColor = Colors.grey;
    IconData? rankIcon;

    if (entry.rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 3) {
      rankColor = Colors.brown;
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: entry.rank <= 3 ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: entry.rank <= 3 && rankIcon != null
                ? Icon(rankIcon, color: Colors.white, size: 20)
                : Text(
                    '${entry.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: entry.rank <= 3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${entry.poin} pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
