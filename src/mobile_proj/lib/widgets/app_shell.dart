import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const AppShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = 560,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: padding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: math.max(0, constraints.maxHeight - 40),
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
