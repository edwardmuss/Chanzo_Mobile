import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double width;
  final ShapeBorder shape;

  const ShimmerWidget.rectangular({
    this.height = double.infinity,
    this.width = double.infinity,
    super.key,
  }) : shape = const RoundedRectangleBorder();

  const ShimmerWidget.circular({
    this.width = double.infinity,
    this.height = double.infinity,
    super.key,
    this.shape = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      height: height,
      width: width,
      decoration: ShapeDecoration(
        color: Colors.grey[400]!,
        shape: shape,
      ),
    ),
  );
}
