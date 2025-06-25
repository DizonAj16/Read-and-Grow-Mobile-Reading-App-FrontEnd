import 'package:flutter/material.dart';

class Activity4Page extends StatefulWidget {
  const Activity4Page({super.key});

  @override
  State<Activity4Page> createState() => _Activity4PageState();
}

class _Activity4PageState extends State<Activity4Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 4')),
      body: Center(
        child: Text('This is Activity 4', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
