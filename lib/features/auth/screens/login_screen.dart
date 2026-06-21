import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

enum AuthMode { login, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.login;
  bool _loading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_mode == AuthMode.login) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      context.go('/chat');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordSheet() {
    final resetController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.petalWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? resetError;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset Password', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email and we\'ll send you a reset link.',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: resetController,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  if (resetError != null) ...[
                    const SizedBox(height: 8),
                    Text(resetError!,
                        style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Send Reset Link',
                    onPressed: () async {
                      try {
                        await Supabase.instance.client.auth
                            .resetPasswordForEmail(
                                resetController.text.trim());
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      } on AuthException catch (e) {
                        setSheetState(() => resetError = e.message);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // If width is greater than 800, we show the landscape layout
          if (constraints.maxWidth > 800) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side: Branding / Illustration
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.barkCream.withValues(alpha: 0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/assets/logo.png', width: 120, height: 120),
                  const SizedBox(height: 24),
                  Text('Tagar', style: AppTextStyles.logo.copyWith(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('blooming conversations', style: AppTextStyles.caption.copyWith(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
        // Right side: Login Form
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.petalWhite,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _mode == AuthMode.login ? 'Welcome Back' : 'Join Us',
                        style: AppTextStyles.h1.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == AuthMode.login 
                          ? 'Please enter your details to sign in.' 
                          : 'Create an account to start blooming conversations.',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 32),
                      _buildLoginForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('lib/assets/logo.png', width: 72, height: 72),
        const SizedBox(height: 8),
        Text('Tagar', style: AppTextStyles.logo),
        const SizedBox(height: 4),
        Text('blooming conversations', style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeToggle(),
        const SizedBox(height: 24),
        if (_mode == AuthMode.signUp) ...[
          AppTextField(
            controller: _nameController,
            hintText: 'Your name',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          const SizedBox(height: 16),
        ],
        AppTextField(
          controller: _emailController,
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          hintText: 'Password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outlined),
        ),
        if (_mode == AuthMode.signUp) ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm password',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outlined),
          ),
        ],
        if (_mode == AuthMode.login) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordSheet,
              child: Text(
                'Forgot password?',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.riverBlue,
                ),
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: _mode == AuthMode.login ? 'Sign In' : 'Create Account',
          loading: _loading,
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.barkCream,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleTab('Login', AuthMode.login),
          const SizedBox(width: 4),
          _toggleTab('Sign Up', AuthMode.signUp),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, AuthMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.leafGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.petalWhite : AppColors.earthBrown,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
