import 'package:flutter/material.dart';
import 'class_info.dart';


class ClassDetailsPage extends StatefulWidget {
  final Map<String, dynamic> classDetails;

  const ClassDetailsPage({super.key, required this.classDetails});

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final classId = widget.classDetails['id'] ?? widget.classDetails['class_name'];
    final className = widget.classDetails['class_name'] ?? 'Class';
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Hero(
                tag: 'class-title-$classId',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    className,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'class-bg-$classId',
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/background/classroombg.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          children: [
            ClassInfoPage(classDetails: widget.classDetails), // 🆕 Class Info tab
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Class Info"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Students"),
        ],
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
