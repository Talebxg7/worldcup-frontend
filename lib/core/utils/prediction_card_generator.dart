import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RoomPredictionItemData {
  final String username;
  final int? homeScore;
  final int? awayScore;
  final bool hidden;
  final int? pointsEarned;
  final bool? joker;
  final bool? redCard;
  final bool? penalty;

  RoomPredictionItemData({
    required this.username,
    this.homeScore,
    this.awayScore,
    this.hidden = false,
    this.pointsEarned,
    this.joker,
    this.redCard,
    this.penalty,
  });
}

class PredictionCardGenerator {
  static Future<Uint8List> generateMatchPredictionImage({
    required String roomName,
    required String joinCode,
    required String homeTeam,
    required String awayTeam,
    String? status,
    int? actualHomeScore,
    int? actualAwayScore,
    required List<RoomPredictionItemData> predictions,
  }) async {
    const double width = 800.0;
    const double padding = 32.0;
    const double contentWidth = width - (padding * 2);

    final bool isFinished = status == 'finished' && actualHomeScore != null && actualAwayScore != null;

    final double headerHeight = 90.0;
    final double matchBoxHeight = isFinished ? 120.0 : 100.0;
    final double sectionTitleHeight = 36.0;
    final double rowHeight = 56.0;
    final double rowsHeight = predictions.isEmpty ? 56.0 : (predictions.length * rowHeight);
    final double footerHeight = 60.0;

    final double totalHeight = padding + headerHeight + matchBoxHeight + sectionTitleHeight + rowsHeight + footerHeight + padding;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, totalHeight));

    // 1. Outer Card Background (Navy Gradient)
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(width, totalHeight),
        [const Color(0xFF0F172A), const Color(0xFF1E293B)],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, totalHeight), const Radius.circular(24)),
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, totalHeight), const Radius.circular(24)),
      borderPaint,
    );

    // Top Gold Accent Line
    final accentPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(0, 0, width, 8),
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
      ),
      accentPaint,
    );

    double currentY = padding + 10;

    // 2. Header: App Name & Room Info
    _drawText(
      canvas,
      text: 'WHO WILL WIN',
      offset: Offset(padding, currentY),
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD700),
      letterSpacing: 2.0,
    );

    _drawText(
      canvas,
      text: '$roomName  •  Code: $joinCode',
      offset: Offset(padding, currentY + 30),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    );

    currentY += headerHeight;

    // 3. Match Banner Box
    final matchBoxRect = Rect.fromLTWH(padding, currentY, contentWidth, matchBoxHeight);
    final matchBoxBg = Paint()
      ..shader = ui.Gradient.linear(
        Offset(padding, currentY),
        Offset(padding + contentWidth, currentY + matchBoxHeight),
        [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      );
    canvas.drawRRect(RRect.fromRectAndRadius(matchBoxRect, const Radius.circular(16)), matchBoxBg);
    canvas.drawRRect(RRect.fromRectAndRadius(matchBoxRect, const Radius.circular(16)), borderPaint);

    // Match Title: Home vs Away
    final matchTitle = '$homeTeam  VS  $awayTeam';
    _drawTextCentered(
      canvas,
      text: matchTitle,
      center: Offset(width / 2, currentY + 36),
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    if (isFinished) {
      _drawTextCentered(
        canvas,
        text: 'Final Score: $actualHomeScore - $actualAwayScore',
        center: Offset(width / 2, currentY + 80),
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF4ADE80),
      );
    }

    currentY += matchBoxHeight + 16;

    // 4. Predictions Header
    _drawText(
      canvas,
      text: 'ROOM MEMBER PREDICTIONS',
      offset: Offset(padding, currentY),
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF94A3B8),
      letterSpacing: 1.2,
    );

    currentY += sectionTitleHeight;

    // 5. Prediction Rows
    if (predictions.isEmpty) {
      _drawText(
        canvas,
        text: 'No predictions recorded for this match yet.',
        offset: Offset(padding + 16, currentY + 12),
        fontSize: 15,
        color: const Color(0xFF64748B),
      );
      currentY += 56;
    } else {
      for (int i = 0; i < predictions.length; i++) {
        final p = predictions[i];
        final rowRect = Rect.fromLTWH(padding, currentY, contentWidth, 48);

        final rowBg = Paint()..color = const Color(0xFF1E293B);
        canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(12)), rowBg);

        // Avatar Circle
        final circleCenter = Offset(padding + 22, currentY + 24);
        final avatarPaint = Paint()..color = const Color(0xFF3B82F6);
        canvas.drawCircle(circleCenter, 13, avatarPaint);

        final initial = p.username.isNotEmpty ? p.username[0].toUpperCase() : '?';
        _drawTextCentered(
          canvas,
          text: initial,
          center: circleCenter,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        // Username
        _drawText(
          canvas,
          text: p.username,
          offset: Offset(padding + 44, currentY + 13),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        // Prediction Score
        final predText = p.hidden ? 'Hidden' : '${p.homeScore ?? '-'} - ${p.awayScore ?? '-'}';
        _drawText(
          canvas,
          text: predText,
          offset: Offset(padding + 200, currentY + 13),
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFF1F5F9),
        );

        // Badges
        double badgeX = padding + 320;
        if (!p.hidden) {
          if (p.joker == true) {
            badgeX += _drawBadge(canvas, text: 'JOKER', x: badgeX, y: currentY + 14, bg: const Color(0xFFF59E0B), fg: Colors.black);
          }
          if (p.redCard == true) {
            badgeX += _drawBadge(canvas, text: 'RED CARD', x: badgeX, y: currentY + 14, bg: const Color(0xFFDC2626), fg: Colors.white);
          }
          if (p.penalty == true) {
            badgeX += _drawBadge(canvas, text: 'PENALTY', x: badgeX, y: currentY + 14, bg: const Color(0xFF2563EB), fg: Colors.white);
          }
        }

        // Points Earned Pill (Right Aligned)
        if (p.pointsEarned != null) {
          final ptsText = '${p.pointsEarned! >= 0 ? '+' : ''}${p.pointsEarned} pts';
          final Color ptsBg = p.pointsEarned! > 0 ? const Color(0xFF166534) : (p.pointsEarned! < 0 ? const Color(0xFF991B1B) : const Color(0xFF334155));
          final Color ptsFg = p.pointsEarned! > 0 ? const Color(0xFF86EFAC) : (p.pointsEarned! < 0 ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1));

          _drawPillRightAligned(
            canvas,
            text: ptsText,
            rightX: padding + contentWidth - 12,
            centerY: currentY + 24,
            bg: ptsBg,
            fg: ptsFg,
          );
        }

        currentY += rowHeight;
      }
    }

    currentY += 8;

    // 6. Footer
    final linePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(padding, currentY), Offset(padding + contentWidth, currentY), linePaint);

    currentY += 14;
    _drawTextCentered(
      canvas,
      text: 'Predict matches & compete with friends on whowillwinapp.com',
      center: Offset(width / 2, currentY + 10),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF64748B),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    required Color color,
    double? letterSpacing,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  static void _drawTextCentered(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  static double _drawBadge(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required Color bg,
    required Color fg,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    final badgeWidth = tp.width + 10;
    final badgeRect = Rect.fromLTWH(x, y, badgeWidth, 18);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)), Paint()..color = bg);
    tp.paint(canvas, Offset(x + 5, y + 2.5));
    return badgeWidth + 6;
  }

  static void _drawPillRightAligned(
    Canvas canvas, {
    required String text,
    required double rightX,
    required double centerY,
    required Color bg,
    required Color fg,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    final pillWidth = tp.width + 14;
    final pillHeight = 22.0;
    final pillRect = Rect.fromLTWH(rightX - pillWidth, centerY - (pillHeight / 2), pillWidth, pillHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(11)), Paint()..color = bg);
    tp.paint(canvas, Offset(rightX - pillWidth + 7, centerY - (tp.height / 2)));
  }
}
