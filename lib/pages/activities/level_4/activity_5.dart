import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity5pages/drag_the_word_to_picture.dart';
import 'activity5pages/fill_in_the_blanks.dart';
import 'activity5pages/penguin_mpc.dart';
import 'activity5pages/penguin_read.dart';

class Activity5Page extends StatefulWidget {
  final VoidCallback? onCompleted; // ✅ Notifies TaskListPage when complete

  const Activity5Page({super.key, this.onCompleted});

  @override
  _Activity5PageState createState() => _Activity5PageState();
}

class _Activity5PageState extends State<Activity5Page> {
  int _currentPage = 0;
  bool _isLoading = false;
  late List<bool> _completed;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _completed = List.filled(4, false);
    _pages = [
      PenguinsPage(onCompleted: () => _markPageCompleted(0)),
      PenguinMultipleChoicePage(onCompleted: () => _markPageCompleted(1)),
      DragTheWordToPicturePage(onCompleted: () => _markPageCompleted(2)),
      FillInTheBlanksPage(onCompleted: () => _markPageCompleted(3)),
    ];
  }

  /// ✅ Mark page as completed
  void _markPageCompleted(int index) {
    if (!_completed[index]) {
      setState(() {
        _completed[index] = true;
      });
    }
  }

  /// ✅ Save task completion status
  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  /// ✅ Go to previous page
  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      await _showLoadingOverlay();
      setState(() => _currentPage--);
    }
  }

  /// ✅ Go to next page or finish
  Future<void> _goToNextPage() async {
    if (_currentPage < _pages.length - 1 && _completed[_currentPage]) {
      await _showLoadingOverlay();
      setState(() => _currentPage++);
    } else if (_currentPage == _pages.length - 1 && _completed[_currentPage]) {
      await _saveTaskStatus("Task 5", "Completed");
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
                    Navigator.pop(context); // Return to TaskListPage
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// ✅ Loading overlay animation
  Future<void> _showLoadingOverlay() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isLoading = false);
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
                  Expanded(child: _pages[_currentPage]),
                  const SizedBox(height: 12),
                  _buildNavigationBar(context),
                ],
              ),
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

  /// ✅ Bottom navigation bar
  Widget _buildNavigationBar(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final canGoNext = _completed[_currentPage] && !_isLoading;

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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: canGoNext ? _goToNextPage : null,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            label: Text(isLastPage ? "Finish" : "Next"),
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
