library flutter_metaball;

import 'package:flutter/foundation.dart';
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
  final bool isAddingMass;

  final Color color;

  MetaballParams(
    this.mCenter,
    this.radius, {
    this.isAddingMass = true,
    this.color = Colors.black,
  });
}

class Voxel {
  /// each single ball forces
  List<double> ballForces;

  /// all balls summed force
  double totForce;

  /// resulting color mixed by the ball forces
  Color color;

  Voxel(this.color, this.totForce, this.ballForces);
}

class Metaball extends StatelessWidget {
  /// the more voxel is the more inaccurate will be.
  /// Define the square edge where computation will be made
  final int voxel;

  final List<MetaballParams> balls;

  const Metaball({
    super.key,
    required this.balls,
    required this.voxel,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: MetaballPainter(balls: balls, voxelEdge: voxel),
      ),
    );
  }
}

class MetaballPainter extends CustomPainter {
  /// the more is voxel the more inaccurate will be.
  /// Define the square edge where computation will be made
  final int voxelEdge;

  final List<MetaballParams> balls;

  MetaballPainter({
    this.voxelEdge = 20,
    required this.balls,
  })  : assert(voxelEdge > 0, 'voxelEdge must be >0 !'),
        assert(balls.isNotEmpty, 'some metaball(s) should be provided!');

  // TODO (maybe) run into N isolates
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    int rows = 0;
    int cols = 0;
    List<List<Voxel>> voxels = List.generate(
        size.height ~/ voxelEdge + 1,
        (index) => List.generate(
            size.width ~/ voxelEdge + 1,
            (index) => Voxel(const Color(0x00000000), 0.0,
                List.generate(balls.length, (index) => 0.0))));

    paint.color = const Color(0xFFe8e8e8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // calculate single and total force applied by all balls in the voxel
    // and their color
    for (int y = 0; y < size.height; y += voxelEdge, ++cols) {
      rows = 0;
      for (int x = 0; x < size.width; x += voxelEdge, ++rows) {
        voxels[cols][rows].totForce = 0.0;

        for (int n = 0; n < balls.length; ++n) {
          double f = 0.0;
          f = balls[n].radius /
              (Offset(balls[n].center.dx - x, balls[n].center.dy - y).distance +
                  0.00001);

          if (balls[n].isAddingMass) {
            voxels[cols][rows].totForce += f;
            voxels[cols][rows].ballForces[n] = f;
          } else {
            voxels[cols][rows].totForce -= f;
            voxels[cols][rows].ballForces[n] = -f;
          }
        }

        // now this [Voxel] has been set. Time to find its color
        paint.color = Colors.black;
        if (voxels[cols][rows].totForce >= 1.0) {
          Color color = const Color(0xffffffff);

          for (int n = 0; n < balls.length; ++n) {
            // negative force if the ball is sucking,
            // positive if the ball is throwing out (mathematically speaking)
            voxels[cols][rows].ballForces[n] =
                clampDouble(voxels[cols][rows].ballForces[n], -1.0, 1.0);

            if (voxels[cols][rows].ballForces[n] >= 0) {
              color = Color.lerp(
                  color, balls[n].color, voxels[cols][rows].ballForces[n])!;
            } else {
              Color.lerp(const Color(0x00000000), balls[n].color,
                  voxels[cols][rows].ballForces[n].abs())!;
            }
          }
          paint.color = color;
          canvas.drawRect(
              Rect.fromCircle(
                  center: Offset(x.toDouble(), y.toDouble()),
                  radius: voxelEdge.toDouble()),
              paint);
        }
      }
    }

    paint.color = Colors.black;
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    for (int n = 0; n < balls.length; n++) {
      canvas.drawCircle(balls[n].center, balls[n].radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
