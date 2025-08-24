import 'package:flutter/material.dart';

class MonthlyReportView extends StatelessWidget {
  const MonthlyReportView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report')),
      body: const Center(child: Text('Detailed Monthly Report Screen')),
    );
  }
}