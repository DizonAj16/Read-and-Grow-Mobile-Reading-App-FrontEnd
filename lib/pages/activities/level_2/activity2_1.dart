import 'package:flutter/material.dart';

import 'activity2pages/drag_word_picture_page.dart';
import 'activity2pages/fill_in_blanks_page.dart';
import 'activity2pages/the_bird_mcq_page.dart';
import 'activity2pages/the_bird_page.dart';

class Activity2_1Page extends StatefulWidget {
  const Activity2_1Page({super.key});

  @override
  _Activity2_1PageState createState() => _Activity2_1PageState();
}

class _Activity2_1PageState extends State<Activity2_1Page> {
  int _currentPage = 0;

  final List<Widget> _pages = const [
    const TheBirdPage(),
    const TheBirdMultipleChoicePage(),
    const DragTheWordToPicturePage(),
    const FillInTheBlanksPage(),
  ];

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(child: _pages[_currentPage]),
              const SizedBox(height: 12),
              _buildNavigationBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            icon: const Icon(Icons.arrow_back_ios),
            label: const Text("Back"),
            style: _buttonStyle(),
          ),
          Text(
            "Page ${_currentPage + 1} of ${_pages.length}",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _currentPage < _pages.length - 1 ? _goToNextPage : null,
            icon: const Icon(Icons.arrow_forward_ios),
            label: const Text("Next"),
            style: _buttonStyle(),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
