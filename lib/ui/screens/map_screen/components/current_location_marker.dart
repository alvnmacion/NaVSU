import 'package:flutter/material.dart';
import 'package:navsu/ui/screens/map_screen/painters/flashlight_painter.dart';

class CurrentLocationMarker extends StatelessWidget {
  final double markerSize;
  final double compassRotation;
  final Animation<double> pulseAnimation;
  final Animation<double> flashlightAnimation;

  const CurrentLocationMarker({
    Key? key,
    required this.markerSize,
    required this.compassRotation,
    required this.pulseAnimation,
    required this.flashlightAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnimation, flashlightAnimation]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: compassRotation * (3.14159265359 / 180),
              child: CustomPaint(
                size: Size(markerSize * 8, markerSize * 8),
                painter: FlashlightPainter(
                  opacity: flashlightAnimation.value,
                  color: Colors.green,
                  length: markerSize * 4,
                  width: markerSize * 2,
                ),
              ),
            ),
            Transform.scale(
              scale: 1.0 + (pulseAnimation.value * 0.5),
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2 * (1 - pulseAnimation.value)),
                ),
              ),
            ),
            Container(
              width: markerSize * 0.7,
              height: markerSize * 0.7,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: markerSize * 0.25,
              height: markerSize * 0.25,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}
