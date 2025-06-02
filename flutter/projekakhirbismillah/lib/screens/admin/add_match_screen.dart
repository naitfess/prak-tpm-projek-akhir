import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../models/team.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green[700]!;
    final Color bgColor = Colors.green[50]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Add Match'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<MatchProvider>(
        builder: (context, matchProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<Team>(
                    decoration: InputDecoration(
                      labelText: 'Team 1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: bgColor,
                    ),
                    value: _selectedTeam1,
                    items: matchProvider.teams.map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTeam1 = value;
                        // Reset team 2 if it's the same as team 1
                        if (_selectedTeam2 == value) {
                          _selectedTeam2 = null;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select Team 1';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<Team>(
                    decoration: InputDecoration(
                      labelText: 'Team 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: bgColor,
                    ),
                    value: _selectedTeam2,
                    items: matchProvider.teams
                        .where((team) =>
                            team !=
                            _selectedTeam1) // Filter out selected team 1
                        .map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTeam2 = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select Team 2';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final matchData = {
                            'team1_id': _selectedTeam1!.id,
                            'team2_id': _selectedTeam2!.id,
                            'date':
                                _selectedDate.toIso8601String().split('T')[0],
                            'time':
                                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          };

                          final success =
                              await matchProvider.createMatch(matchData);
                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Match created successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to create match')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text('Create Match',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          )),
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
