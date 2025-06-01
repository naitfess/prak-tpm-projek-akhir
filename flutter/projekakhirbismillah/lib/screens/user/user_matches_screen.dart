import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/match_schedule.dart';
import 'prediction_dialog.dart';

class UserMatchesScreen extends StatefulWidget {
  const UserMatchesScreen({super.key});

  @override
  State<UserMatchesScreen> createState() => _UserMatchesScreenState();
}

class _UserMatchesScreenState extends State<UserMatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      final predictionProvider = Provider.of<PredictionProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      matchProvider.loadMatches();
      predictionProvider.loadPredictions();
      // Refresh user data to get updated points
      authProvider.checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MatchProvider, PredictionProvider>(
      builder: (context, matchProvider, predictionProvider, child) {
        if (matchProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (matchProvider.matches.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No matches available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back later for upcoming matches!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await matchProvider.loadMatches();
            await predictionProvider.loadPredictions();
            // Refresh auth to update points
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.checkAuthStatus();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matchProvider.matches.length,
            itemBuilder: (context, index) {
              final match = matchProvider.matches[index];
              return _buildMatchCard(context, match, predictionProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchSchedule match, PredictionProvider predictionProvider) {
    final hasPredicted = predictionProvider.hasPredictedMatch(match.id);
    final userPrediction = predictionProvider.predictions
        .where((p) => p.matchScheduleId == match.id)
        .cast<dynamic>()
        .firstWhere(
          (_) => true,
          orElse: () => null,
        );

    String? predictedText;
    if (userPrediction != null) {
      if (userPrediction.predictedTeamId == (match.team1?.id ?? -1)) {
        predictedText = '${match.team1?.name ?? 'Tim 1'} Menang';
      } else if (userPrediction.predictedTeamId == (match.team2?.id ?? -1)) {
        predictedText = '${match.team2?.name ?? 'Tim 2'} Menang';
      } else if (userPrediction.predictedTeamId == 0) {
        predictedText = 'Seri';
      }
    }

    bool isCorrect = false;
    if (match.isFinished && userPrediction != null) {
      if (match.winner == 'Seri' && userPrediction.predictedTeamId == 0) {
        isCorrect = true;
      } else if (userPrediction.predictedTeamId == (match.team1?.id ?? -1) && match.winner == (match.team1?.name ?? '')) {
        isCorrect = true;
      } else if (userPrediction.predictedTeamId == (match.team2?.id ?? -1) && match.winner == (match.team2?.name ?? '')) {
        isCorrect = true;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match teams and scores
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team1?.name ?? 'Team 1',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (match.team1?.logoUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(
                            match.team1!.logoUrl!,
                            height: 40,
                            width: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.sports_soccer, size: 40, color: Colors.blue);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    if (match.isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          '${match.skor1} - ${match.skor2}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.green,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
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
                      Text(
                        match.team2?.name ?? 'Team 2',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (match.team2?.logoUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(
                            match.team2!.logoUrl!,
                            height: 40,
                            width: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.sports_soccer, size: 40, color: Colors.blue);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Match status and prediction info
            if (match.isFinished) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hasil Akhir - Pemenang: ${match.winner}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.blue : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Prediksi Anda: $predictedText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        isCorrect
                            ? '✓ Prediksi Benar!'
                            : '✗ Prediksi Salah',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tidak ada prediksi untuk pertandingan ini',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Prediksi Anda:',
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
                      'Menunggu hasil pertandingan...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Buat Prediksi'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Status: ${match.status}',
              style: TextStyle(
                color: match.status == 'Belum Dimainkan' ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (match.isFinished)
              Text(
                'Pemenang: ${match.winner}',
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