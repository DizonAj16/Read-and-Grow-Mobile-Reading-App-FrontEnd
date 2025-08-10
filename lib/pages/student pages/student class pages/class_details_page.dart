import 'package:flutter/material.dart';
import 'tabs/student_list_page.dart';
import 'tabs/materials_page.dart';
import 'tabs/teacher_info_page.dart';

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
    required this.classId,
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
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final double offset = _scrollController.offset;
    setState(() {
      _appBarOpacity = (offset / 100).clamp(0.0, 1.0);
    });
  }

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
    final theme = Theme.of(context);
    final colors = [
      Colors.pink[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    final avatarColor = colors[widget.className.hashCode % colors.length];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: theme.colorScheme.primary.withOpacity(_appBarOpacity),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              centerTitle: true,
              title: Hero(
                tag: 'class-title-${widget.className}',
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedOpacity(
                    opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.className,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
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
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                      child: widget.backgroundImage.startsWith('http')
                          ? Image.network(
                              widget.backgroundImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: avatarColor.withOpacity(0.2),
                              ),
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
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          widget.className,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 8),
                        // Text(
                        //   'Taught by ${widget.teacherName}',
                        //   style: TextStyle(
                        //     color: Colors.white.withOpacity(0.9),
                        //     fontSize: 16,
                        //     shadows: [
                        //       const Shadow(
                        //         color: Colors.black45,
                        //         blurRadius: 4,
                        //         offset: Offset(0, 1),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
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
            MaterialsPage(classId: widget.classId),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: theme.scaffoldBackgroundColor,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_outlined),
                ),
                label: "Materials",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_outline),
                ),
                label: "Classmates",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline),
                ),
                label: "Teacher",
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}