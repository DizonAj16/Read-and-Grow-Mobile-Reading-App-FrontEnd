import 'package:flutter/material.dart';

class TheGreenFrogReadingPage extends StatelessWidget {
  const TheGreenFrogReadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'The Green Frog Reading Page',
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
