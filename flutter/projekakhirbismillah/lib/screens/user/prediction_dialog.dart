import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/prediction_provider.dart';
import '../../models/match_schedule.dart';

class PredictionDialog extends StatefulWidget {
  final MatchSchedule match;
  const PredictionDialog({super.key, required this.match});

  @override
  State<PredictionDialog> createState() => _PredictionDialogState();
}

class _PredictionDialogState extends State<PredictionDialog> {
  int? _selectedTeamId;
  String? _selectedOption;
  bool _isLoading = false;

  // Method untuk mendapatkan predicted_team_id yang benar
  int? _getPredictedTeamId() {
    switch (_selectedOption) {
      case 'team1':
        return widget.match.team1?.id; // ID tim 1
      case 'draw':
        return 0; // Seri
      case 'team2':
        return widget.match.team2?.id; // ID tim 2
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final team1 = widget.match.team1;
    final team2 = widget.match.team2;
    final Color bgColor = Colors.green[50]!;
    final Color primaryGreen = Colors.green[700]!;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Pilih Prediksi',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${team1?.name ?? 'Tim 1'} vs ${team2?.name ?? 'Tim 2'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildPredictionOption(
              title: '${team1?.name ?? 'Tim 1'} Menang',
              icon: Icons.sports_soccer,
              color: Colors.blue,
              isSelected: _selectedOption == 'team1',
              onTap: () => setState(() {
                _selectedOption = 'team1';
                _selectedTeamId = _getPredictedTeamId();
              }),
            ),
            const SizedBox(height: 12),
            _buildPredictionOption(
              title: 'Hasil Seri',
              icon: Icons.handshake,
              color: Colors.orange,
              isSelected: _selectedOption == 'draw',
              onTap: () => setState(() {
                _selectedOption = 'draw';
                _selectedTeamId = _getPredictedTeamId();
              }),
            ),
            const SizedBox(height: 12),
            _buildPredictionOption(
              title: '${team2?.name ?? 'Tim 2'} Menang',
              icon: Icons.sports_soccer,
              color: primaryGreen,
              isSelected: _selectedOption == 'team2',
              onTap: () => setState(() {
                _selectedOption = 'team2';
                _selectedTeamId = _getPredictedTeamId();
              }),
            ),
            if (_selectedOption != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Prediksi: ${_getSelectedText()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'predicted_team_id: $_selectedTeamId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: (_selectedTeamId == null || _isLoading) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Prediksi'),
        ),
      ],
    );
  }

  String _getSelectedText() {
    switch (_selectedOption) {
      case 'team1':
        return '${widget.match.team1?.name ?? 'Tim 1'} Menang';
      case 'draw':
        return 'Hasil Seri';
      case 'team2':
        return '${widget.match.team2?.name ?? 'Tim 2'} Menang';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (_selectedTeamId == null) return;

    // Debug: Show detailed prediction info
    String predictionType = _getSelectedText();
    print('=== SUBMITTING PREDICTION ===');
    print('Prediction Type: $predictionType');
    print('Selected Option: $_selectedOption');
    print('Predicted Team ID: $_selectedTeamId');
    print('Match ID: ${widget.match.id}');
    print(
        'Team1: ID=${widget.match.team1?.id}, Name="${widget.match.team1?.name}"');
    print(
        'Team2: ID=${widget.match.team2?.id}, Name="${widget.match.team2?.name}"');

    // Validate predicted_team_id logic
    if (_selectedOption == 'team1' &&
        _selectedTeamId != widget.match.team1?.id) {
      print('ERROR: Team1 selection mismatch!');
      return;
    } else if (_selectedOption == 'team2' &&
        _selectedTeamId != widget.match.team2?.id) {
      print('ERROR: Team2 selection mismatch!');
      return;
    } else if (_selectedOption == 'draw' && _selectedTeamId != 0) {
      print('ERROR: Draw selection should be 0!');
      return;
    }
    print('Validation passed!');
    print('============================');

    // Check token availability
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make predictions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final predictionProvider =
          Provider.of<PredictionProvider>(context, listen: false);
      final success = await predictionProvider.createPrediction(
        widget.match.id,
        _selectedTeamId!,
      );

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prediction saved: $predictionType'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                predictionProvider.errorMessage ?? 'Failed to save prediction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPredictionOption({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
