import 'package:flutter/material.dart';

class DragTheWordToPicturePage extends StatelessWidget {
  const DragTheWordToPicturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Drag The Word To Picture Page',
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
