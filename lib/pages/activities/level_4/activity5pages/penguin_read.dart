import 'package:flutter/material.dart';

class PenguinsReadPage extends StatelessWidget {
  const PenguinsReadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penguins Read')),
      body: const Center(child: Text('Penguins Read Page')),
    );
  }
}
