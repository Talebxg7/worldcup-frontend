import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When enabled, the router allows navigating the app without auth.
final demoModeProvider = StateProvider<bool>((ref) => false);

