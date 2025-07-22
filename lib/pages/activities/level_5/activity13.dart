import 'package:flutter/material.dart';

import 'Day4Pages/day_4_mpc.dart';
import 'Day4Pages/day_4_story_reading.dart';
import 'Day4Pages/day_5_essay_page.dart'; // ✅ Import the essay page

class Activity13Page extends StatefulWidget {
  const Activity13Page({super.key});

  @override
  State<Activity13Page> createState() => _Activity13PageState();
}

class _Activity13PageState extends State<Activity13Page> {
  int _currentPage = 0;
  bool _isLoading = false;

  late final List<Widget> _pages;
  final List<bool> _pageCompleted = [false, false, false]; // ✅ now 3 pages

  @override
  void initState() {
    super.initState();
    _pages = [
      DayFourStoryPage(onCompleted: () => _markPageComplete(0)),
      DayFourMultipleChoicePage(onCompleted: () => _markPageComplete(1)),
      DayFiveEssayPage(
        onCompleted: () => _markPageComplete(2),
      ), // ✅ added essay
    ];
  }

  void _markPageComplete(int index) {
    if (!_pageCompleted[index]) {
      setState(() {
        _pageCompleted[index] = true;
      });
    }
  }

  Future<void> _goToPage(int newPage) async {
    if (_isLoading || newPage < 0 || newPage >= _pages.length) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _currentPage = newPage;
      _isLoading = false;
    });
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
                      transitionBuilder:
                          (child, animation) =>
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
                _currentPage > 0 && !_isLoading
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
            onPressed:
                _currentPage < _pages.length - 1 &&
                        !_isLoading &&
                        _pageCompleted[_currentPage]
                    ? () => _goToPage(_currentPage + 1)
                    : null,
            icon: const Icon(Icons.arrow_forward_ios),
            label: const Text("Next"),
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
