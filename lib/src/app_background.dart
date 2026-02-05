import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bgImage = width > 700
        ? 'assets/images/bg_desktop.jpg'
        : 'assets/images/bg_mobile.jpg';

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            bgImage,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.35),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
