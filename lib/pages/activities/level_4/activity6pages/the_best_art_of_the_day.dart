import 'package:flutter/material.dart';

class TheBestArtOfTheDayPage extends StatelessWidget {
  const TheBestArtOfTheDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'The Best Art of the Day - Reading Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
