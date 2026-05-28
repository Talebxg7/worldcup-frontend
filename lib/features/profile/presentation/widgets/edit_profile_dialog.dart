import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Country options for profile (Firestore `country` field).
const List<String> kProfileCountryOptions = [
  'Jordan',
  'Egypt',
  'Spain',
  'Portugal',
  'France',
  'Germany',
  'Brazil',
  'Argentina',
  'England',
  'Morocco',
  'Saudi Arabia',
];

/// Edit username + country; persists to `users/{uid}`.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.uid,
    required this.initialUsername,
    required this.initialCountry,
    required this.initialHideUsername,
  });

  final String uid;
  final String initialUsername;
  final String initialCountry;
  final bool initialHideUsername;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _usernameCtrl;
  late String _country;
  late bool _hideUsername;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername);
    final c = widget.initialCountry.trim();
    _country = kProfileCountryOptions.contains(c) ? c : kProfileCountryOptions.first;
    _hideUsername = widget.initialHideUsername;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _usernameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 1. Update Node.js Postgres Backend first (this verifies uniqueness!)
      final currentAvatar = ref.read(authStateProvider).value?.avatarUrl ?? '';
      await ref.read(authStateProvider.notifier).updateProfile(
            username: name,
            avatarUrl: currentAvatar,
            hideUsername: _hideUsername,
          );

      // 2. Only if the backend update succeeds, update Firebase Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set(
        {
          'username': name,
          'country': _country,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      
      // Clean up the error message for the user
      String errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('taken') || errorMsg.toLowerCase().contains('already')) {
        errorMsg = 'Username is already taken';
      } else if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $errorMsg'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.darkSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit profile',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _usernameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: const InputDecoration(
                  labelText: 'Country',
                ),
                isExpanded: true,
                items: kProfileCountryOptions
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _country = val);
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkTextSecondary,
                        side: const BorderSide(color: AppColors.darkBorder),
                        backgroundColor: AppColors.darkCard,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
