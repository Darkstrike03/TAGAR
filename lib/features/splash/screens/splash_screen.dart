import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    // Increased duration by 2 seconds (3.5s + 2s = 5.5s)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // Subtle scale up
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    // Smooth fade in
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.4, curve: Curves.easeIn),
      ),
    );

    // To keep the top petal at the top for a 5-star flower, 
    // we rotate exactly 1 full turn (1.0) or increments of 1/5 (0.2).
    // Using 1.0 for a complete, elegant slow revolution.
    _rotationAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToAuth();
      }
    });
  }

  Future<void> _navigateToAuth() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final prefs = await SharedPreferences.getInstance();
      final pendingName = prefs.getString('pending_name');
      if (pendingName != null) {
        await Supabase.instance.client.from('user_data').update({
          'profile_name': pendingName,
          'username': pendingName,
        }).eq('id', session.user.id);
        await prefs.remove('pending_name');
      }
      if (!mounted) return;
      context.go('/chat');
    } else {
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with full 360-degree rotation to preserve orientation
                RotationTransition(
                  turns: _rotationAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'lib/assets/logo.png',
                      width: 130, // Slightly larger for better impact
                      height: 130,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'TAGAR',
                  style: AppTextStyles.logo.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: 0.6,
                  child: Text(
                    'blooming conversations',
                    style: AppTextStyles.caption.copyWith(
                      letterSpacing: 2.0,
                      fontStyle: FontStyle.italic,
                    ),
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
