import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCalendar extends StatelessWidget {
  const ShimmerCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            child: Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
