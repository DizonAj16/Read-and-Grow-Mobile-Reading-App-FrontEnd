import 'package:flutter/material.dart';
import 'student_list_page.dart';
import 'task_list_page.dart';
import 'teacher_info_page.dart';

class ClassDetailsPage extends StatefulWidget {
  final int classId;
  final String className;
  final String backgroundImage;
  final String teacherName;
  final String teacherEmail;
  final String teacherPosition;
  final String? teacherAvatar;

  const ClassDetailsPage({
    super.key,
    required this.classId, // ✅ add this
    required this.className,
    required this.backgroundImage,
    required this.teacherName,
    required this.teacherEmail,
    required this.teacherPosition,
    this.teacherAvatar,
  });

  @override
  _ClassDetailsPageState createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Hero(
                    tag: 'class-title-${widget.className}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'class-bg-${widget.className}',
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.25),
                            BlendMode.darken,
                          ),
                          child:
                              widget.backgroundImage.startsWith('http')
                                  ? Image.network(
                                    widget.backgroundImage,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.asset(
                                    widget.backgroundImage,
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.6, 1.0],
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
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            const TaskListPage(),
            StudentListPage(classId: widget.classId),
            TeacherInfoPage(
              teacherName: widget.teacherName,
              teacherEmail: widget.teacherEmail,
              teacherPosition: widget.teacherPosition,
              teacherAvatar: widget.teacherAvatar,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Classmates"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Teacher"),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
