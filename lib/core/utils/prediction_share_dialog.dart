import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'prediction_card_generator.dart';

class PredictionShareDialog extends StatefulWidget {
  final String roomName;
  final String joinCode;
  final String? leagueName;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String? status;
  final int? actualHomeScore;
  final int? actualAwayScore;
  final List<RoomPredictionItemData> predictions;
  final String textSummary;

  const PredictionShareDialog({
    super.key,
    required this.roomName,
    required this.joinCode,
    this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.status,
    this.actualHomeScore,
    this.actualAwayScore,
    required this.predictions,
    required this.textSummary,
  });

  static Future<void> show(
    BuildContext context, {
    required String roomName,
    required String joinCode,
    String? leagueName,
    required String homeTeam,
    required String awayTeam,
    String? homeLogoUrl,
    String? awayLogoUrl,
    String? status,
    int? actualHomeScore,
    int? actualAwayScore,
    required List<RoomPredictionItemData> predictions,
    required String textSummary,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PredictionShareDialog(
        roomName: roomName,
        joinCode: joinCode,
        leagueName: leagueName,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeLogoUrl: homeLogoUrl,
        awayLogoUrl: awayLogoUrl,
        status: status,
        actualHomeScore: actualHomeScore,
        actualAwayScore: actualAwayScore,
        predictions: predictions,
        textSummary: textSummary,
      ),
    );
  }

  @override
  State<PredictionShareDialog> createState() => _PredictionShareDialogState();
}

class _PredictionShareDialogState extends State<PredictionShareDialog> {
  Uint8List? _imageBytes;
  bool _isGenerating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateAndShare();
  }

  Future<ui.Image?> _loadPlaceholderAsset() async {
    try {
      final data = await rootBundle.load('assets/images/default_club_placeholder.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Failed to load placeholder asset: $e');
    }
    return null;
  }

  Future<ui.Image?> _fetchLogo(String? url, ui.Image? fallback) async {
    if (url == null || url.trim().isEmpty) return fallback;
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      if (response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (e) {
      debugPrint('Logo fetch skipped for $url: $e');
    }
    return fallback;
  }

  Future<void> _generateAndShare() async {
    try {
      final fallbackImage = await _loadPlaceholderAsset();

      final logos = await Future.wait([
        _fetchLogo(widget.homeLogoUrl, fallbackImage).timeout(const Duration(seconds: 3), onTimeout: () => fallbackImage),
        _fetchLogo(widget.awayLogoUrl, fallbackImage).timeout(const Duration(seconds: 3), onTimeout: () => fallbackImage),
      ]);

      final homeImage = logos[0] ?? fallbackImage;
      final awayImage = logos[1] ?? fallbackImage;

      final bytes = await PredictionCardGenerator.generateMatchPredictionImage(
        roomName: widget.roomName,
        joinCode: widget.joinCode,
        leagueName: widget.leagueName,
        homeTeam: widget.homeTeam,
        awayTeam: widget.awayTeam,
        homeLogoImage: homeImage,
        awayLogoImage: awayImage,
        status: widget.status,
        actualHomeScore: widget.actualHomeScore,
        actualAwayScore: widget.actualAwayScore,
        predictions: widget.predictions,
      );

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isGenerating = false;
        });
      }

      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'match_${widget.homeTeam}_vs_${widget.awayTeam}.png',
      );

      await Share.shareXFiles([xFile], text: widget.textSummary);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _shareImage() async {
    if (_imageBytes == null) return;
    final xFile = XFile.fromData(
      _imageBytes!,
      mimeType: 'image/png',
      name: 'match_${widget.homeTeam}_vs_${widget.awayTeam}.png',
    );
    await Share.shareXFiles([xFile], text: widget.textSummary);
  }

  Future<void> _downloadImage() async {
    if (_imageBytes == null) return;
    final fileName = 'match_${widget.homeTeam}_vs_${widget.awayTeam}.png';
    final xFile = XFile.fromData(
      _imageBytes!,
      mimeType: 'image/png',
      name: fileName,
    );
    await xFile.saveTo(fileName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image downloaded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Text(
                      'Share Prediction Image',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: _isGenerating
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Generating prediction card image...'),
                          ],
                        ),
                      )
                    : _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _error ?? 'Failed to generate image',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isGenerating && _imageBytes != null) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _downloadImage,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.textSummary));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Text summary copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Text'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
