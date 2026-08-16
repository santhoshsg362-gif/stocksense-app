import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../home/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
    _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
    TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.register(
        _nameController.text.trim(),
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ??
            'Registration failed. Please try again.';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
              CrossAxisAlignment.start,
            children: [
              const Text(
                'Join StockSense',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your free account',
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

                    // Full name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                        TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email or User ID',
                        prefixIcon: Icon(
                          Icons.person_outline),
                        hintText: 'e.g. SS123456',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
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
                          onPressed: () => setState(
                            () => _obscurePassword =
                              !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Minimum 8 characters';
                        }
                        if (!value.contains(
                            RegExp(r'[A-Z]'))) {
                          return 'Need at least one uppercase letter';
                        }
                        if (!value.contains(
                            RegExp(r'[a-z]'))) {
                          return 'Need at least one lowercase letter';
                        }
                        if (!value.contains(
                            RegExp(r'[0-9]'))) {
                          return 'Need at least one number';
                        }
                        if (!value.contains(
                            RegExp(r'[@$!%*?&#]'))) {
                          return 'Need one special character (@\$!%*?&#)';
                        }
                        return null;
                      },
                    ),

                    // Password strength indicator
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildPasswordStrength(
                          _passwordController.text),
                      ],
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller:
                        _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm =
                              !_obscureConfirm),
                        ),
                      ),
                      validator: (value) {
                        if (value !=
                            _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
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

                    // Register button
                    ElevatedButton(
                      onPressed: _isLoading ?
                        null : _register,
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () =>
                      Navigator.pop(context),
                    child: const Text(
                      'Sign In',
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

  Widget _buildPasswordStrength(String password) {
  int strength = 0;
  if (password.length >= 8) strength++;
  if (password.contains(
      RegExp(r'[A-Z]'))) strength++;
  if (password.contains(
      RegExp(r'[a-z]'))) strength++;
  if (password.contains(
      RegExp(r'[0-9]'))) strength++;
  if (password.contains(
      RegExp(r'[@$!%*?&#]'))) strength++;

  Color color;
  String label;
  if (strength <= 2) {
    color = AppTheme.red;
    label = 'Weak';
  } else if (strength <= 3) {
    color = Colors.orange;
    label = 'Medium';
  } else if (strength <= 4) {
    color = Colors.lightGreen;
    label = 'Strong';
  } else {
    color = AppTheme.green;
    label = 'Very Strong';
  }

  return Column(
    crossAxisAlignment:
      CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor:
                Colors.grey[300],
              valueColor:
                AlwaysStoppedAnimation(
                  color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}
}