import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../list_of_quiz_and_lessons.dart';
import 'tabs/student_list_page.dart';
import 'tabs/materials_page.dart';
import 'tabs/teacher_info_page.dart';

class ClassDetailsPage extends StatefulWidget {
  final String classId;
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
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  final user = Supabase.instance.client.auth.currentUser;



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
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _getAvatarColor(widget.className);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(
                context,
                theme,
                avatarColor,
                innerBoxIsScrolled,
              ),
            ],
        body: _buildPageView(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    Color avatarColor,
    bool innerBoxIsScrolled,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: theme.colorScheme.primary.withOpacity(_appBarOpacity),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        centerTitle: true,
        title: _buildAppBarTitle(innerBoxIsScrolled),
        background: _buildAppBarBackground(avatarColor),
      ),
    );
  }

  Hero _buildAppBarTitle(bool innerBoxIsScrolled) {
    return Hero(
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
    );
  }

  Stack _buildAppBarBackground(Color avatarColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundImage(avatarColor),
        _buildBackgroundGradient(),
        _buildClassNameOverlay(),
      ],
    );
  }

  Hero _buildBackgroundImage(Color avatarColor) {
    return Hero(
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: avatarColor.withOpacity(0.2),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: avatarColor.withOpacity(0.2),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  );
                },
              )
            : Image.asset(
                widget.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: avatarColor.withOpacity(0.2)),
              ),
      ),
    );
  }

  Container _buildBackgroundGradient() {
    return Container(
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
    );
  }

  Positioned _buildClassNameOverlay() {
    return Positioned(
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
        ],
      ),
    );
  }

  PageView _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        ClassContentScreen(classRoomId: widget.classId,),
        MaterialsPage(classId: widget.classId),
        StudentListPage(classId: widget.classId),
        TeacherInfoPage(
          classId: widget.classId,
        ),
      ],
    );
  }

  Container _buildBottomNavigationBar(ThemeData theme) {
    return Container(
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
          items: _buildBottomNavigationItems(theme),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavigationItems(ThemeData theme) {
    return [
      _buildBottomNavItem(0, Icons.task_outlined, "Tasks", theme),
      _buildBottomNavItem(2, Icons.people_outline, "Classmates", theme),
      _buildBottomNavItem(3, Icons.person_outline, "Teacher", theme),
    ];
  }

  BottomNavigationBarItem _buildBottomNavItem(
    int index,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              _currentIndex == index
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  Color _getAvatarColor(String className) {
    final colors = [
      Colors.pink[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    return colors[className.hashCode % colors.length];
  }
}
