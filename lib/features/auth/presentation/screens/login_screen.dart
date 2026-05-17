import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authStateProvider.notifier).login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authStateProvider.notifier).googleLogin();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
              // Hero Header
              Container(
                height: size.height * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF006633), Color(0xFF004499)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ).animate().scaleXY(begin: 0.8, duration: 500.ms, curve: Curves.elasticOut),
                      ],
                    ),
                  ),
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Welcome Back! 👋',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().slideX(begin: -0.2, duration: 400.ms, delay: 200.ms)
                            .fadeIn(duration: 300.ms, delay: 200.ms),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue your predictions',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!,
                                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                                ),
                              ],
                            ),
                          ).animate().shake(),

                        // Username field
                        TextFormField(
                          controller: _usernameCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            hintText: 'Enter your username',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Username is required';
                            if (v.trim().length < 3) return 'At least 3 characters';
                            return null;
                          },
                        ).animate().slideX(begin: -0.2, duration: 400.ms, delay: 350.ms)
                            .fadeIn(duration: 300.ms, delay: 350.ms),

                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                        ).animate().slideX(begin: -0.2, duration: 400.ms, delay: 400.ms)
                            .fadeIn(duration: 300.ms, delay: 400.ms),

                        const SizedBox(height: 28),

                        // Login button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                          ),
                        ).animate().slideY(begin: 0.3, duration: 400.ms, delay: 450.ms)
                            .fadeIn(duration: 300.ms, delay: 450.ms),

                        const SizedBox(height: 24),

                        // OR divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ).animate().fadeIn(duration: 300.ms, delay: 480.ms),

                        const SizedBox(height: 24),

                        // Google Sign In button
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _googleLogin,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.white),
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ).animate().slideY(begin: 0.3, duration: 400.ms, delay: 500.ms).fadeIn(duration: 300.ms, delay: 500.ms),

                        const SizedBox(height: 16),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : () => context.go('/forgot-password'),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),



                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ),
    );
  }
}
