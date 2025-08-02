import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity7pages/icfs_mpc.dart';
import 'activity7pages/icfs_reading_page.dart';

class Activity7Page extends StatefulWidget {
  final VoidCallback? onCompleted;

  const Activity7Page({super.key, this.onCompleted});

  @override
  _Activity7PageState createState() => _Activity7PageState();
}

class _Activity7PageState extends State<Activity7Page>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  bool _isLoading = false;
  bool _activityMarkedComplete = false;

  late List<bool> _completed;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _completed = List.filled(2, false);

    _pages = [
      IcfsReadingPage(onCompleted: () => _markPageCompleted(0)),
      IcfsMultipleChoicePage(onCompleted: () => _markPageCompleted(1)),
    ];
  }

  void _markPageCompleted(int index) {
    if (!_completed[index]) {
      setState(() {
        _completed[index] = true;
      });
      print('✅ Page $index completed');
    }
  }

  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
    print('🔒 Saved $title as $status');
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      await _showLoadingOverlay();
      setState(() => _currentPage--);
    }
  }

  Future<void> _goToNextPage() async {
    if (_currentPage < _pages.length - 1 && _completed[_currentPage]) {
      await _showLoadingOverlay();
      setState(() => _currentPage++);
    } else if (_currentPage == _pages.length - 1 &&
        _completed[_currentPage] &&
        !_activityMarkedComplete) {
      _activityMarkedComplete = true;
      await _saveTaskStatus("Task 7", "Completed");
      widget.onCompleted?.call();

      if (context.mounted) {
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
                  _buildNavigationBar(),
                ],
              ),
            ),
            if (_isLoading)
              AnimatedOpacity(
                opacity: 1.0,
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

  Widget _buildNavigationBar() {
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
