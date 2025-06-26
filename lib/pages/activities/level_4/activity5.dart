import 'package:flutter/material.dart';

class Activity5Page extends StatefulWidget {
  const Activity5Page({super.key});

  @override
  State<Activity5Page> createState() => _Activity5PageState();
}

class _Activity5PageState extends State<Activity5Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 5')),
      body: Center(
        child: Text('This is Activity 5', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
