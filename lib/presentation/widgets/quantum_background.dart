import 'dart:math';
import 'package:flutter/material.dart';

class QuantumBackground extends StatefulWidget {
  final Widget child;

  const QuantumBackground({super.key, required this.child});

  @override
  State<QuantumBackground> createState() => _QuantumBackgroundState();
}

class _QuantumBackgroundState extends State<QuantumBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF05050B),
          ),
          child: Stack(
            children: [
              // Orb 1 - Purple
              Positioned(
                top: -80 + sin(_controller.value * 2 * pi) * 40,
                right: -60 + cos(_controller.value * 2 * pi) * 30,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9D00FF).withOpacity(0.3),
                        const Color(0xFF9D00FF).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Orb 2 - Cyan
              Positioned(
                bottom: -100 + cos(_controller.value * 2 * pi) * 50,
                left: -80 + sin(_controller.value * 2 * pi) * 40,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00F0FF).withOpacity(0.2),
                        const Color(0xFF00F0FF).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Orb 3 - Pink
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: MediaQuery.of(context).size.width * 0.3 + sin(_controller.value * 2 * pi + 1) * 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF003C).withOpacity(0.15),
                        const Color(0xFFFF003C).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}
