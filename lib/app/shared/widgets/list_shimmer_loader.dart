import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ListShimmerLoader extends StatelessWidget {
  const ListShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 6, // Show 6 shimmering items
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white),
              title: Container(
                height: 16,
                width: 150,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: 100,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}