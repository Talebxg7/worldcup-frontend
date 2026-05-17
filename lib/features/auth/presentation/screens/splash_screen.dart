import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    
    if (authState.isLoading) {
      // If still loading (e.g. slow network), check again shortly
      Future.delayed(const Duration(milliseconds: 500), _navigate);
      return;
    }

    if (authState.hasError) {
      // Likely a network timeout or parsing error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Proceeding offline if possible.')),
      );
      context.go('/login');
      return;
    }

    final user = authState.value;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final bgImage = isLandscape 
              ? 'assets/images/splash_bg_desktop.jpg' 
              : 'assets/images/splash_bg_mobile.jpg';

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    bottom: 64,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                          strokeWidth: 2,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms);
        },
      ),
    );
  }
}
