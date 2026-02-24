import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class MorphingLoader extends StatefulWidget {
  const MorphingLoader({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.8,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  State<MorphingLoader> createState() => _MorphingLoaderState();
}

class _MorphingLoaderState extends State<MorphingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final phase = (math.sin(t * math.pi * 2) + 1) / 2;
        final borderRadius = lerpDouble(widget.size / 2, widget.size * 0.16, phase) ??
            widget.size / 2;
        final scale = 0.86 + (0.14 * phase);

        return Transform.rotate(
          angle: t * math.pi * 2,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: baseColor,
                      width: widget.strokeWidth,
                    ),
                  ),
                ),
                Container(
                  width: widget.size * 0.24,
                  height: widget.size * 0.24,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(widget.size * 0.08),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
