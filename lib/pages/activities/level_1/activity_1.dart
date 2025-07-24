import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity1pages/ag_family_page.dart';
import 'activity1pages/fill_in_the_blanks_page.dart';
import 'activity1pages/match_pictures_page.dart';
import 'activity1pages/match_words_to_pictures_page.dart';
import 'activity1pages/reading_page.dart';

class Activity1Page extends StatefulWidget {
  final VoidCallback? onCompleted;

  const Activity1Page({super.key, this.onCompleted});

  @override
  State<Activity1Page> createState() => _Activity1PageState();
}

class _Activity1PageState extends State<Activity1Page> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<bool> _completed;
  late List<Widget> _pages;
  late TTSHelper _ttsHelper;

  @override
  void initState() {
    super.initState();
    _ttsHelper = TTSHelper();
    _ttsHelper.init();

    _completed = List.filled(5, false);

    _pages = [
      AgFamilyPage(onCompleted: () => _markComplete(0)),
      MatchPicturesPage(onCompleted: () => _markComplete(1)),
      MatchWordsToPicturesPage(onCompleted: () => _markComplete(2)),
      FillInTheBlanksPage(onCompleted: () => _markComplete(3)),
      ReadingPage(onCompleted: () => _markComplete(4), ttsHelper: _ttsHelper),
    ];

    _loadProgress(); // ✅ Restore saved progress
  }

  /// ✅ Save current progress in SharedPreferences
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activity1_currentPage', _currentPage);
    await prefs.setStringList(
      'activity1_completed',
      _completed.map((e) => e.toString()).toList(),
    );
  }

  /// ✅ Load saved progress from SharedPreferences
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('activity1_currentPage');
    final completedList = prefs.getStringList('activity1_completed');

    if (savedPage != null &&
        completedList != null &&
        completedList.length == _completed.length) {
      setState(() {
        _currentPage = savedPage;
        _completed = completedList.map((e) => e == 'true').toList();
        _pageController.jumpToPage(_currentPage);
      });
    } else {
      _resetProgress(); // fallback if data is invalid
    }
  }

  void _resetProgress() {
    _currentPage = 0;
    _completed = List.filled(5, false);
    _pageController.jumpToPage(0);
  }

  void _markComplete(int index) {
    if (!_completed[index]) {
      setState(() {
        _completed[index] = true;
      });
      _saveProgress();
    }
  }

  void _goToPage(int index) {
    setState(() => _currentPage = index);
    _pageController.jumpToPage(index);
    _saveProgress();
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _completed[_currentPage] = false;
        _pages[_currentPage] = _recreatePage(_currentPage);
        _currentPage--;
      });
      _goToPage(_currentPage);
    }
  }

  void _goToNextPage() async {
    if (_currentPage < _pages.length - 1 && _completed[_currentPage]) {
      setState(() => _currentPage++);
      _goToPage(_currentPage);
    } else if (_currentPage == _pages.length - 1 && _completed[_currentPage]) {
      await _saveTaskStatus("Task 1", "Completed");
      await _clearProgress(); // ✅ Clear saved progress

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
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activity1_currentPage');
    await prefs.remove('activity1_completed');
  }

  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  Widget _recreatePage(int index) {
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
        return ReadingPage(
          onCompleted: () => _markComplete(4),
          ttsHelper: _ttsHelper,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _saveProgress(); // ✅ Save before closing
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
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
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
          Text(
            "Page ${_currentPage + 1} of ${_pages.length}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: (_completed[_currentPage]) ? _goToNextPage : null,
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
