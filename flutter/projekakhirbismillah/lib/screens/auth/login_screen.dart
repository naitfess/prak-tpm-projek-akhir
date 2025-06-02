import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard.dart';
import '../user/user_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.clearError(); // Clear previous errors

      final success = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        if (authProvider.user?.role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboard()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ??
                'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green[700]!;
    final Color accentGreen = Colors.green[400]!;
    final Color bgColor = Colors.green[50]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(18),
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Football Prediction App',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: bgColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: bgColor,
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor: accentGreen,
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    )),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                              "Don't have an account? Register here"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
