library flutter_metaball;

import 'package:flutter/material.dart';

class MetaballParams {
  /// Position
  Offset mCenter;
  Offset get center => mCenter;
  set center(Offset center) {
    mCenter = center;
  }

  /// The strenght defines also the radius
  final double radius;

  /// add mass if true, else act as a black-hole
  final bool addMass;

  MetaballParams(this.mCenter, this.radius, {this.addMass = true});
}

class Metaball extends StatelessWidget {
  /// the more voxel is the more inaccurate will be.
  /// Define the square edge where computation will be made
  final int voxel;

  final List<MetaballParams> balls;

  const Metaball({
    super.key,
    required this.voxel,
    required this.balls,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: MetaballPainter(balls: balls, voxel: voxel),
      ),
    );
  }
}

class MetaballPainter extends CustomPainter {
  /// the more is voxel the more inaccurate will be.
  /// Define the square edge where computation will be made
  final int voxel;

  final List<MetaballParams> balls;

  MetaballPainter({
    this.voxel = 20,
    required this.balls,
  })  : assert(voxel > 0, 'voxel must be >0 !'),
        assert(balls.isNotEmpty, 'some metaball(s) should be provided!');

  @override
  void paint(Canvas canvas, Size size) {
    int rows = 0;
    int cols = 0;
    List<List<double>> matrix = List.generate(size.height ~/ voxel + 1,
        (index) => List.generate(size.width ~/ voxel + 1, (index) => 0.0));
    final Paint paint = Paint();

    paint.color = const Color(0xFFe0e0e0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    double f = 0;
    for (int y = 0; y < size.height; y += voxel, ++cols) {
      rows = 0;
      for (int x = 0; x < size.width; x += voxel, ++rows) {
        f = 0;
        for (int n = 0; n < balls.length; ++n) {
          if (balls[n].addMass) {
            f += balls[n].radius /
                (Offset(balls[n].center.dx - x, balls[n].center.dy - y)
                        .distance +
                    0.00001);
            if (matrix[cols][rows] < f) matrix[cols][rows] = f;
          } else {
            f -= balls[n].radius /
                (Offset(balls[n].center.dx - x, balls[n].center.dy - y)
                    .distance +
                    0.00001);
            if (matrix[cols][rows] > f) matrix[cols][rows] = f;
          }
        }

        if (matrix[cols][rows] > 1.0) {
          paint.color = Color.fromARGB(
              255, 0, 192 + (64 * matrix[cols][rows]).toInt(), 0);
          canvas.drawCircle(Offset(1.0 * x, 1.0 * y), 2, paint);
        }
      }
    }

    paint.color = Colors.yellow;
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    for (int n = 0; n < balls.length; n++) {
      canvas.drawCircle(balls[n].center, balls[n].radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
