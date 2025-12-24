import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';

class ScoreGridCell extends StatelessWidget {
  static const double width = 240;
  static const double height = 310;

  final Score score;

  const ScoreGridCell({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: width, height: height, child: Placeholder());
  }
}
