import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_metaball/flutter_metaball.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int voxelSize = 2;
  int nMetaball = 5;
  double minRadius = 20;
  double maxRadius = 30;
  double minSpin = 2;
  double maxSpin = 4;
  double width = 400;
  double height = 400;
  bool attraction = false;
  bool addMass = true;

  List<MetaballParams> metaballs = [];

  /// define the spin of each metaball
  List<Offset> spins = [];

  @override
  void initState() {
    super.initState();

    // set random metaball
    metaballs = List.generate(
      nMetaball,
      (index) => MetaballParams(
          Offset(Random().nextDouble() * width, Random().nextDouble() * height),
          Random().nextDouble() * (maxRadius - minRadius) + minRadius,
          color: Colors.accents[Random().nextInt(Colors.accents.length)]),
    );

    // set random spin
    spins = List.generate(
        nMetaball,
        (index) => Offset(
              (Random().nextDouble() * (maxSpin - minSpin) - minSpin) *
                  (Random().nextInt(2) * 2 - 1), // <- random sign
              (Random().nextDouble() * (maxSpin - minSpin) - minSpin) *
                  (Random().nextInt(2) * 2 - 1), // <- random sign
            ));



    WidgetsBinding.instance.addPostFrameCallback(_postFrameCallback);
  }

  _postFrameCallback(Duration timeStamp) {
    // check if the metaballs are going out of view
    for (int n = 0; n < nMetaball; ++n) {
      double dx = metaballs[n].center.dx + spins[n].dx;
      double dy = metaballs[n].center.dy + spins[n].dy;
      if (dx > width || dx <= 0) {
        spins[n] = Offset(spins[n].dx * -1, spins[n].dy);
      }
      if (dy > height || dy <= 0) {
        spins[n] = Offset(spins[n].dx, spins[n].dy * -1);
      }

      metaballs[n].center += spins[n];
    }

    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback(_postFrameCallback);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // return the angle between 0 and 2pi
  double myAtan2(double y, double x) {
    double ret;
    ret = atan2(y, x);
    if (ret < 0) ret += pi * 2;
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metaball example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: Listener(
              // add a metaball under the pointer when pressed,
              // remove it when released
              onPointerDown: (e) {
                metaballs.add(
                  MetaballParams(e.localPosition, 20,
                      isAddingMass: addMass,
                      color: const Color.fromARGB(255, 0, 0, 0)),
                );
              },
              onPointerUp: (e) => metaballs.removeLast(),
              onPointerMove: (e) {
                metaballs.last.center = e.localPosition;

                // attract the balls to pointer position?
                if (attraction) {
                  for (int n = 0; n < nMetaball; ++n) {
                    double angle = myAtan2(
                        e.localPosition.dy - metaballs[n].center.dy,
                        e.localPosition.dx - metaballs[n].center.dx);
                    spins[n] = Offset(
                      cos(angle) * (Random().nextDouble() * maxSpin + minSpin),
                      sin(angle) * (Random().nextDouble() * maxSpin + minSpin),
                    );
                  }
                }
                if (mounted) setState(() {});
              },
              child: Metaball(
                balls: metaballs,
                voxel: voxelSize,
              ),
            ),
          ),
          const SizedBox(height: 30),

          /// CheckBoxes
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: attraction,
                    onChanged: (_) => attraction = !attraction,
                  ),
                  const Text('pointer attraction'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: addMass,
                    onChanged: (_) => addMass = !addMass,
                  ),
                  const Text('pointer add/substract mass'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
