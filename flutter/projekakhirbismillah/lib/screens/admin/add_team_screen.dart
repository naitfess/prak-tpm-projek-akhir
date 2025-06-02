import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green[700]!;
    final Color bgColor = Colors.green[50]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Add Team'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.sports_soccer),
                  filled: true,
                  fillColor: bgColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter team name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _logoUrlController,
                decoration: InputDecoration(
                  labelText: 'Logo URL (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.image),
                  filled: true,
                  fillColor: bgColor,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final matchProvider =
                          Provider.of<MatchProvider>(context, listen: false);

                      final success = await matchProvider.createTeam(
                        _nameController.text,
                        _logoUrlController.text.isEmpty
                            ? null
                            : _logoUrlController.text,
                      );

                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Team created successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to create team')),
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
                  child: const Text('Create Team',
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
      ),
    );
  }
}
