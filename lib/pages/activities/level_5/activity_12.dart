import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your updated Activity 12 pages
import 'Day3Pages/day_3_mpc.dart';
import 'Day3Pages/day_3_story_reading.dart';

class Activity12Page extends StatefulWidget {
  final VoidCallback? onCompleted; // ✅ Callback to notify TaskListPage

  const Activity12Page({super.key, this.onCompleted});

  @override
  State<Activity12Page> createState() => _Activity12PageState();
}

class _Activity12PageState extends State<Activity12Page> {
  int _currentPage = 0;
  bool _isLoading = false;

  late final List<Widget> _pages;
  final List<bool> _pageCompleted = [false, false]; // ✅ Track completion

  @override
  void initState() {
    super.initState();
    _pages = [
      DayThreeStoryPage(onCompleted: () => _markPageComplete(0)),
      DayThreeMultipleChoicePage(onCompleted: () => _markPageComplete(1)),
    ];
  }

  /// ✅ Mark page as completed
  void _markPageComplete(int index) {
    if (!_pageCompleted[index]) {
      setState(() {
        _pageCompleted[index] = true;
      });
    }
  }

  /// ✅ Save Task completion to SharedPreferences
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

    /// ✅ If last page is reached and all completed → save & notify
    if (newPage == _pages.length - 1 &&
        _pageCompleted.every((completed) => completed)) {
      await _saveTaskStatus("Task 12", "Completed");
      widget.onCompleted?.call();

      await Future.delayed(const Duration(milliseconds: 300));
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Great job!"),
        content: const Text("You’ve completed all parts of this activity."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to TaskListPage
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
        _pageCompleted[_currentPage] && !_isLoading; // ✅ Lock until completed

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
              size: 18,
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
