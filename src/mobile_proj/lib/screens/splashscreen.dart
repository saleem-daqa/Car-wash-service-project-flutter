import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({Key? key, required this.onFinished}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _animationIndex = 0;

  final List<String> _animations = [
    'assets/WaterSplash.json',
    'assets/Washingnewmodel.json',
    'assets/LocationFinding.json',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_animationIndex < _animations.length - 1) {
          setState(() {
            _animationIndex++;
          });
          _controller.reset();
        } else {
          widget.onFinished();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          _animations[_animationIndex],
          controller: _controller,
          onLoaded: (composition) {
            _controller.duration = Duration(
              milliseconds: (composition.duration.inMilliseconds * 0.5).round(),
            );
            _controller.forward();
          },
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
