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
      return Text(flag.isEmpty ? '🏳️' : flag, style: TextStyle(fontSize: size));
    }

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Text('🏳️', style: TextStyle(fontSize: size * 0.7)),
            ),
          );
        },
      ),
    );
  }
}

