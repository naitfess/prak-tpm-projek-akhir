import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'user_matches_screen.dart';
import 'user_news_screen.dart';
import 'leaderboard_screen.dart';
import '../../services/api_service.dart'; // Fix path
import '../../theme/app_colors.dart'; // Fix path

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UserMatchesScreen(),
    const UserNewsScreen(),
    const LeaderboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    verifyToken();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();
      // Debug log
      print('User after checkAuthStatus: ${authProvider.user?.username}');
    });
  }

  Future<void> verifyToken() async {
    final token = await ApiService.getToken();
    print('Dashboard token check: ${token?.substring(0, 20)}...'); // Debug log

    if (token == null || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            elevation: 2,
            shadowColor: Colors.black12,
            title: Row(
              children: [
                Icon(Icons.sports_soccer,
                    color: AppColors.textOnPrimary, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textOnPrimary.withOpacity(0.9),
                          ),
                    ),
                    Text(
                      authProvider.user?.username ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${authProvider.user?.poin ?? 0} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(CupertinoIcons.power, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () async {
                        await authProvider.logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryGreen,
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
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard),
                label: 'Leaderboard',
              ),
            ],
          ),
        );
      },
    );
  }
}
