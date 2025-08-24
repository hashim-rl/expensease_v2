import 'package:flutter/material.dart';

class FamilyModeDashboardView extends StatelessWidget {
  const FamilyModeDashboardView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Mode')),
      body: const Center(child: Text('Family Mode Dashboard Screen')),
    );
  }
}