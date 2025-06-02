import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'admin_matches_screen.dart';
import 'admin_news_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminMatchesScreen(),
    const AdminNewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 4,
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text('Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
      ),
    );
  }
}
