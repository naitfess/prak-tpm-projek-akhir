import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/match_schedule.dart';
import 'prediction_dialog.dart';
import '../../theme/app_colors.dart';

class UserMatchesScreen extends StatefulWidget {
  const UserMatchesScreen({super.key});

  @override
  State<UserMatchesScreen> createState() => _UserMatchesScreenState();
}

class _UserMatchesScreenState extends State<UserMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      final predictionProvider =
          Provider.of<PredictionProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      matchProvider.loadMatches();
      predictionProvider.loadPredictions();
      // Refresh user data to get updated points
      authProvider.checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: AppColors.cardBackground,
          child: SafeArea(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryGreen,
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: "Upcoming"),
                    Tab(text: "Finished"),
                    Tab(text: "Prediction History"),
                  ],
                ),
                Divider(height: 1, thickness: 1, color: AppColors.divider),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<MatchProvider, PredictionProvider>(
        builder: (context, matchProvider, predictionProvider, child) {
          if (matchProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = matchProvider.matches;
          final predictions = predictionProvider.predictions;

          final upcomingMatches = matches.where((m) => !m.isFinished).toList();
          final finishedMatches = matches.where((m) => m.isFinished).toList();

          // Prediction history: only matches where user has predicted
          final predictedMatchIds =
              predictions.map((p) => p.matchScheduleId).toSet();
          final predictionHistory =
              matches.where((m) => predictedMatchIds.contains(m.id)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming Matches
              _buildMatchList(
                context,
                upcomingMatches,
                predictionProvider,
                emptyText: "No upcoming matches.",
                showPredictionButton: true,
              ),
              // Finished Matches
              _buildMatchList(
                context,
                finishedMatches,
                predictionProvider,
                emptyText: "No finished matches.",
                showPredictionButton: false,
              ),
              // Prediction History
              _buildMatchList(
                context,
                predictionHistory,
                predictionProvider,
                emptyText: "No prediction history.",
                showPredictionButton: false,
                onlyShowPredicted: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    List<MatchSchedule> matches,
    PredictionProvider predictionProvider, {
    required String emptyText,
    bool showPredictionButton = false,
    bool onlyShowPredicted = false,
  }) {
    final Color cardColor = showPredictionButton
        ? Colors.green[50]! // Upcoming: hijau muda
        : Colors.white; // Finished/history: putih/hijau muda

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(
          context,
          match,
          predictionProvider,
          showPredictionButton: showPredictionButton,
          onlyShowPredicted: onlyShowPredicted,
          cardColor: cardColor,
        );
      },
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchSchedule match,
    PredictionProvider predictionProvider, {
    bool showPredictionButton = false,
    bool onlyShowPredicted = false,
    Color? cardColor,
  }) {
    final hasPredicted = predictionProvider.hasPredictedMatch(match.id);
    final userPrediction = predictionProvider.predictions
        .where((p) => p.matchScheduleId == match.id)
        .cast<dynamic>()
        .firstWhere(
          (_) => true,
          orElse: () => null,
        );

    if (onlyShowPredicted && userPrediction == null) {
      return const SizedBox.shrink();
    }

    String? predictedText;
    if (userPrediction != null) {
      if (userPrediction.predictedTeamId == (match.team1?.id ?? -1)) {
        predictedText = '${match.team1?.name ?? 'Team 1'} Win';
      } else if (userPrediction.predictedTeamId == (match.team2?.id ?? -1)) {
        predictedText = '${match.team2?.name ?? 'Team 2'} Win';
      } else if (userPrediction.predictedTeamId == 0) {
        predictedText = 'Draw';
      }
    }

    bool isCorrect = false;
    if (match.isFinished && userPrediction != null) {
      if (match.winner == 'Seri' && userPrediction.predictedTeamId == 0) {
        isCorrect = true;
      } else if (userPrediction.predictedTeamId == (match.team1?.id ?? -1) &&
          match.winner == (match.team1?.name ?? '')) {
        isCorrect = true;
      } else if (userPrediction.predictedTeamId == (match.team2?.id ?? -1) &&
          match.winner == (match.team2?.name ?? '')) {
        isCorrect = true;
      }
    }

    final Color effectiveCardColor =
        cardColor ?? (match.isFinished ? Colors.green[100]! : Colors.white);

    return Card(
      elevation: 5,
      color: cardColor ?? AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      if (match.team1?.logoUrl != null &&
                          match.team1!.logoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: ClipOval(
                            child: Image.network(
                              match.team1!.logoUrl!,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.sports_soccer,
                                    size: 40, color: Colors.green);
                              },
                            ),
                          ),
                        ),
                      Text(
                        match.team1?.name ?? 'Team 1',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    if (match.isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${match.skor1} - ${match.skor2}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.date.day}/${match.date.month}/${match.date.year}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      match.time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      if (match.team2?.logoUrl != null &&
                          match.team2!.logoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: ClipOval(
                            child: Image.network(
                              match.team2!.logoUrl!,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.sports_soccer,
                                    size: 40, color: Colors.green);
                              },
                            ),
                          ),
                        ),
                      Text(
                        match.team2?.name ?? 'Team 2',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (match.isFinished) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Final Result - Winner: ${match.winner}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (userPrediction != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.blue : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Prediction: $predictedText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        isCorrect
                            ? '✓ Correct Prediction!'
                            : '✗ Wrong Prediction',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No prediction for this match',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ] else if (hasPredicted && userPrediction != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Prediction:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      predictedText ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Waiting for match result...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (showPredictionButton) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PredictionDialog(match: match),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Make Prediction'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Status: ${match.status}',
              style: TextStyle(
                color: match.status == 'Belum Dimainkan'
                    ? Colors.orange
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (match.isFinished)
              Text(
                'Winner: ${match.winner}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
