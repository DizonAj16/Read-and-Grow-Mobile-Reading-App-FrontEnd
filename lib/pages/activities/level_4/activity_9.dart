import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity9pages/the_owl_and_the_roaster_mpc.dart';
import 'activity9pages/the_owl_and_the_roaster_page.dart';

// Import your updated Activity 9 pages

class Activity9Page extends StatefulWidget {
  final VoidCallback? onCompleted; // ✅ Callback to notify TaskListPage

  const Activity9Page({super.key, this.onCompleted});

  @override
  _Activity9PageState createState() => _Activity9PageState();
}

class _Activity9PageState extends State<Activity9Page>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  bool _isLoading = false;

  late final List<Widget> _pages;
  List<bool> _pageCompleted = [false, false];

  @override
  void initState() {
    super.initState();
    _pages = [
      TheOwlAndTheRoosterPage(onCompleted: () => _markPageComplete(0)),
      TheOwlAndTheRoosterMultipleChoicePage(
        onCompleted: () => _markPageComplete(1),
      ),
    ];
  }

  /// ✅ Mark page complete
  void _markPageComplete(int pageIndex) {
    if (!_pageCompleted[pageIndex]) {
      setState(() {
        _pageCompleted[pageIndex] = true;
      });
    }
  }

  /// ✅ Save task status persistently
  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      await _showLoadingOverlay();
      setState(() => _currentPage--);
    }
  }

  Future<void> _goToNextPage() async {
    if (_currentPage < _pages.length - 1 && _pageCompleted[_currentPage]) {
      await _showLoadingOverlay();
      setState(() => _currentPage++);
    } else if (_currentPage == _pages.length - 1 &&
        _pageCompleted[_currentPage]) {
      // ✅ Save completion and notify TaskListPage
      await _saveTaskStatus("Task 9", "Completed");
      widget.onCompleted?.call();

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Great job!"),
              content: const Text(
                "You’ve completed all parts of this activity.",
              ),
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
  }

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

  Widget _buildNavigationBar(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final canGoNext = _pageCompleted[_currentPage] && !_isLoading;

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
            onPressed: canGoNext ? _goToNextPage : null,
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
