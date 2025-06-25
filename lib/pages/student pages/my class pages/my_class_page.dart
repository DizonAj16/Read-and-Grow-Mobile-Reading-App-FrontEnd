import 'package:flutter/material.dart';

import 'class_details_page.dart';

class MyClassPage extends StatefulWidget {
  const MyClassPage({super.key});

  @override
  _MyClassPageState createState() => _MyClassPageState();
}

class _MyClassPageState extends State<MyClassPage> {
  List<Map<String, dynamic>> classList = [];
  bool isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadClasses() async {
    await Future.delayed(Duration(seconds: 2));

    if (!mounted || _isDisposed) return;

    setState(() {
      classList = [
        {
          'className': 'English 1',
          'sectionName': 'Grade 1 - Section A',
          'teacherName': 'Teacher A',
          'backgroundImage': 'assets/background/classroombg.jpg',
          'studentLevel': 1, // Level 1
        },
        {
          'className': 'English 2',
          'sectionName': 'Grade 2 - Section B',
          'teacherName': 'Teacher B',
          'backgroundImage': 'assets/background/classroombg.jpg',
          'studentLevel': 2, // Level 2
        },
        {
          'className': 'English 3',
          'sectionName': 'Grade 3 - Section C',
          'teacherName': 'Teacher C',
          'backgroundImage': 'assets/background/classroombg.jpg',
          'studentLevel': 3, // Level 3
        },
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                "My Class",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child:
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          itemCount: classList.length,
                          itemBuilder: (context, index) {
                            final classItem = classList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: ClassCard(
                                className: classItem['className'],
                                sectionName: classItem['sectionName'],
                                teacherName: classItem['teacherName'],
                                backgroundImage: classItem['backgroundImage'],
                                studentLevel: classItem['studentLevel'],
                              ),
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
  final int studentLevel;

  const ClassCard({
    super.key,
    required this.className,
    required this.sectionName,
    required this.teacherName,
    required this.backgroundImage,
    required this.studentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
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
                        transitionDuration: Duration(milliseconds: 600),
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                ClassDetailsPage(
                                  className: className,
                                  studentLevel: studentLevel,
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
                            SizedBox(width: 8),
                            Text('View Class'),
                          ],
                        ),
                      ),
                    ],
                icon: Icon(Icons.more_vert, color: Colors.white),
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
                        ).textTheme.headlineMedium?.copyWith(
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
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_3_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            teacherName,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
