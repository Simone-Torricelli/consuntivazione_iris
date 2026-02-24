import 'package:flutter/material.dart';

class ResponsiveAppFrame extends StatelessWidget {
  final Widget child;

  const ResponsiveAppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 760) {
          return child;
        }

        final maxContentWidth = width >= 1500
            ? 1220.0
            : width >= 1100
            ? 1000.0
            : 860.0;

        return ColoredBox(
          color: const Color(0xFFEFF3F8),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
