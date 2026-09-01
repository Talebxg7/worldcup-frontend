import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// An infinite auto-scrolling marquee with horizontal gradient edge-fade masks,
/// hover-to-pause on desktop, touch-pause on mobile, and reduced-motion fallback.
class EdgeFadeMarquee extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double pixelsPerSecond;
  final double edgeFadeWidth;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final bool pauseOnHover;
  final bool reverse;

  const EdgeFadeMarquee({
    super.key,
    required this.children,
    this.height = 48.0,
    this.pixelsPerSecond = 35.0,
    this.edgeFadeWidth = 40.0,
    this.padding = EdgeInsets.zero,
    this.spacing = 16.0,
    this.pauseOnHover = true,
    this.reverse = false,
  });

  @override
  State<EdgeFadeMarquee> createState() => _EdgeFadeMarqueeState();
}

class _EdgeFadeMarqueeState extends State<EdgeFadeMarquee>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  bool _isHovered = false;
  bool _isTouched = false;
  double _singleContentWidth = 0.0;
  final GlobalKey _firstSetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ticker = createTicker(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSingleSet();
      _startTicker();
    });
  }

  void _measureSingleSet() {
    final renderBox = _firstSetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      setState(() {
        _singleContentWidth = renderBox.size.width;
      });
    }
  }

  void _startTicker() {
    if (!mounted) return;
    _lastElapsed = Duration.zero;
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_scrollController.hasClients) return;

    // Check reduced motion accessibility
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      return;
    }

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double deltaSeconds = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (_isHovered || _isTouched || _singleContentWidth <= 0) return;

    final double deltaPixels = widget.pixelsPerSecond * deltaSeconds;
    double currentOffset = _scrollController.offset;

    if (widget.reverse) {
      currentOffset -= deltaPixels;
      if (currentOffset <= 0) {
        currentOffset += _singleContentWidth;
      }
    } else {
      currentOffset += deltaPixels;
      if (currentOffset >= _singleContentWidth) {
        currentOffset -= _singleContentWidth;
      }
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(currentOffset);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final fadeStop = (widget.edgeFadeWidth / screenWidth).clamp(0.01, 0.2);

    Widget content = SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // purely driven by translate ticker loop
        padding: widget.padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First duplicated set (measured)
            Row(
              key: _firstSetKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.children.length; i++) ...[
                  widget.children[i],
                  if (i < widget.children.length - 1 || widget.spacing > 0)
                    SizedBox(width: widget.spacing),
                ],
              ],
            ),
            // Second duplicated set (seamless loop)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.children.length; i++) ...[
                  widget.children[i],
                  if (i < widget.children.length - 1 || widget.spacing > 0)
                    SizedBox(width: widget.spacing),
                ],
              ],
            ),
            // Third set for ultra-wide desktop monitors
            if (kIsWeb || screenWidth > 900)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.children.length; i++) ...[
                    widget.children[i],
                    if (i < widget.children.length - 1 || widget.spacing > 0)
                      SizedBox(width: widget.spacing),
                  ],
                ],
              ),
          ],
        ),
      ),
    );

    // Apply horizontal edge-fade linear gradient mask (mask-image: linear-gradient)
    if (widget.edgeFadeWidth > 0) {
      content = ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              0.0,
              fadeStop,
              1.0 - fadeStop,
              1.0,
            ],
            colors: const [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: content,
      );
    }

    // Hover-to-pause & touch-to-pause handling
    if (widget.pauseOnHover) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Listener(
          onPointerDown: (_) => setState(() => _isTouched = true),
          onPointerUp: (_) => setState(() => _isTouched = false),
          onPointerCancel: (_) => setState(() => _isTouched = false),
          child: content,
        ),
      );
    }

    return content;
  }
}
