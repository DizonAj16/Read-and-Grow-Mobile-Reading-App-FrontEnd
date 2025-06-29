import 'package:flutter/material.dart';

import 'activity1pages/ag_family_page.dart';
import 'activity1pages/fill_in_the_blanks_page.dart';
import 'activity1pages/match_pictures_page.dart';
import 'activity1pages/match_words_to_pictures_page.dart';
import 'activity1pages/reading_page.dart';

class Activity1Page extends StatefulWidget {
  const Activity1Page({super.key});

  @override
  State<Activity1Page> createState() => _Activity1PageState();
}

class _Activity1PageState extends State<Activity1Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<bool> _completed;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  void _initPages() {
    _pages = List.generate(5, (index) => _createPage(index));
    _completed = List.filled(_pages.length, false);
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return AgFamilyPage(onCompleted: () => _markComplete(0));
      case 1:
        return MatchPicturesPage(onCompleted: () => _markComplete(1));
      case 2:
        return MatchWordsToPicturesPage(onCompleted: () => _markComplete(2));
      case 3:
        return FillInTheBlanksPage(onCompleted: () => _markComplete(3));
      case 4:
        return ReadingPage(onCompleted: () => _markComplete(4));
      default:
        return const SizedBox.shrink();
    }
  }

  void _markComplete(int index) {
    if (!_completed[index]) {
      setState(() {
        _completed[index] = true;
      });
    }
  }

  void _goToPage(int index) {
    setState(() => _currentPage = index);
    _pageController.jumpToPage(index);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _completed[_currentPage] = false;
        _pages[_currentPage] = _createPage(_currentPage); // Reset page
        _currentPage--;
      });
      _goToPage(_currentPage);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1 && _completed[_currentPage]) {
      setState(() => _currentPage++);
      _goToPage(_currentPage);
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
        child: Column(
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
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
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
          // BACK BUTTON
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

          // PAGE STATUS
          Text(
            "Page ${_currentPage + 1} of ${_pages.length}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red,
            ),
          ),

          // NEXT BUTTON
          ElevatedButton.icon(
            onPressed:
                (_currentPage < _pages.length - 1 && _completed[_currentPage])
                    ? _goToNextPage
                    : null,
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
