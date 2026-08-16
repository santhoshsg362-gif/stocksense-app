import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_theme.dart';
import '../../config/constants.dart';

class ForgotPasswordScreen
    extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState()
      => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl =
    TextEditingController();
  final _confirmPassCtrl =
    TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  String? _error;
  String? _success;
  bool _obscurePass = true;

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}'
          '/auth/forgot-password'),
        headers: {
          'Content-Type':
            'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
        }),
      );
      final data =
        jsonDecode(response.body);
      if (data['message'] != null) {
        setState(() {
          _otpSent = true;
          _success = data['message'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message']
            ?? 'Failed to send OTP';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text !=
        _confirmPassCtrl.text) {
      setState(() =>
        _error = 'Passwords do not match');
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      setState(() =>
        _error =
          'Password must be at least '
          '8 characters');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}'
          '/auth/reset-password'),
        headers: {
          'Content-Type':
            'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'otp': _otpCtrl.text.trim(),
          'newPassword':
            _newPassCtrl.text,
        }),
      );
      final data =
        jsonDecode(response.body);
      if (data.containsKey('token')) {
        setState(() {
          _success =
            'Password reset successful!';
          _isLoading = false;
        });
        await Future.delayed(
          const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          _error = data['message']
            ?? 'Reset failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
            CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue
                    .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 40,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                ? 'Enter the OTP and your '
                  'new password'
                : 'Enter your registered '
                  'email to receive an OTP',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Error/Success messages
            if (_error != null)
              Container(
                padding:
                  const EdgeInsets.all(12),
                margin: const EdgeInsets
                  .only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.red
                    .withOpacity(0.1),
                  borderRadius:
                    BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppTheme.red),
                ),
              ),
            if (_success != null)
              Container(
                padding:
                  const EdgeInsets.all(12),
                margin: const EdgeInsets
                  .only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.green
                    .withOpacity(0.1),
                  borderRadius:
                    BorderRadius.circular(8),
                ),
                child: Text(
                  _success!,
                  style: const TextStyle(
                    color: AppTheme.green),
                ),
              ),

            // Email field
            TextFormField(
              controller: _emailCtrl,
              enabled: !_otpSent,
              keyboardType:
                TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(
                  Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            if (!_otpSent)
              ElevatedButton(
                onPressed: _isLoading
                  ? null : _sendOtp,
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                    )
                  : const Text('Send OTP'),
              ),

            if (_otpSent) ...[
              // OTP field
              TextFormField(
                controller: _otpCtrl,
                keyboardType:
                  TextInputType.number,
                decoration:
                  const InputDecoration(
                  labelText: 'Enter OTP',
                  prefixIcon: Icon(
                    Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // New password
              TextFormField(
                controller: _newPassCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                    ),
                    onPressed: () =>
                      setState(() =>
                        _obscurePass =
                          !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: true,
                decoration:
                  const InputDecoration(
                  labelText:
                    'Confirm New Password',
                  prefixIcon: Icon(
                    Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading
                  ? null
                  : _resetPassword,
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                    )
                  : const Text(
                      'Reset Password'),
              ),

              const SizedBox(height: 16),

              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: () => setState(
                    () {
                    _otpSent = false;
                    _success = null;
                    _error = null;
                  }),
                  child: const Text(
                    'Resend OTP'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}