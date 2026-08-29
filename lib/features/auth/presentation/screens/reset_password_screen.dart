import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.prefilledEmail,
    this.prefilledToken,
  });

  final String? prefilledEmail;
  final String? prefilledToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tokenCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefilledEmail ?? '');
    _tokenCtrl = TextEditingController(text: widget.prefilledToken ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailCtrl.text.trim(),
            token: _tokenCtrl.text.trim(),
            newPassword: _passwordCtrl.text,
          );
      if (!mounted) return;
      setState(() => _success = 'Password updated successfully! Redirecting to Sign In...');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrefilledEmail = widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/auth_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xD9070D18), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top App Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ).animate().scaleXY(begin: 0.85, duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),

                    // Frosted Glass Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title & Subtitle
                                Text(
                                  'Reset Password',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hasPrefilledEmail
                                      ? 'A reset code was sent to your email. Enter the code and your new password below.'
                                      : 'Enter your email, the code sent to you, and your new password.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Success message
                                if (_success != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _success!,
                                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(),

                                // Error message
                                if (_error != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().shake(),

                                // Email Input
                                Text(
                                  'Email Address',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  readOnly: hasPrefilledEmail,
                                  enableInteractiveSelection: true,
                                  onChanged: (_) {
                                    if (_error != null) setState(() => _error = null);
                                  },
                                  style: GoogleFonts.outfit(
                                    color: hasPrefilledEmail ? const Color(0xFF94A3B8) : Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'you@example.com',
                                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
                                    fillColor: hasPrefilledEmail
                                        ? const Color(0xFF0F172A).withOpacity(0.6)
                                        : const Color(0xFF1E293B).withOpacity(0.7),
                                    filled: true,
                                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
                                    suffixIcon: hasPrefilledEmail
                                        ? const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18)
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                    ),
                                  ),
                                  validator: (v) {
                                    final email = (v ?? '').trim();
                                    if (email.isEmpty) return 'Email is required';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Reset Code Input
                                Text(
                                  'Reset Code',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _tokenCtrl,
                                  textCapitalization: TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                  enableInteractiveSelection: true,
                                  onChanged: (_) {
                                    if (_error != null) setState(() => _error = null);
                                  },
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 123456',
                                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14, letterSpacing: 0),
                                    fillColor: const Color(0xFF1E293B).withOpacity(0.7),
                                    filled: true,
                                    prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF94A3B8), size: 20),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                    ),
                                  ),
                                  validator: (v) {
                                    if ((v ?? '').trim().isEmpty) return 'Reset code is required';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // New Password Input
                                Text(
                                  'New Password',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  enableInteractiveSelection: true,
                                  onChanged: (_) {
                                    if (_error != null) setState(() => _error = null);
                                  },
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Min. 6 characters',
                                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
                                    fillColor: const Color(0xFF1E293B).withOpacity(0.7),
                                    filled: true,
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if ((v ?? '').length < 6) return 'At least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Confirm New Password Input
                                Text(
                                  'Confirm New Password',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  enableInteractiveSelection: true,
                                  onChanged: (_) {
                                    if (_error != null) setState(() => _error = null);
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Re-enter new password',
                                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
                                    fillColor: const Color(0xFF1E293B).withOpacity(0.7),
                                    filled: true,
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                                      icon: Icon(
                                        _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Reset Password Submit Button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Reset Password',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Back to Sign In
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Back to ',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => context.go('/login'),
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF38BDF8),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
