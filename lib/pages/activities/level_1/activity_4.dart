import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity4pages/drag_the_word_to_pic.dart';
import 'activity4pages/fill_in_the_blanks.dart';
import 'activity4pages/green_frog_words.dart';
import 'activity4pages/instruction_page.dart';
import 'activity4pages/the_frog_mpc.dart';
import 'activity4pages/the_green_frog_reading_page.dart';

class Activity4Page extends StatefulWidget {
  final VoidCallback? onCompleted; // ✅ Notify TaskListPage when completed

  const Activity4Page({super.key, this.onCompleted});

  @override
  _Activity4PageState createState() => _Activity4PageState();
}

class _Activity4PageState extends State<Activity4Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  late List<bool> _completedPages;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FrogInstructionPage(onCompleted: () => _markPageComplete(0)),
      GreenFrogPage(onCompleted: () => _markPageComplete(1)),
      TheGreenFrogReadingPage(onCompleted: () => _markPageComplete(2)),
      GreenFrogMultipleChoicePage(onCompleted: () => _markPageComplete(3)),
      DragTheWordToPicturePage(onCompleted: () => _markPageComplete(4)),
      FillInTheBlanksPage(onCompleted: () => _markPageComplete(5)),
    ];
    _completedPages = List.filled(
      _pages.length,
      false,
    ); // ✅ Fix: match page count
  }

  /// ✅ Mark a page complete
  void _markPageComplete(int index) {
    if (!_completedPages[index]) {
      setState(() {
        _completedPages[index] = true;
      });
    }
  }

  /// ✅ Save task status to SharedPreferences
  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  /// ✅ Go to Previous Page
  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      await _showLoadingOverlay();
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ✅ Go to Next Page or Finish Activity
  Future<void> _goToNextPage() async {
    if (_currentPage < _pages.length - 1 && _completedPages[_currentPage]) {
      await _showLoadingOverlay();
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == _pages.length - 1 &&
        _completedPages[_currentPage]) {
      await _saveTaskStatus("Task 4", "Completed");
      widget.onCompleted?.call();

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
                    Navigator.pop(context); // Go back to TaskListPage
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// ✅ Loading Overlay Animation
  Future<void> _showLoadingOverlay() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pages.length,
                    itemBuilder: (_, index) => _pages[index],
                  ),
                ),
                const SizedBox(height: 12),
                _buildNavigationBar(context),
              ],
            ),
            if (_isLoading)
              AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ✅ Bottom Navigation Bar
  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
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
            onPressed:
                _currentPage > 0 && !_isLoading ? _goToPreviousPage : null,
            icon: Icon(
              Icons.arrow_back_ios,
              color: _currentPage > 0 ? Colors.red : Colors.grey,
              size: 18,
            ),
            label: const Text("Back"),
            style: _buttonStyle(),
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
            onPressed:
                !_isLoading && _completedPages[_currentPage]
                    ? _goToNextPage
                    : null,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            label: const Text("Next"),
            style: _buttonStyle(),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
