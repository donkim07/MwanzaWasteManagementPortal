import 'package:flutter/material.dart';

class WasteManagementLoadingScreen extends StatefulWidget {
  const WasteManagementLoadingScreen({super.key});

  @override
  State<WasteManagementLoadingScreen> createState() => _WasteManagementLoadingScreenState();
}

class _WasteManagementLoadingScreenState extends State<WasteManagementLoadingScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C2F), // Dark forest green
              Color(0xFF115937), // Primary green
              Color(0xFF0D7A4F), // Rich emerald
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated recycle icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: const Icon(
                      Icons.recycling,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Loading text
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Custom loading indicator
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Positioned(
                              left: constraints.maxWidth * (_controller.value - 0.3),
                              child: Container(
                                width: constraints.maxWidth * 0.3,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}