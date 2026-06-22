import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/password_strength_bar.dart';

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

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _nameError;

  bool _showConfirmation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _nameError = null;
    });

    var valid = true;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = 'Email is required';
      valid = false;
    } else if (!_validateEmail(email)) {
      _emailError = 'Enter a valid email address';
      valid = false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = 'Password is required';
      valid = false;
    } else if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
      valid = false;
    } else if (!password.contains(RegExp(r'[a-zA-Z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      _passwordError = 'Password must include both letters and numbers';
      valid = false;
    }

    if (_mode == AuthMode.signUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Name is required';
        valid = false;
      }

      final confirm = _confirmPasswordController.text;
      if (confirm != password) {
        _confirmPasswordError = 'Passwords do not match';
        valid = false;
      }
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

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
        if (!mounted) return;
        context.go('/chat');
      } else {
        final name = _nameController.text.trim();
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'profile_name': name, 'username': name},
        );

        if (response.session != null) {
          await Supabase.instance.client.from('user_data').update({
            'profile_name': name,
            'username': name,
          }).eq('id', response.user!.id);

          if (!mounted) return;
          context.go('/chat');
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_name', name);

          if (!mounted) return;
          setState(() => _showConfirmation = true);
        }
      }
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
    if (_showConfirmation) {
      return _buildConfirmationScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
    );
  }

  Widget _buildConfirmationScreen() {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('lib/assets/logo.png', width: 80, height: 80),
              const SizedBox(height: 24),
              Text('Check Your Email', style: AppTextStyles.h1),
              const SizedBox(height: 12),
              Text(
                'We sent a confirmation link to\n${_emailController.text.trim()}',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link to verify your account, then sign in.',
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to Sign In',
                onPressed: () {
                  setState(() {
                    _showConfirmation = false;
                    _mode = AuthMode.login;
                  });
                },
              ),
            ],
          ),
        ),
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
                  Text('Tagar',
                      style: AppTextStyles.logo.copyWith(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('blooming conversations',
                      style:
                          AppTextStyles.caption.copyWith(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.petalWhite,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                hintText: 'Your name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(_nameError!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _emailController,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_emailError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outlined),
            ),
            if (_mode == AuthMode.signUp)
              PasswordStrengthBar(password: _passwordController.text),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_passwordError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ),
          ],
        ),
        if (_mode == AuthMode.signUp) ...[
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm password',
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
              if (_confirmPasswordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(_confirmPasswordError!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),
            ],
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
      onTap: () {
        setState(() {
          _mode = mode;
          _emailError = null;
          _passwordError = null;
          _confirmPasswordError = null;
          _nameError = null;
          _error = null;
        });
      },
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
