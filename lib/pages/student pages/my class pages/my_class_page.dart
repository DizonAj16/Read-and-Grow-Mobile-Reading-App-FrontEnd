import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/models/classroom.dart';
import 'package:flutter/material.dart';

import 'class_details_page.dart';

class MyClassPage extends StatefulWidget {
  const MyClassPage({Key? key}) : super(key: key);

  @override
  State<MyClassPage> createState() => _MyClassPageState();
}

class _MyClassPageState extends State<MyClassPage> {
  late Future<List<Classroom>> _futureClasses;

  @override
  void initState() {
    super.initState();
    _futureClasses = _loadClasses();
  }

  Future<List<Classroom>> _loadClasses() async {
    try {
      List<Classroom> savedClasses =
          await ApiService.getStudentClassesFromPrefs();
      if (savedClasses.isNotEmpty) return savedClasses;

      List<Classroom> fetchedClasses = await ApiService.getStudentClasses();
      await ApiService.storeStudentClassesToPrefs(fetchedClasses);
      return fetchedClasses;
    } catch (e) {
      List<Classroom> savedClasses =
          await ApiService.getStudentClassesFromPrefs();
      return savedClasses.isNotEmpty ? savedClasses : [];
    }
  }

  Future<void> _refresh() async {
    try {
      setState(() {
        _futureClasses = ApiService.getStudentClasses().then((fetchedClasses) {
          ApiService.storeStudentClassesToPrefs(fetchedClasses);
          return fetchedClasses;
        });
      });
    } catch (e) {
      setState(() {
        _futureClasses = _loadClasses();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                "My Classes",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Classroom>>(
                  future: _futureClasses,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Failed to load classes. Please pull to refresh.",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "You are not assigned to any classes yet.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final classes = snapshot.data!;
                    return ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final classItem = classes[index];
                        return ClassCard(
                          className: classItem.className,
                          sectionName:
                              "${classItem.gradeLevel} - ${classItem.section}",
                          teacherName: classItem.teacherName ?? "N/A",
                          backgroundImage: 'assets/background/classroombg.jpg',
                          realBackgroundImage:
                              classItem.backgroundImage ??
                              'assets/background/classroombg.jpg',
                          teacherEmail: classItem.teacherEmail ?? "No email",
                          teacherPosition:
                              classItem.teacherPosition ?? "Teacher",
                          teacherAvatar: classItem.teacherAvatar,
                          gradeLevel:
                              int.tryParse(classItem.gradeLevel.toString()) ??
                              0,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassCard extends StatelessWidget {
  final String className;
  final String sectionName;
  final String teacherName;
  final String backgroundImage;
  final String realBackgroundImage;
  final String teacherEmail;
  final String teacherPosition;
  final String? teacherAvatar;
  final int gradeLevel;

  const ClassCard({
    Key? key,
    required this.className,
    required this.sectionName,
    required this.teacherName,
    required this.backgroundImage,
    required this.realBackgroundImage,
    required this.teacherEmail,
    required this.teacherPosition,
    this.teacherAvatar,
    required this.gradeLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 150,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Hero(
              tag: 'class-bg-$className',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 600),
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                ClassDetailsPage(
                                  className: className,
                                  backgroundImage: realBackgroundImage,
                                  teacherName: teacherName,
                                  teacherEmail: teacherEmail,
                                  teacherPosition: teacherPosition,
                                  teacherAvatar: teacherAvatar,
                                  gradeLevel: gradeLevel,
                                ),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('View Class'),
                          ],
                        ),
                      ),
                    ],
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'class-title-$className',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        className,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    sectionName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.person_3_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        teacherName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
