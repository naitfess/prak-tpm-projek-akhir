import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<void> _submit() async {
    if (_selectedTeamId == null) return;
    setState(() => _isLoading = true);

    final predictionProvider = Provider.of<PredictionProvider>(context, listen: false);
    final success = await predictionProvider.createPrediction(
      widget.match.id,
      _selectedTeamId!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Prediksi berhasil disimpan!' : (predictionProvider.errorMessage ?? 'Gagal menyimpan prediksi')),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team1 = widget.match.team1;
    final team2 = widget.match.team2;
    
    return AlertDialog(
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
            
            // Tim 1 Menang
            _buildPredictionOption(
              title: '${team1?.name ?? 'Tim 1'} Menang',
              icon: Icons.sports_soccer,
              color: Colors.blue,
              isSelected: _selectedOption == 'team1',
              onTap: () => setState(() {
                _selectedTeamId = team1?.id;
                _selectedOption = 'team1';
              }),
            ),
            
            const SizedBox(height: 12),
            
            // Seri
            _buildPredictionOption(
              title: 'Hasil Seri',
              icon: Icons.handshake,
              color: Colors.orange,
              isSelected: _selectedOption == 'draw',
              onTap: () => setState(() {
                _selectedTeamId = 0;
                _selectedOption = 'draw';
              }),
            ),
            
            const SizedBox(height: 12),
            
            // Tim 2 Menang
            _buildPredictionOption(
              title: '${team2?.name ?? 'Tim 2'} Menang',
              icon: Icons.sports_soccer,
              color: Colors.green,
              isSelected: _selectedOption == 'team2',
              onTap: () => setState(() {
                _selectedTeamId = team2?.id;
                _selectedOption = 'team2';
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
                child: Row(
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
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Prediksi'),
        ),
      ],
    );
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
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
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
}
