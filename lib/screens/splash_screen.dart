import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown briefly while the app connects to Supabase and restores the
/// current match. This is the *Flutter-level* splash — the native splash
/// (configured via flutter_native_splash in pubspec.yaml) is what the
/// user sees for the instant before the Flutter engine itself starts;
/// this one bridges the gap between that and the first real screen so
/// there's no flash of a blank/plain loading spinner.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Opacity(
                opacity: _pulse.value,
                child: Transform.scale(scale: _pulse.value, child: child),
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.45),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Image.asset('assets/splash/splash_logo.png'),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '🏏 CRICKET SCOREBOARD',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Connecting to Supabase...',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}