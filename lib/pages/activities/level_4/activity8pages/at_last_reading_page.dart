import 'package:flutter/material.dart';

class AtLastReadingPage extends StatelessWidget {
  const AtLastReadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'At last - Reading Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
