import 'package:flutter/material.dart';

// Import your Activity 10 pages
import 'Day2Pages/day_2_mpc.dart';
import 'Day2Pages/day_2_story_story_reading.dart';

class Activity11Page extends StatefulWidget {
  const Activity11Page({super.key});

  @override
  State<Activity11Page> createState() => _Activity11PageState();
}

class _Activity11PageState extends State<Activity11Page> {
  int _currentPage = 0;
  bool _isLoading = false;

  late final List<Widget> _pages;
  final List<bool> _pageCompleted = [false, false]; // track completion

  @override
  void initState() {
    super.initState();

    _pages = [
      Day2StoryPage(onCompleted: () => _markPageComplete(0)),
      Day2MultipleChoicePage(onCompleted: () => _markPageComplete(1)),
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
                        _pageCompleted[_currentPage] // lock until completed
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
