import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for a beach umbrella
class UmbrellaPainter extends CustomPainter {
  final Color color;

  UmbrellaPainter({this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Pole
    paint.color = Colors.brown.shade700;
    final poleRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.65),
      width: size.width * 0.06,
      height: size.height * 0.55,
    );
    canvas.drawRect(poleRect, paint);

    // Umbrella canopy - simple arc shape
    paint.color = color;
    final canopyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.25),
      width: size.width * 0.9,
      height: size.height * 0.5,
    );
    canvas.drawArc(
      canopyRect,
      math.pi, // Start angle (180 degrees)
      math.pi, // Sweep angle (180 degrees)
      true,    // Use center
      paint,
    );

    // Add stripes for detail
    paint.color = color.withOpacity(0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    final centerX = size.width / 2;
    final topY = size.height * 0.25;
    
    // Draw 4 stripes from center to edge
    for (int i = 0; i < 4; i++) {
      final angle = math.pi + (i * math.pi / 4);
      final endX = centerX + (size.width * 0.45) * math.cos(angle);
      final endY = topY + (size.height * 0.25) * math.sin(angle);
      canvas.drawLine(
        Offset(centerX, topY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for a sunbed/lounge chair
class SunbedPainter extends CustomPainter {
  final Color color;

  SunbedPainter({this.color = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Bed frame
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.6, size.width * 0.8, size.height * 0.1),
      paint,
    );

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.7, size.width * 0.08, size.height * 0.25),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.77, size.height * 0.7, size.width * 0.08, size.height * 0.25),
      paint,
    );

    // Mattress
    paint.color = color;
    final mattressPath = Path();
    mattressPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.3, size.width * 0.9, size.height * 0.35),
        Radius.circular(size.width * 0.05),
      ),
    );
    canvas.drawPath(mattressPath, paint);

    // Mattress lines (quilted effect)
    paint.color = color.withOpacity(0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.05, size.height * 0.3 + (size.height * 0.35 * i / 4)),
        Offset(size.width * 0.95, size.height * 0.3 + (size.height * 0.35 * i / 4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for sea waves
class WavePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  WavePainter({this.color = const Color(0xFF90CAF9), this.animationValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Horizontal scrolling (Right to Left): 0 -> 1
    // We want continuous shift.
    final horizontalShift = animationValue * size.width;

    // Vertical Swash ("Risacca"): Up and Down cycle
    // We use sine to create a smooth -1 to 1 to -1 cycle over the animation
    // We want the wave to move down (onto sand) and back up.
    // Let's say overlap is max 20% of height.
    // We oscillate between 0 (edge) and +0.2*height (overlap).
    // sin^2 or (sin+1)/2 gives 0..1.
    final swashCycle = (math.sin(animationValue * 2 * math.pi) + 1) / 2; // 0 -> 1 -> 0
    final verticalOverlap = swashCycle * (size.height * 0.25); // Max overlap 25%

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Draw wavy line at the BOTTOM + Overlap
    // Base line is at size.height. We add verticalOverlap to it.
    // We also add the sine wave shape for the water surface.
    
    // To make it look like waves overlapping sand, we draw the edge further down.
    final baseLineY = size.height + verticalOverlap;

    for (double x = size.width; x >= 0; x -= 5) {
      // Wave shape
      // Moving right to left means phase should increase with time? 
      //If we want right-to-left movement, we subtract time from x.
      // (x + shift) gives left-to-right visual if we look at a fixed window?
      // actually sin(kx - wt).
      
      final waveShape = math.sin(((x + horizontalShift) / size.width) * 4 * math.pi) * (size.height * 0.1);
      
      final y = baseLineY + waveShape;
      path.lineTo(x, y);
    }

    path.lineTo(0, 0); // Close back to top left
    path.close();

    canvas.drawPath(path, paint);

    // Froth / Foam layer
    paint.color = Colors.white.withOpacity(0.4);
    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(size.width, 0);

    // Froth is slightly above the main wave edge
    for (double x = size.width; x >= 0; x -= 5) {
      final waveShape = math.sin(((x + horizontalShift) / size.width) * 4 * math.pi + 0.5) * (size.height * 0.1);
      // Froth lags slightly or is offset
      final y = baseLineY + waveShape - (size.height * 0.05); 
      path2.lineTo(x, y);
    }
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path2, paint);

    // 3. Shore Foam (Schiuma della risacca) - Distinct white edge at the bottom
    paint.color = Colors.white.withOpacity(0.8);
    final foamPath = Path();
    
    // Store points to create a ribbon
    final List<Offset> wavePoints = [];
    
    // Calculate the same wave curve as the main body
    for (double x = size.width; x >= 0; x -= 5) {
      final waveShape = math.sin(((x + horizontalShift) / size.width) * 4 * math.pi) * (size.height * 0.1);
      final y = baseLineY + waveShape;
      wavePoints.add(Offset(x, y));
    }
    
    if (wavePoints.isNotEmpty) {
      // Top edge of foam (matches water edge)
      foamPath.moveTo(wavePoints.first.dx, wavePoints.first.dy);
      for (var p in wavePoints) {
        foamPath.lineTo(p.dx, p.dy);
      }
      
      // Bottom edge of foam (slightly further down on sand)
      // The foam band width
      final foamWidth = size.height * 0.08; 
      
      for (int i = wavePoints.length - 1; i >= 0; i--) {
        final p = wavePoints[i];
        foamPath.lineTo(p.dx, p.dy + foamWidth);
      }
      
      foamPath.close();
      canvas.drawPath(foamPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => 
    animationValue != oldDelegate.animationValue;
}

/// Custom painter for wooden walkway
class WalkwayPainter extends CustomPainter {
  final Color color;

  WalkwayPainter({this.color = const Color(0xFF8D6E63)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw wooden planks
    final plankCount = (size.height / (size.width * 0.15)).ceil();
    for (int i = 0; i < plankCount; i++) {
      final y = i * size.width * 0.15;
      
      // Plank
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, size.width * 0.12),
        paint,
      );

      // Wood grain (darker lines)
      paint.color = color.withOpacity(0.6);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      canvas.drawLine(
        Offset(0, y + size.width * 0.04),
        Offset(size.width, y + size.width * 0.04),
        paint,
      );
      canvas.drawLine(
        Offset(0, y + size.width * 0.08),
        Offset(size.width, y + size.width * 0.08),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for bar/kiosk
class BarPainter extends CustomPainter {
  final Color color;

  BarPainter({this.color = Colors.brown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Roof
    paint.color = Colors.red.shade900;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.1, size.height * 0.3);
    roofPath.lineTo(size.width * 0.5, size.height * 0.05);
    roofPath.lineTo(size.width * 0.9, size.height * 0.3);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Building
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.3, size.width * 0.7, size.height * 0.6),
      paint,
    );

    // Window
    paint.color = Colors.lightBlue.shade200;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.2, size.height * 0.2),
      paint,
    );

    // Door
    paint.color = Colors.brown.shade900;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.55, size.width * 0.2, size.height * 0.35),
      paint,
    );

    // Door handle
    paint.color = Colors.yellow;
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.72),
      size.width * 0.02,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for palm tree
class PalmPainter extends CustomPainter {
  final Color color;

  PalmPainter({this.color = Colors.green});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Trunk
    paint.color = Colors.brown.shade700;
    final trunkPath = Path();
    trunkPath.moveTo(size.width * 0.45, size.height * 0.4);
    trunkPath.quadraticBezierTo(
      size.width * 0.42, size.height * 0.6,
      size.width * 0.45, size.height * 0.9,
    );
    trunkPath.lineTo(size.width * 0.55, size.height * 0.9);
    trunkPath.quadraticBezierTo(
      size.width * 0.58, size.height * 0.6,
      size.width * 0.55, size.height * 0.4,
    );
    trunkPath.close();
    canvas.drawPath(trunkPath, paint);

    // Palm leaves
    paint.color = color;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 2;
      final leafPath = Path();
      final centerX = size.width * 0.5;
      final centerY = size.height * 0.35;
      
      leafPath.moveTo(centerX, centerY);
      leafPath.quadraticBezierTo(
        centerX + math.cos(angle) * size.width * 0.2,
        centerY + math.sin(angle) * size.height * 0.15,
        centerX + math.cos(angle) * size.width * 0.4,
        centerY + math.sin(angle) * size.height * 0.25,
      );
      leafPath.quadraticBezierTo(
        centerX + math.cos(angle) * size.width * 0.35,
        centerY + math.sin(angle) * size.height * 0.22,
        centerX, centerY,
      );
      canvas.drawPath(leafPath, paint);
    }

    // Coconuts
    paint.color = Colors.brown.shade400;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.45 + i * 0.05), size.height * 0.38),
        size.width * 0.04,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for rock
class RockPainter extends CustomPainter {
  final Color color;

  RockPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Main rock shape (irregular polygon)
    paint.color = color;
    final rockPath = Path();
    rockPath.moveTo(size.width * 0.2, size.height * 0.8);
    rockPath.lineTo(size.width * 0.1, size.height * 0.5);
    rockPath.lineTo(size.width * 0.3, size.height * 0.2);
    rockPath.lineTo(size.width * 0.5, size.height * 0.15);
    rockPath.lineTo(size.width * 0.7, size.height * 0.25);
    rockPath.lineTo(size.width * 0.9, size.height * 0.55);
    rockPath.lineTo(size.width * 0.8, size.height * 0.85);
    rockPath.close();
    canvas.drawPath(rockPath, paint);

    // Shadow/depth
    paint.color = color.withOpacity(0.5);
    final shadowPath = Path();
    shadowPath.moveTo(size.width * 0.2, size.height * 0.8);
    shadowPath.lineTo(size.width * 0.5, size.height * 0.6);
    shadowPath.lineTo(size.width * 0.8, size.height * 0.85);
    shadowPath.close();
    canvas.drawPath(shadowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for shower
class ShowerPainter extends CustomPainter {
  final Color color;

  ShowerPainter({this.color = Colors.blueGrey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Pole
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.3, size.width * 0.1, size.height * 0.6),
      paint,
    );

    // Shower head
    paint.color = color.withOpacity(0.8);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.25, size.width * 0.3, size.height * 0.1),
      paint,
    );

    // Water drops
    paint.color = Colors.lightBlue.shade200;
    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.35 + i * 0.075);
      canvas.drawCircle(Offset(x, size.height * 0.4), size.width * 0.02, paint);
      canvas.drawCircle(Offset(x, size.height * 0.5), size.width * 0.02, paint);
      canvas.drawCircle(Offset(x, size.height * 0.6), size.width * 0.02, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for cabin/changing room
class CabinPainter extends CustomPainter {
  final Color color;

  CabinPainter({this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Cabin walls
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.6),
      paint,
    );

    // Roof
    paint.color = color.withOpacity(0.7);
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.05, size.height * 0.3);
    roofPath.lineTo(size.width * 0.5, size.height * 0.1);
    roofPath.lineTo(size.width * 0.95, size.height * 0.3);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Door
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.5, size.width * 0.3, size.height * 0.4),
      paint,
    );

    // Door handle
    paint.color = Colors.yellow;
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.7),
      size.width * 0.03,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for gazebo
class GazeboPainter extends CustomPainter {
  final Color color;

  GazeboPainter({this.color = Colors.brown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Roof
    paint.color = Colors.red.shade800;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.5, size.height * 0.1);
    roofPath.lineTo(size.width * 0.9, size.height * 0.4);
    roofPath.lineTo(size.width * 0.1, size.height * 0.4);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Poles
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.4, size.width * 0.08, size.height * 0.5),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.77, size.height * 0.4, size.width * 0.08, size.height * 0.5),
      paint,
    );

    // Floor
    paint.color = Colors.brown.shade300;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.85, size.width * 0.8, size.height * 0.1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for bench
class BenchPainter extends CustomPainter {
  final Color color;

  BenchPainter({this.color = Colors.brown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Seat
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.5, size.width * 0.8, size.height * 0.15),
      paint,
    );

    // Backrest
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.1, size.height * 0.35),
      paint,
    );

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.65, size.width * 0.08, size.height * 0.3),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.77, size.height * 0.65, size.width * 0.08, size.height * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for fence
class FencePainter extends CustomPainter {
  final Color color;

  FencePainter({this.color = Colors.brown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = color;

    // Horizontal rails
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.1),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.1),
      paint,
    );

    // Vertical posts
    const postCount = 5;
    for (int i = 0; i < postCount; i++) {
      final x = i * size.width / (postCount - 1) - size.width * 0.05;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.2, size.width * 0.1, size.height * 0.6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for first aid station
class FirstAidPainter extends CustomPainter {
  final Color color;

  FirstAidPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Building
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.6),
      paint,
    );

    // Red cross
    paint.color = Colors.red;
    // Vertical bar
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.4, size.width * 0.1, size.height * 0.4),
      paint,
    );
    // Horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.55, size.width * 0.3, size.height * 0.1),
      paint,
    );

    // Border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = Colors.red;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// Custom painter for zones/areas with customizable borders and fills
class ZonePainter extends CustomPainter {
  final Color? borderColor;
  final double borderWidth;
  final Color? fillColor;
  final double fillOpacity;
  final String? title;
  final List<Offset>? customPath;

  ZonePainter({
    this.borderColor,
    this.borderWidth = 2.0,
    this.fillColor,
    this.fillOpacity = 0.3,
    this.title,
    this.customPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    Path zonePath;
    
    if (customPath != null && customPath!.isNotEmpty) {
      // Use custom path (free-form shape)
      zonePath = _createSmoothPath(customPath!, size);
    } else {
      // Use rectangle
      zonePath = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // Draw fill
    if (fillColor != null) {
      paint.color = fillColor!.withOpacity(fillOpacity);
      paint.style = PaintingStyle.fill;
      canvas.drawPath(zonePath, paint);
    }

    // Draw border
    if (borderColor != null) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = borderWidth;
      paint.color = borderColor!;
      canvas.drawPath(zonePath, paint);
    }

    // Draw title
    if (title != null && title!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: title,
          style: TextStyle(
            color: borderColor ?? Colors.black,
            fontSize: math.min(size.width, size.height) * 0.15,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Center the text
      final offset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  Path _createSmoothPath(List<Offset> points, Size size) {
    if (points.length < 2) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final path = Path();
    
    // Scale points to size
    final scaledPoints = points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
    
    path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);

    // Use quadratic bezier curves for smooth path
    for (int i = 0; i < scaledPoints.length - 1; i++) {
      final p0 = scaledPoints[i];
      final p1 = scaledPoints[i + 1];
      
      if (i < scaledPoints.length - 2) {
        final p2 = scaledPoints[i + 2];
        final controlPoint = Offset(
          (p0.dx + p1.dx + p2.dx) / 3,
          (p0.dy + p1.dy + p2.dy) / 3,
        );
        path.quadraticBezierTo(p1.dx, p1.dy, controlPoint.dx, controlPoint.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ZonePainter oldDelegate) {
    return borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        fillColor != oldDelegate.fillColor ||
        fillOpacity != oldDelegate.fillOpacity ||
        title != oldDelegate.title ||
        customPath != oldDelegate.customPath;
  }
}

/// Custom painter for grass terrain
class GrassPainter extends CustomPainter {
  final Color color;

  GrassPainter({this.color = Colors.green});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Base grass color
    paint.color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Grass blades
    paint.color = color.withOpacity(0.7);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    for (int i = 0; i < 20; i++) {
      final x = (i % 5) * size.width / 5 + size.width * 0.1;
      final y = (i ~/ 5) * size.height / 4;
      canvas.drawLine(
        Offset(x, y + size.height * 0.15),
        Offset(x + size.width * 0.02, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for deckchair
class DeckchairPainter extends CustomPainter {
  final Color color;

  DeckchairPainter({this.color = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Frame
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.7, size.width * 0.6, size.height * 0.05),
      paint,
    );

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.75, size.width * 0.05, size.height * 0.2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.75, size.width * 0.05, size.height * 0.2),
      paint,
    );

    // Fabric
    paint.color = color;
    final fabricPath = Path();
    fabricPath.moveTo(size.width * 0.2, size.height * 0.7);
    fabricPath.lineTo(size.width * 0.3, size.height * 0.3);
    fabricPath.lineTo(size.width * 0.7, size.height * 0.3);
    fabricPath.lineTo(size.width * 0.8, size.height * 0.7);
    fabricPath.close();
    canvas.drawPath(fabricPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for pedalo
class PedaloPainter extends CustomPainter {
  final Color color;

  PedaloPainter({this.color = Colors.cyan});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Hull
    paint.color = color;
    final hullPath = Path();
    hullPath.moveTo(size.width * 0.1, size.height * 0.6);
    hullPath.lineTo(size.width * 0.2, size.height * 0.8);
    hullPath.lineTo(size.width * 0.8, size.height * 0.8);
    hullPath.lineTo(size.width * 0.9, size.height * 0.6);
    hullPath.close();
    canvas.drawPath(hullPath, paint);

    // Seats
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.4, size.width * 0.15, size.height * 0.2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.4, size.width * 0.15, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for canoe/kayak
class CanoePainter extends CustomPainter {
  final Color color;

  CanoePainter({this.color = Colors.teal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Canoe body
    paint.color = color;
    final canoePath = Path();
    canoePath.moveTo(size.width * 0.1, size.height * 0.5);
    canoePath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.3,
      size.width * 0.9, size.height * 0.5,
    );
    canoePath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.7,
      size.width * 0.1, size.height * 0.5,
    );
    canvas.drawPath(canoePath, paint);

    // Paddle
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.2, size.width * 0.05, size.height * 0.6),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.15, size.width * 0.15, size.height * 0.1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for boat
class BoatPainter extends CustomPainter {
  final Color color;

  BoatPainter({this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Hull
    paint.color = color;
    final hullPath = Path();
    hullPath.moveTo(size.width * 0.2, size.height * 0.6);
    hullPath.lineTo(size.width * 0.1, size.height * 0.8);
    hullPath.lineTo(size.width * 0.9, size.height * 0.8);
    hullPath.lineTo(size.width * 0.8, size.height * 0.6);
    hullPath.close();
    canvas.drawPath(hullPath, paint);

    // Cabin
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.4, size.width * 0.3, size.height * 0.2),
      paint,
    );

    // Mast
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.48, size.height * 0.1, size.width * 0.04, size.height * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for surfboard
class SurfPainter extends CustomPainter {
  final Color color;

  SurfPainter({this.color = Colors.lightBlue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Surfboard
    paint.color = color;
    final boardPath = Path();
    boardPath.moveTo(size.width * 0.5, size.height * 0.1);
    boardPath.quadraticBezierTo(
      size.width * 0.6, size.height * 0.5,
      size.width * 0.5, size.height * 0.9,
    );
    boardPath.quadraticBezierTo(
      size.width * 0.4, size.height * 0.5,
      size.width * 0.5, size.height * 0.1,
    );
    canvas.drawPath(boardPath, paint);

    // Stripe
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for windsurf
class WindsurfPainter extends CustomPainter {
  final Color color;

  WindsurfPainter({this.color = Colors.cyan});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Board
    paint.color = color;
    final boardPath = Path();
    boardPath.moveTo(size.width * 0.5, size.height * 0.7);
    boardPath.quadraticBezierTo(
      size.width * 0.6, size.height * 0.8,
      size.width * 0.5, size.height * 0.9,
    );
    boardPath.quadraticBezierTo(
      size.width * 0.4, size.height * 0.8,
      size.width * 0.5, size.height * 0.7,
    );
    canvas.drawPath(boardPath, paint);

    // Sail
    paint.color = Colors.red.shade300;
    final sailPath = Path();
    sailPath.moveTo(size.width * 0.5, size.height * 0.7);
    sailPath.lineTo(size.width * 0.5, size.height * 0.1);
    sailPath.lineTo(size.width * 0.8, size.height * 0.4);
    sailPath.close();
    canvas.drawPath(sailPath, paint);

    // Mast
    paint.color = Colors.brown;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for dock
class DockPainter extends CustomPainter {
  final Color color;

  DockPainter({this.color = Colors.blueGrey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Platform
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
      paint,
    );

    // Planks
    paint.color = color.withOpacity(0.7);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      final x = i * size.width / 8;
      canvas.drawLine(
        Offset(x, size.height * 0.4),
        Offset(x, size.height * 0.6),
        paint,
      );
    }

    // Poles
    paint.style = PaintingStyle.fill;
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.6, size.width * 0.08, size.height * 0.4),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.6, size.width * 0.08, size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for wall
class WallPainter extends CustomPainter {
  final Color color;

  WallPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Wall
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.6),
      paint,
    );

    // Bricks
    paint.color = color.withOpacity(0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    
    for (int row = 0; row < 4; row++) {
      final y = size.height * 0.2 + row * size.height * 0.15;
      final offset = (row % 2) * size.width * 0.1;
      for (int col = 0; col < 6; col++) {
        final x = col * size.width / 6 + offset;
        canvas.drawRect(
          Rect.fromLTWH(x, y, size.width / 6, size.height * 0.15),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for plant
class PlantPainter extends CustomPainter {
  final Color color;

  PlantPainter({this.color = Colors.green});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Pot
    paint.color = Colors.brown.shade400;
    final potPath = Path();
    potPath.moveTo(size.width * 0.3, size.height * 0.7);
    potPath.lineTo(size.width * 0.25, size.height * 0.9);
    potPath.lineTo(size.width * 0.75, size.height * 0.9);
    potPath.lineTo(size.width * 0.7, size.height * 0.7);
    potPath.close();
    canvas.drawPath(potPath, paint);

    // Leaves
    paint.color = color;
    for (int i = 0; i < 5; i++) {
      final angle = (i * math.pi * 2 / 5) - math.pi / 2;
      final leafPath = Path();
      leafPath.moveTo(size.width * 0.5, size.height * 0.6);
      leafPath.quadraticBezierTo(
        size.width * 0.5 + math.cos(angle) * size.width * 0.15,
        size.height * 0.6 + math.sin(angle) * size.height * 0.15,
        size.width * 0.5 + math.cos(angle) * size.width * 0.25,
        size.height * 0.6 + math.sin(angle) * size.height * 0.25,
      );
      leafPath.quadraticBezierTo(
        size.width * 0.5 + math.cos(angle) * size.width * 0.2,
        size.height * 0.6 + math.sin(angle) * size.height * 0.2,
        size.width * 0.5, size.height * 0.6,
      );
      canvas.drawPath(leafPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for flower
class FlowerPainter extends CustomPainter {
  final Color color;

  FlowerPainter({this.color = Colors.pink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Stem
    paint.color = Colors.green;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.47, size.height * 0.4, size.width * 0.06, size.height * 0.5),
      paint,
    );

    // Petals
    paint.color = color;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.drawCircle(
        Offset(
          size.width * 0.5 + math.cos(angle) * size.width * 0.15,
          size.height * 0.35 + math.sin(angle) * size.height * 0.15,
        ),
        size.width * 0.1,
        paint,
      );
    }

    // Center
    paint.color = Colors.yellow;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for playground
class PlaygroundPainter extends CustomPainter {
  final Color color;

  PlaygroundPainter({this.color = Colors.orange});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Slide
    paint.color = color;
    final slidePath = Path();
    slidePath.moveTo(size.width * 0.7, size.height * 0.3);
    slidePath.lineTo(size.width * 0.7, size.height * 0.7);
    slidePath.lineTo(size.width * 0.3, size.height * 0.9);
    slidePath.lineTo(size.width * 0.3, size.height * 0.85);
    slidePath.lineTo(size.width * 0.65, size.height * 0.7);
    slidePath.lineTo(size.width * 0.65, size.height * 0.3);
    slidePath.close();
    canvas.drawPath(slidePath, paint);

    // Ladder
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.3, size.width * 0.05, size.height * 0.6),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.3, size.width * 0.05, size.height * 0.6),
      paint,
    );
    
    // Rungs
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.15,
          size.height * (0.4 + i * 0.15),
          size.width * 0.15,
          size.width * 0.03,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for lifeguard tower
class LifeguardTowerPainter extends CustomPainter {
  final Color color;

  LifeguardTowerPainter({this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Legs
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.5, size.width * 0.08, size.height * 0.5),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.5, size.width * 0.08, size.height * 0.5),
      paint,
    );

    // Platform
    paint.color = Colors.brown.shade300;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.45, size.width * 0.7, size.height * 0.1),
      paint,
    );

    // Tower cabin
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.15, size.width * 0.6, size.height * 0.3),
      paint,
    );

    // Roof
    paint.color = Colors.white;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.15, size.height * 0.15);
    roofPath.lineTo(size.width * 0.5, size.height * 0.05);
    roofPath.lineTo(size.width * 0.85, size.height * 0.15);
    roofPath.close();
    canvas.drawPath(roofPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for lighthouse
class LighthousePainter extends CustomPainter {
  final Color color;

  LighthousePainter({this.color = Colors.yellow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Tower
    paint.color = Colors.white;
    final towerPath = Path();
    towerPath.moveTo(size.width * 0.35, size.height * 0.9);
    towerPath.lineTo(size.width * 0.4, size.height * 0.3);
    towerPath.lineTo(size.width * 0.6, size.height * 0.3);
    towerPath.lineTo(size.width * 0.65, size.height * 0.9);
    towerPath.close();
    canvas.drawPath(towerPath, paint);

    // Stripes
    paint.color = Colors.red;
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.4 + i * 0.15);
      final topWidth = size.width * (0.2 + i * 0.02);
      final bottomWidth = size.width * (0.2 + (i + 1) * 0.02);
      
      final stripePath = Path();
      stripePath.moveTo(size.width * 0.5 - topWidth / 2, y);
      stripePath.lineTo(size.width * 0.5 + topWidth / 2, y);
      stripePath.lineTo(size.width * 0.5 + bottomWidth / 2, y + size.height * 0.1);
      stripePath.lineTo(size.width * 0.5 - bottomWidth / 2, y + size.height * 0.1);
      stripePath.close();
      canvas.drawPath(stripePath, paint);
    }

    // Light
    paint.color = color;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.2, size.width * 0.3, size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for ticket office
class TicketOfficePainter extends CustomPainter {
  final Color color;

  TicketOfficePainter({this.color = Colors.purple});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Building
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.3, size.width * 0.7, size.height * 0.6),
      paint,
    );

    // Roof
    paint.color = color.withOpacity(0.7);
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.1, size.height * 0.3);
    roofPath.lineTo(size.width * 0.5, size.height * 0.1);
    roofPath.lineTo(size.width * 0.9, size.height * 0.3);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Window
    paint.color = Colors.lightBlue.shade100;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.45, size.width * 0.4, size.height * 0.25),
      paint,
    );

    // Counter line
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.05),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for kiosk
class KioskPainter extends CustomPainter {
  final Color color;

  KioskPainter({this.color = Colors.brown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Base
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.4, size.width * 0.6, size.height * 0.5),
      paint,
    );

    // Awning
    paint.color = Colors.red.shade700;
    final awningPath = Path();
    awningPath.moveTo(size.width * 0.15, size.height * 0.4);
    awningPath.lineTo(size.width * 0.1, size.height * 0.3);
    awningPath.lineTo(size.width * 0.9, size.height * 0.3);
    awningPath.lineTo(size.width * 0.85, size.height * 0.4);
    awningPath.close();
    canvas.drawPath(awningPath, paint);

    // Counter opening
    paint.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.5, size.width * 0.4, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for lounge
class LoungePainter extends CustomPainter {
  final Color color;

  LoungePainter({this.color = Colors.indigo});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Sofa base
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.5, size.width * 0.8, size.height * 0.3),
      paint,
    );

    // Backrest
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.25),
      paint,
    );

    // Cushions
    paint.color = color.withOpacity(0.7);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (0.15 + i * 0.25),
          size.height * 0.35,
          size.width * 0.2,
          size.height * 0.15,
        ),
        paint,
      );
    }

    // Legs
    paint.color = Colors.brown;
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (0.15 + i * 0.23),
          size.height * 0.8,
          size.width * 0.05,
          size.height * 0.15,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for umbrella stand
class UmbrellaStandPainter extends CustomPainter {
  final Color color;

  UmbrellaStandPainter({this.color = Colors.deepOrange});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Base
    paint.color = Colors.grey.shade700;
    final basePath = Path();
    basePath.moveTo(size.width * 0.3, size.height * 0.8);
    basePath.lineTo(size.width * 0.25, size.height * 0.9);
    basePath.lineTo(size.width * 0.75, size.height * 0.9);
    basePath.lineTo(size.width * 0.7, size.height * 0.8);
    basePath.close();
    canvas.drawPath(basePath, paint);

    // Stand cylinder
    paint.color = Colors.grey.shade600;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.3, size.width * 0.3, size.height * 0.5),
      paint,
    );

    // Umbrellas in stand
    paint.color = color;
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.35 + i * 0.1);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.1, size.width * 0.05, size.height * 0.25),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for parking
class ParkingPainter extends CustomPainter {
  final Color color;

  ParkingPainter({this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Parking lot
    paint.color = Colors.grey.shade400;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Parking lines
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(i * size.width / 3, 0),
        Offset(i * size.width / 3, size.height),
        paint,
      );
    }

    // P sign
    paint.style = PaintingStyle.fill;
    paint.color = color;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.2,
      paint,
    );

    // P letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.25,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width * 0.5 - textPainter.width / 2,
        size.height * 0.5 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for entrance
class EntrancePainter extends CustomPainter {
  final Color color;

  EntrancePainter({this.color = Colors.green});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gate posts
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.15, size.height * 0.7),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.75, size.height * 0.2, size.width * 0.15, size.height * 0.7),
      paint,
    );

    // Archway
    paint.color = color;
    final archPath = Path();
    archPath.moveTo(size.width * 0.25, size.height * 0.2);
    archPath.lineTo(size.width * 0.25, size.height * 0.4);
    archPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.15,
      size.width * 0.75, size.height * 0.4,
    );
    archPath.lineTo(size.width * 0.75, size.height * 0.2);
    archPath.close();
    canvas.drawPath(archPath, paint);

    // Arrow
    paint.color = Colors.white;
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.5, size.height * 0.5);
    arrowPath.lineTo(size.width * 0.4, size.height * 0.6);
    arrowPath.lineTo(size.width * 0.45, size.height * 0.6);
    arrowPath.lineTo(size.width * 0.45, size.height * 0.75);
    arrowPath.lineTo(size.width * 0.55, size.height * 0.75);
    arrowPath.lineTo(size.width * 0.55, size.height * 0.6);
    arrowPath.lineTo(size.width * 0.6, size.height * 0.6);
    arrowPath.close();
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for restaurant
class RestaurantPainter extends CustomPainter {
  final Color color;

  RestaurantPainter({this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Building
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.6),
      paint,
    );

    // Roof
    paint.color = Colors.brown.shade800;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.05, size.height * 0.3);
    roofPath.lineTo(size.width * 0.5, size.height * 0.05);
    roofPath.lineTo(size.width * 0.95, size.height * 0.3);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Windows
    paint.color = Colors.lightBlue.shade100;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.45, size.width * 0.2, size.height * 0.2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.45, size.width * 0.2, size.height * 0.2),
      paint,
    );

    // Door
    paint.color = Colors.brown.shade900;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.425, size.height * 0.55, size.width * 0.15, size.height * 0.35),
      paint,
    );
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for bungalow
class BungalowPainter extends CustomPainter {
  final Color color;

  BungalowPainter({this.color = Colors.brown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Main structure
    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.35, size.width * 0.8, size.height * 0.55),
      paint,
    );

    // Roof
    paint.color = Colors.red.shade900;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.05, size.height * 0.35);
    roofPath.lineTo(size.width * 0.5, size.height * 0.1);
    roofPath.lineTo(size.width * 0.95, size.height * 0.35);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Window
    paint.color = Colors.lightBlue.shade200;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.5, size.width * 0.25, size.height * 0.2),
      paint,
    );

    // Door
    paint.color = Colors.brown.shade900;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.6, size.width * 0.25, size.height * 0.3),
      paint,
    );

    // Door handle
    paint.color = Colors.yellow;
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.75),
      size.width * 0.025,
      paint,
    );

    // Chimney
    paint.color = Colors.red.shade800;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.15, size.width * 0.1, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for pagoda (oriental pavilion)
class PagodaPainter extends CustomPainter {
  final Color color;

  PagodaPainter({this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Base structure
    paint.color = color.withOpacity(0.8);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.5, size.width * 0.6, size.height * 0.4),
      paint,
    );

    // Curved roof (pagoda style)
    paint.color = color;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.05, size.height * 0.5);
    roofPath.quadraticBezierTo(
      size.width * 0.15, size.height * 0.35,
      size.width * 0.5, size.height * 0.25,
    );
    roofPath.quadraticBezierTo(
      size.width * 0.85, size.height * 0.35,
      size.width * 0.95, size.height * 0.5,
    );
    roofPath.lineTo(size.width * 0.8, size.height * 0.5);
    roofPath.quadraticBezierTo(
      size.width * 0.7, size.height * 0.4,
      size.width * 0.5, size.height * 0.35,
    );
    roofPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.4,
      size.width * 0.2, size.height * 0.5,
    );
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Roof ornament (top)
    paint.color = Colors.yellow.shade700;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.2),
      size.width * 0.05,
      paint,
    );

    // Pillars
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.5, size.width * 0.08, size.height * 0.4),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.67, size.height * 0.5, size.width * 0.08, size.height * 0.4),
      paint,
    );

    // Decorative details
    paint.color = Colors.yellow.shade600;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for canopy (baldacchino)
class CanopyPainter extends CustomPainter {
  final Color color;

  CanopyPainter({this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Poles (4 corners)
    paint.color = Colors.brown.shade700;
    final poleWidth = size.width * 0.06;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, poleWidth, size.height * 0.6),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.84, size.height * 0.3, poleWidth, size.height * 0.6),
      paint,
    );

    // Canopy fabric (curved top)
    paint.color = color;
    final canopyPath = Path();
    canopyPath.moveTo(size.width * 0.05, size.height * 0.3);
    canopyPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.15,
      size.width * 0.95, size.height * 0.3,
    );
    canopyPath.lineTo(size.width * 0.85, size.height * 0.35);
    canopyPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.25,
      size.width * 0.15, size.height * 0.35,
    );
    canopyPath.close();
    canvas.drawPath(canopyPath, paint);

    // Fabric drapes
    paint.color = color.withOpacity(0.7);
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.3 + i * 0.2);
      final drapePath = Path();
      drapePath.moveTo(x, size.height * 0.3);
      drapePath.quadraticBezierTo(
        x + size.width * 0.05, size.height * 0.5,
        x, size.height * 0.7,
      );
      drapePath.lineTo(x + size.width * 0.1, size.height * 0.7);
      drapePath.quadraticBezierTo(
        x + size.width * 0.05, size.height * 0.5,
        x + size.width * 0.1, size.height * 0.3,
      );
      drapePath.close();
      canvas.drawPath(drapePath, paint);
    }

    // Decorative top
    paint.color = Colors.yellow.shade700;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.04,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for king size bed (lettone king size)
class KingSizeBedPainter extends CustomPainter {
  final Color color;

  KingSizeBedPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Bed frame
    paint.color = Colors.brown.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.4, size.width * 0.9, size.height * 0.5),
      paint,
    );

    // Mattress
    paint.color = color;
    final mattressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.35, size.width * 0.84, size.height * 0.4),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(mattressRect, paint);

    // Mattress quilting lines
    paint.color = color.withOpacity(0.5);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.08, size.height * 0.35 + (size.height * 0.4 * i / 4)),
        Offset(size.width * 0.92, size.height * 0.35 + (size.height * 0.4 * i / 4)),
        paint,
      );
    }

    // Pillows
    paint.style = PaintingStyle.fill;
    paint.color = Colors.grey.shade200;
    final pillow1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.25, size.width * 0.3, size.height * 0.15),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(pillow1, paint);
    
    final pillow2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.25, size.width * 0.3, size.height * 0.15),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(pillow2, paint);

    // Headboard
    paint.color = Colors.brown.shade600;
    final headboardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.15, size.width * 0.9, size.height * 0.15),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(headboardRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
