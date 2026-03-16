import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/cosmic_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)));
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.checkAuth();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(loggedIn ? '/home' : '/auth');
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _fadeIn.value,
              child: Transform.scale(scale: _scale.value, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                    boxShadow: [BoxShadow(color: CosmicTheme.starGold.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 56, color: Color(0xFF0A0E1A)),
                ),
                const SizedBox(height: 32),
                Text('JYOTISH AI', style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  letterSpacing: 6, color: CosmicTheme.starGold, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Vedic Astrology Intelligence', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CosmicTheme.moonSilver.withOpacity(0.7), letterSpacing: 3)),
                const SizedBox(height: 48),
                SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: CosmicTheme.starGold.withOpacity(0.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
