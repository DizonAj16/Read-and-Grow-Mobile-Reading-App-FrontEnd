import 'package:flutter/material.dart';

class Activity6Page extends StatefulWidget {
  const Activity6Page({super.key});

  @override
  State<Activity6Page> createState() => _Activity6PageState();
}

class _Activity6PageState extends State<Activity6Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 6')),
      body: Center(
        child: Text('This is Activity 6', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
