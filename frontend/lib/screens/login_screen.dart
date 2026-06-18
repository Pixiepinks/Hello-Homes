import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  Timer? _timer;
  int _secondsRemaining = 120;
  bool _canResend = false;
  bool _adminPasswordMode = false;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 120;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _canResend = true);
        }
      }
    });
  }

  void _handleSendOtp() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final errorMessage = await context.read<AuthProvider>().sendOtp(_emailController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMessage == null) {
        setState(() {
          _otpSent = true;
          _startTimer();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _handleLogin() async {
    if (_otpController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().verifyOtp(_emailController.text.trim(), _otpController.text.trim());
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        final auth = context.read<AuthProvider>();
        if (auth.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/profile');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired OTP.')));
      }
    }
  }

  void _handleAdminLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().adminLogin(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid admin credentials.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text('Welcome Back', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(_adminPasswordMode ? 'Enter admin credentials' : (_otpSent ? 'Enter OTP sent to your email' : 'Enter your email to receive an OTP'), style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                enabled: !_otpSent,
              ),
              const SizedBox(height: 16),
              if (_adminPasswordMode) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Admin Password'),
                  obscureText: true,
                ),
              ] else if (_otpSent) ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: '6-digit OTP'),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_adminPasswordMode ? _handleAdminLogin : (_otpSent ? _handleLogin : _handleSendOtp)),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_adminPasswordMode ? 'Admin Login' : (_otpSent ? 'Verify & Login' : 'Send OTP')),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _adminPasswordMode = !_adminPasswordMode;
                    _otpSent = false;
                    _otpController.clear();
                    _passwordController.clear();
                    _timer?.cancel();
                  });
                },
                child: Text(_adminPasswordMode ? 'Use email OTP login' : 'Admin password login'),
              ),
              if (_otpSent)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      Text(
                        'Time remaining: ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _secondsRemaining > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_canResend)
                        TextButton(
                          onPressed: () {
                            _otpController.clear();
                            _handleSendOtp();
                          },
                          child: const Text('Resend OTP'),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _otpSent = false;
                            _otpController.clear();
                            _timer?.cancel();
                          });
                        },
                        child: const Text('Use a different email'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
