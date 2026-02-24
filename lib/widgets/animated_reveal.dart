import 'package:flutter/material.dart';

class AnimatedReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;
  final bool scale;

  const AnimatedReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 460),
    this.beginOffset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
    this.scale = true,
  });

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: widget.duration,
      curve: widget.curve,
      offset: _visible ? Offset.zero : widget.beginOffset,
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: widget.curve,
        opacity: _visible ? 1 : 0,
        child: AnimatedScale(
          duration: widget.duration,
          curve: widget.curve,
          scale: widget.scale ? (_visible ? 1 : 0.96) : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
