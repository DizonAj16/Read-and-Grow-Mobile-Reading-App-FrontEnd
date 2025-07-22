import 'package:flutter/material.dart';

import 'activity2pages/cat_and_rat_page.dart';
import 'activity2pages/draw_animals_page.dart';
import 'activity2pages/fill_in_the_blanks.dart';
import 'activity2pages/matching_exercise_page.dart';

class Activity2Page extends StatefulWidget {
  const Activity2Page({super.key});

  @override
  State<Activity2Page> createState() => _Activity2PageState();
}

class _Activity2PageState extends State<Activity2Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Tracks if each page is completed
  final List<bool> _pageCompleted = [false, false, false, false];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      CatAndRatPage(onCompleted: () => _markPageComplete(0)),
      MatchingExercisePage(onCompleted: () => _markPageComplete(1)),
      FillInTheBlanksPage(onCompleted: () => _markPageComplete(2)),
      DrawAnimalsPage(onCompleted: () => _markPageComplete(3)),
    ];
  }

  void _markPageComplete(int index) {
    if (!_pageCompleted[index]) {
      setState(() {
        _pageCompleted[index] = true;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) => _pages[index],
            ),
          ),
          // Footer with navigation and page info
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                ElevatedButton.icon(
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Back"),
                ),
                // Page number indicator
                Text(
                  "Page ${_currentPage + 1} of ${_pages.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Next Button (only active when current page is completed)
                ElevatedButton.icon(
                  onPressed:
                      (_pageCompleted[_currentPage] &&
                              _currentPage < _pages.length - 1)
                          ? _goToNextPage
                          : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
