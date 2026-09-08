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
    String? leagueName,
    required String homeTeam,
    required String awayTeam,
    ui.Image? homeLogoImage,
    ui.Image? awayLogoImage,
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
    final double matchBoxHeight = 140.0;
    final double sectionTitleHeight = 40.0;
    final double rowHeight = 58.0;
    final double rowsHeight = predictions.isEmpty ? 60.0 : (predictions.length * rowHeight);
    final double footerHeight = 60.0;

    final double totalHeight = padding + headerHeight + matchBoxHeight + sectionTitleHeight + rowsHeight + footerHeight + padding;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, totalHeight));

    // 1. Outer Card Background (Deep Slate / Dark Navy Gradient)
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(width, totalHeight),
        [const Color(0xFF0B1325), const Color(0xFF111A2E)],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, totalHeight), const Radius.circular(28)),
      bgPaint,
    );

    // Subtle Outer Border
    final borderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, totalHeight), const Radius.circular(28)),
      borderPaint,
    );

    // Top Gold Accent Line
    final accentPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(0, 0, width, 8),
        topLeft: const Radius.circular(28),
        topRight: const Radius.circular(28),
      ),
      accentPaint,
    );

    double currentY = padding + 10;

    // 2. Header: App Name (Centered Gold) & Competition Name (Left)
    _drawTextCentered(
      canvas,
      text: 'WHO WILL WIN',
      center: Offset(width / 2, currentY + 16),
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD700),
      letterSpacing: 3.0,
    );

    final displaySub = (leagueName != null && leagueName.isNotEmpty)
        ? leagueName
        : '$roomName  •  Code: $joinCode';
    _drawText(
      canvas,
      text: displaySub,
      offset: Offset(padding + 4, currentY + 48),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    );

    currentY += headerHeight;

    // 3. Match Hero Box (3D Metallic Green Stadium Container)
    final matchBoxRect = Rect.fromLTWH(padding, currentY, contentWidth, matchBoxHeight);
    final matchBoxBg = Paint()
      ..shader = ui.Gradient.linear(
        Offset(padding, currentY),
        Offset(padding + contentWidth, currentY + matchBoxHeight),
        [const Color(0xFF144A29), const Color(0xFF0A2B17)],
      );
    canvas.drawRRect(RRect.fromRectAndRadius(matchBoxRect, const Radius.circular(20)), matchBoxBg);

    // Green Metallic Frame Stroke
    final greenFramePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(matchBoxRect, const Radius.circular(20)), greenFramePaint);

    // Left Team Emblem / Logo Circle
    final leftCenter = Offset(padding + 68, currentY + 60);
    _drawTeamLogoBadge(canvas, center: leftCenter, teamName: homeTeam, image: homeLogoImage);

    // Right Team Emblem / Logo Circle
    final rightCenter = Offset(padding + contentWidth - 68, currentY + 60);
    _drawTeamLogoBadge(canvas, center: rightCenter, teamName: awayTeam, image: awayLogoImage);

    // Match Title in Center (Home VS Away)
    final matchTitle = '$homeTeam   VS   $awayTeam';
    _drawTextCentered(
      canvas,
      text: matchTitle,
      center: Offset(width / 2, currentY + 46),
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    // Status / Score Pill (Bottom Center of Match Container)
    final statusText = isFinished ? 'Final Score: $actualHomeScore - $actualAwayScore' : 'PREDICT';
    _drawStatusPill(
      canvas,
      text: statusText,
      center: Offset(width / 2, currentY + 110),
      isFinished: isFinished,
    );

    currentY += matchBoxHeight + 20;

    // 4. Section Header
    _drawText(
      canvas,
      text: 'ROOM MEMBER PREDICTIONS',
      offset: Offset(padding + 4, currentY),
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF94A3B8),
      letterSpacing: 1.5,
    );

    currentY += sectionTitleHeight;

    // 5. Member Prediction Cards (Dark rounded boxes with silver border & vertical divider)
    if (predictions.isEmpty) {
      _drawText(
        canvas,
        text: 'No predictions recorded for this match yet.',
        offset: Offset(padding + 16, currentY + 14),
        fontSize: 15,
        color: const Color(0xFF64748B),
      );
      currentY += 60;
    } else {
      for (int i = 0; i < predictions.length; i++) {
        final p = predictions[i];
        final rowRect = Rect.fromLTWH(padding, currentY, contentWidth, 48);

        // Dark Rounded Container
        final rowBg = Paint()..color = const Color(0xFF111827);
        canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(14)), rowBg);

        // Silver / Grey Border
        final rowBorder = Paint()
          ..color = const Color(0xFF374151)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(14)), rowBorder);

        // Avatar Circle (Left)
        final avatarCenter = Offset(padding + 26, currentY + 24);
        final avatarBg = Paint()..color = const Color(0xFF3B82F6);
        canvas.drawCircle(avatarCenter, 14, avatarBg);

        final initial = p.username.isNotEmpty ? p.username[0].toUpperCase() : '?';
        _drawTextCentered(
          canvas,
          text: initial,
          center: avatarCenter,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        // Username (Left side before divider)
        _drawText(
          canvas,
          text: p.username,
          offset: Offset(padding + 50, currentY + 13),
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        // Vertical Divider Line (|)
        final dividerX = padding + 210;
        final dividerPaint = Paint()
          ..color = const Color(0xFF374151)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(dividerX, currentY + 12),
          Offset(dividerX, currentY + 36),
          dividerPaint,
        );

        // Prediction Score (Right side of divider)
        final predText = p.hidden ? 'Hidden' : '${p.homeScore ?? '-'} - ${p.awayScore ?? '-'}';
        _drawText(
          canvas,
          text: predText,
          offset: Offset(dividerX + 24, currentY + 13),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: p.hidden ? const Color(0xFF9CA3AF) : Colors.white,
        );

        // Badges (JOKER, RED CARD, PENALTY)
        double badgeX = dividerX + 160;
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

        // Points Earned Pill (Far Right)
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

    // 6. Footer Line & Watermark
    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(padding, currentY), Offset(padding + contentWidth, currentY), linePaint);

    currentY += 16;
    _drawTextCentered(
      canvas,
      text: 'Predict matches & compete with friends on whowillwinapp.com',
      center: Offset(width / 2, currentY + 8),
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF64748B),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawTeamLogoBadge(
    Canvas canvas, {
    required Offset center,
    required String teamName,
    required ui.Image? image,
  }) {
    const double radius = 34.0;

    // Inner Recessed Background Circle
    final bgPaint = Paint()..color = const Color(0xFF071C0F);
    canvas.drawCircle(center, radius, bgPaint);

    // Green Metallic Ring Stroke
    final ringPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, ringPaint);

    if (image != null) {
      canvas.save();
      final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2));
      canvas.clipPath(clipPath);

      final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dst = Rect.fromCircle(center: center, radius: radius - 2);
      canvas.drawImageRect(image, src, dst, Paint()..filterQuality = ui.FilterQuality.high);
      canvas.restore();
    } else {
      // Initials Fallback (e.g. "SEV")
      final parts = teamName.trim().split(' ');
      String initials = '';
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (teamName.length >= 3) {
        initials = teamName.substring(0, 3).toUpperCase();
      } else {
        initials = teamName.toUpperCase();
      }

      _drawTextCentered(
        canvas,
        text: initials,
        center: center,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF86EFAC),
      );
    }
  }

  static void _drawStatusPill(
    Canvas canvas, {
    required String text,
    required Offset center,
    required bool isFinished,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isFinished ? const Color(0xFF86EFAC) : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final pillWidth = tp.width + 24;
    final pillHeight = 24.0;
    final pillRect = Rect.fromLTWH(center.dx - (pillWidth / 2), center.dy - (pillHeight / 2), pillWidth, pillHeight);

    final bgPaint = Paint()..color = const Color(0xFF166534);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(12)), bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(12)), borderPaint);

    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
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
