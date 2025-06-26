import 'package:flutter/material.dart';

class TheFrogMultipleChoicePage extends StatelessWidget {
  const TheFrogMultipleChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'The Frog Multiple Choice Page',
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
