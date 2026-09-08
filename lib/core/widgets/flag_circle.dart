import 'package:flutter/material.dart';

class FlagCircle extends StatelessWidget {
  final String flag;
  final double size;

  const FlagCircle({
    super.key,
    required this.flag,
    required this.size,
  });

  String? _toUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.length == 2) return 'https://flagfeed.com/country/${v.toLowerCase()}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _toUrl(flag);
    if (url == null) {
      return ClipOval(
        child: Image.asset(
          'assets/images/default_club_placeholder.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default_club_placeholder.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
