import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity2pages/cat_and_rat_page.dart';
import 'activity2pages/draw_animals_page.dart';
import 'activity2pages/fill_in_the_blanks.dart';
import 'activity2pages/matching_exercise_page.dart';

class Activity2Page extends StatefulWidget {
  final VoidCallback? onCompleted; // ✅ To notify TaskListPage when done

  const Activity2Page({super.key, this.onCompleted});

  @override
  State<Activity2Page> createState() => _Activity2PageState();
}

class _Activity2PageState extends State<Activity2Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<bool> _pageCompleted;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageCompleted = List.filled(4, false);

    _pages = [
      CatAndRatPage(onCompleted: () => _markPageComplete(0)),
      MatchingExercisePage(onCompleted: () => _markPageComplete(1)),
      FillInTheBlanksPage(onCompleted: () => _markPageComplete(2)),
      DrawAnimalsPage(onCompleted: () => _markPageComplete(3)),
    ];
  }

  /// ✅ Mark a page as completed
  void _markPageComplete(int index) {
    if (!_pageCompleted[index]) {
      setState(() {
        _pageCompleted[index] = true;
      });
    }
  }

  /// ✅ Go to Next Page or Complete Activity
  void _goToNextPage() async {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == _pages.length - 1 &&
        _pageCompleted[_currentPage]) {
      await _saveTaskStatus(
        "Task 2",
        "Completed",
      ); // ✅ Save to SharedPreferences
      widget.onCompleted?.call(); // ✅ Notify TaskListPage

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Activity Complete!'),
              content: const Text('You have completed all the pages.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to TaskListPage
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// ✅ Go to Previous Page
  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ✅ Save Task Status
  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (_, index) => _pages[index],
              ),
            ),
            const SizedBox(height: 12),
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  /// ✅ Bottom Navigation Bar (UI Consistent with Activity1)
  Widget _buildNavigationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            icon: Icon(
              Icons.arrow_back_ios,
              color: _currentPage > 0 ? Colors.red : Colors.grey,
              size: 18,
            ),
            label: const Text("Back"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          Text(
            "Page ${_currentPage + 1} of ${_pages.length}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: (_pageCompleted[_currentPage]) ? _goToNextPage : null,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            label: const Text("Next"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
