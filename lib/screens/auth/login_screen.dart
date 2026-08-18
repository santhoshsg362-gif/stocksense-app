import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';
import '../../services/google_auth_service.dart';
import '../home/main_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.containsKey('token')) {
        if (!mounted) return;
        await context.read<AuthProvider>().saveAuth(
          response['token'],
          response['email'],
          response['fullName'],
          userId: response['userId'],
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen()),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ??
            'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
          'Cannot connect to server. Make sure '
          'the backend is running.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness ==
      Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ── Logo and title ──────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius:
                          BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.candlestick_chart,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'StockSense',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-Powered Portfolio Tracker',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Form ────────────────────────────────────
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                        TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email or User ID',
                        prefixIcon: Icon(
                          Icons.person_outline),
                        hintText:
                          'Enter email or SS123456',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your '
                            'email or User ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() =>
                            _obscurePassword =
                              !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                const ForgotPasswordScreen()),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.red
                            .withOpacity(0.1),
                          borderRadius:
                            BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.red
                              .withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.red,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading ?
                        null : _login,
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider()),
                        Padding(
                          padding:
                            const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(
                          child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Google Sign-In button
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        try {
                          final response = await
                            GoogleAuthService.signIn();

                          if (response == null) {
                            // User cancelled
                            setState(() =>
                              _isLoading = false);
                            return;
                          }

                          if (response.containsKey('token')) {
                            if (!mounted) return;
                            await context.read<AuthProvider>()
                              .saveAuth(
                                response['token'],
                                response['email'],
                                response['fullName'],
                                userId: response['userId'],
                              );
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                  const MainScreen()),
                            );
                          } else {
                            setState(() {
                              _errorMessage =
                                response['message'] ??
                                'Google Sign-In failed';
                              _isLoading = false;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = e.toString()
                              .replaceAll('Exception: ', '');
                            _isLoading = false;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.g_mobiledata, size: 24),
                      label: const Text(
                        'Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                            BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Register link
              Row(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                          const RegisterScreen()),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}