import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../models/match_schedule.dart';
import '../../models/team.dart';

class EditMatchScreen extends StatefulWidget {
  final MatchSchedule match;

  const EditMatchScreen({super.key, required this.match});

  @override
  State<EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends State<EditMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skor1Controller = TextEditingController();
  final _skor2Controller = TextEditingController();
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _skor1Controller.text = widget.match.skor1?.toString() ?? '';
    _skor2Controller.text = widget.match.skor2?.toString() ?? '';
    _selectedDate = widget.match.date;
    _selectedTime = TimeOfDay(
      hour: int.parse(widget.match.time.split(':')[0]),
      minute: int.parse(widget.match.time.split(':')[1]),
    );
  }

  @override
  void dispose() {
    _skor1Controller.dispose();
    _skor2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Match'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MatchProvider>(
        builder: (context, matchProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '${widget.match.team1?.name ?? 'Team 1'} vs ${widget.match.team2?.name ?? 'Team 2'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.match.date.day}/${widget.match.date.month}/${widget.match.date.year} - ${widget.match.time}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text(
                            'Match Status Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.match.isFinished 
                                ? 'Match is finished. Current result: ${widget.match.result}'
                                : 'Match is upcoming. Enter scores to finish the match.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Update Match Score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skor1Controller,
                          decoration: InputDecoration(
                            labelText: '${widget.match.team1?.name ?? 'Team 1'} Score',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter score';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '-',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _skor2Controller,
                          decoration: InputDecoration(
                            labelText: '${widget.match.team2?.name ?? 'Team 2'} Score',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter score';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final score1 = int.parse(_skor1Controller.text);
                          final score2 = int.parse(_skor2Controller.text);
                          
                          final matchData = {
                            'skor1': score1,
                            'skor2': score2,
                          };

                          final success = await matchProvider.updateMatch(
                            widget.match.id,
                            matchData,
                          );

                          if (success) {
                            Navigator.pop(context);
                            String resultMessage;
                            if (score1 > score2) {
                              resultMessage = 'Match completed! Winner: ${widget.match.team1?.name ?? 'Team 1'}';
                            } else if (score2 > score1) {
                              resultMessage = 'Match completed! Winner: ${widget.match.team2?.name ?? 'Team 2'}';
                            } else {
                              resultMessage = 'Match completed! Result: Draw';
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(resultMessage)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update match')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(widget.match.isFinished ? 'Update Match Result' : 'Finish Match'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
