import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        final error = context.read<AuthProvider>().errorMessage;
        _showSnack(error ?? 'Login failed', isError: true);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnack('Enter your email above first');
      return;
    }
    final success = await context
        .read<AuthProvider>()
        .sendPasswordReset(_emailCtrl.text.trim());
    if (mounted) {
      _showSnack(
        success
            ? 'Password reset email sent! Check your inbox.'
            : 'Failed to send reset email.',
        isError: !success,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // ── Logo ──────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha:0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.medical_services,
                          color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      style:
                      Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Your Emergency Medical Identity',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Heading ───────────────────────────────
              Text('Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Sign in to access your emergency profile',
                  style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: 28),

              // ── Form ──────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Email Address',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LoadingButton(
                      text: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 20),

                    // ── Sign up link ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppConstants.signupRoute),
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Emergency hint ─────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha:0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.accentColor.withValues(alpha:0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.accentColor, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Emergency responders can scan your QR without logging in.',
                              style: TextStyle(
                                  color: AppTheme.accentColor, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── No-login scan entry point ──────
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, AppConstants.scanQrRoute),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Scan an Emergency QR Code'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
