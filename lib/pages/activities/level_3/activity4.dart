import 'package:flutter/material.dart';

import 'activity4pages/drag_the_word_to_pic.dart';
import 'activity4pages/fill_in_the_blanks.dart';
import 'activity4pages/the_frog_mpc.dart';
import 'activity4pages/the_green_frog_reading_page.dart';

class Activity4Page extends StatefulWidget {
  const Activity4Page({super.key});

  @override
  _Activity4PageState createState() => _Activity4PageState();
}

class _Activity4PageState extends State<Activity4Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  late List<bool> _completedPages;

  @override
  void initState() {
    super.initState();
    _completedPages = List.generate(_pages.length, (_) => false);
  }

  void _markPageComplete(int index) {
    if (!_completedPages[index]) {
      setState(() {
        _completedPages[index] = true;
      });
    }
  }

  List<Widget> get _pages => [
    TheGreenFrogReadingPage(onCompleted: () => _markPageComplete(0)),
    GreenFrogMultipleChoicePage(onCompleted: () => _markPageComplete(1)),
    DragTheWordToPicturePage(onCompleted: () => _markPageComplete(2)),
    FillInTheBlanksPage(onCompleted: () => _markPageComplete(3)),
  ];

  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      await _showLoadingOverlay();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _goToNextPage() async {
    if (_currentPage < _pages.length - 1 && _completedPages[_currentPage]) {
      await _showLoadingOverlay();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  Future<void> _showLoadingOverlay() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
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

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
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
            onPressed:
                _currentPage < _pages.length - 1 &&
                        !_isLoading &&
                        _completedPages[_currentPage]
                    ? _goToNextPage
                    : null,
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
