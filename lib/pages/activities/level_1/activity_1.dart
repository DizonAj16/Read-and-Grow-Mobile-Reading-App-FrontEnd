import 'package:flutter/material.dart';

import 'activity1pages/ag_family_page.dart';
import 'activity1pages/fill_in_the_blanks_page.dart';
import 'activity1pages/match_pictures_page.dart';
import 'activity1pages/match_words_to_pictures_page.dart';
import 'activity1pages/reading_page.dart';

class Activity1Page extends StatefulWidget {
  const Activity1Page({super.key});

  @override
  _Activity1PageState createState() => _Activity1PageState();
}

class _Activity1PageState extends State<Activity1Page>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const AgFamilyPage(),
    const MatchPicturesPage(),
    const MatchWordsToPicturesPage(),
    const FillInTheBlanksPage(),
    const ReadingPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeController);
  }

  Future<void> _goToPage(int newPage) async {
    if (newPage < 0 || newPage >= _pages.length) return;

    setState(() => _isLoading = true);
    await _fadeController.forward(); // Fade to white

    await Future.delayed(const Duration(milliseconds: 300)); // Simulate loading
    setState(() => _currentPage = newPage);

    await _fadeController.reverse(); // Fade back to page
    setState(() => _isLoading = false);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            FadeTransition(
              opacity: _fadeAnimation,
              child:
                  _isLoading
                      ? Container(
                        color: Colors.white,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
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
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
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
            onPressed: _currentPage < _pages.length - 1 ? _goToNextPage : null,
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
