import 'package:flutter/material.dart';

class PdfPreviewView extends StatelessWidget {
  const PdfPreviewView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: const Center(child: Text('PDF Generation & Preview Screen')),
    );
  }
}