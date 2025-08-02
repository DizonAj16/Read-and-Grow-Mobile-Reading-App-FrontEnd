import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Day4Pages/day_4_mpc.dart';
import 'Day4Pages/day_4_story_reading.dart';
import 'Day4Pages/day_5_essay_page.dart'; // ✅ Essay page

class Activity13Page extends StatefulWidget {
  final VoidCallback? onCompleted; // ✅ Callback for TaskListPage update

  const Activity13Page({super.key, this.onCompleted});

  @override
  State<Activity13Page> createState() => _Activity13PageState();
}

class _Activity13PageState extends State<Activity13Page> {
  int _currentPage = 0;
  bool _isLoading = false;

  late final List<Widget> _pages;
  final List<bool> _pageCompleted = [false, false, false]; // ✅ Track 3 pages

  @override
  void initState() {
    super.initState();
    _pages = [
      DayFourStoryPage(onCompleted: () => _markPageComplete(0)),
      DayFourMultipleChoicePage(onCompleted: () => _markPageComplete(1)),
      DayFiveEssayPage(onCompleted: () => _markPageComplete(2)), // ✅ Essay page
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

  /// ✅ Save Task 13 status in SharedPreferences
  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  Future<void> _goToPage(int newPage) async {
    if (_isLoading || newPage < 0 || newPage >= _pages.length) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _currentPage = newPage;
      _isLoading = false;
    });

    /// ✅ If last page completed → Save & show completion dialog
    if (newPage == _pages.length - 1 &&
        _pageCompleted.every((completed) => completed)) {
      await _saveTaskStatus("Task 13", "Completed");
      widget.onCompleted?.call();

      await Future.delayed(const Duration(milliseconds: 300));
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excellent Work!"),
        content: const Text("You have successfully completed all pages!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to TaskListPage
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _pages[_currentPage],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationBar(),
                ],
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final isLastPage = _currentPage == _pages.length - 1;
    final canGoNext =
        _pageCompleted[_currentPage] && !_isLoading; // ✅ Lock Next button

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
            onPressed: _currentPage > 0 && !_isLoading
                ? () => _goToPage(_currentPage - 1)
                : null,
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
            onPressed: canGoNext
                ? () => _goToPage(_currentPage + 1)
                : null,
            icon: Icon(
              isLastPage ? Icons.check : Icons.arrow_forward_ios,
              color: Colors.white,
            ),
            label: Text(isLastPage ? "Finish" : "Next"),
            style: _buttonStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.white.withOpacity(0.85),
        child: const Center(child: CircularProgressIndicator()),
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
