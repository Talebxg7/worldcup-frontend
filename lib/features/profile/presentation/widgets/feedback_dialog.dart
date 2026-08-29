import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const FeedbackDialog(),
    );
  }

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _textCtrl = TextEditingController();
  String _selectedCategory = 'Feature Request';
  int _rating = 5;
  bool _isSubmitting = false;
  String? _error;
  bool _submitted = false;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Feature Request', 'icon': Icons.lightbulb_outline_rounded, 'emoji': '💡'},
    {'name': 'Bug Report', 'icon': Icons.bug_report_outlined, 'emoji': '🐛'},
    {'name': 'UI & Design', 'icon': Icons.palette_outlined, 'emoji': '🎨'},
    {'name': 'Performance', 'icon': Icons.bolt_rounded, 'emoji': '⚡'},
    {'name': 'General', 'icon': Icons.chat_bubble_outline_rounded, 'emoji': '💬'},
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please enter your feedback before sending.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.id ?? 'anonymous',
        'username': user?.username ?? 'Anonymous User',
        'email': user?.email ?? '',
        'category': _selectedCategory,
        'rating': _rating,
        'message': text,
        'platform': kIsWeb ? 'Web' : defaultTargetPlatform.name,
        'createdAt': FieldValue.serverTimestamp(),
        'dateString': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _submitted = true);
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to submit feedback. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final fieldBg = isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF8FAFC);

    return Dialog(
      backgroundColor: bgColor,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _submitted
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Thank You!',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your feedback helps make WhoWillWin even better.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.feedback_outlined,
                              color: Color(0xFF38BDF8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send Feedback',
                                  style: GoogleFonts.outfit(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Tell us what you'd like to see or report an issue",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: secondaryTextColor, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category Selector
                      Text(
                        'Category',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['name'];
                          return InkWell(
                            onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3B82F6)
                                      : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat['emoji'] as String, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat['name'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Rating Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'How is your experience?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              final starValue = index + 1;
                              return InkWell(
                                onTap: () => setState(() => _rating = starValue),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                  child: Icon(
                                    starValue <= _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: starValue <= _rating
                                        ? const Color(0xFFF59E0B)
                                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                    size: 24,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Textarea with NameThatUI Size Grip Indicator
                      Text(
                        'Feedback Details',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            TextFormField(
                              controller: _textCtrl,
                              minLines: 4,
                              maxLines: 7,
                              maxLength: 500,
                              enableInteractiveSelection: true,
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
                              },
                              style: GoogleFonts.outfit(
                                color: textColor,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: "The export button is hard to find, or I'd love to see a tournament predictor bracket...",
                                hintStyle: GoogleFonts.outfit(
                                  color: secondaryTextColor.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                counterStyle: GoogleFonts.outfit(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            // NameThatUI Size Grip (Diagonal lines resize handle) in bottom-right corner
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: IgnorePointer(
                                child: CustomPaint(
                                  size: const Size(12, 12),
                                  painter: _SizeGripPainter(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error Banner
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              foregroundColor: secondaryTextColor,
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, size: 16),
                            label: Text(
                              _isSubmitting ? 'Sending...' : 'Send Feedback',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
    );
  }
}

/// Custom painter that draws the classic 3 diagonal ribs resize handle (size grip)
class _SizeGripPainter extends CustomPainter {
  final Color color;
  const _SizeGripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Line 1 (smallest corner line)
    canvas.drawLine(
      Offset(size.width - 2, size.height - 8),
      Offset(size.width - 8, size.height - 2),
      paint,
    );

    // Line 2 (middle line)
    canvas.drawLine(
      Offset(size.width - 2, size.height - 5),
      Offset(size.width - 5, size.height - 2),
      paint,
    );

    // Line 3 (outermost tiny dot/line)
    canvas.drawLine(
      Offset(size.width - 2, size.height - 2),
      Offset(size.width - 2, size.height - 2),
      paint..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SizeGripPainter oldDelegate) => oldDelegate.color != color;
}
