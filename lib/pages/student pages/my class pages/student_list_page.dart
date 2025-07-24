import 'dart:math';

import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/models/student.dart'; // Adjust if needed
import 'package:flutter/material.dart';

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<Student> _students = [];
  Map<int, Color> _avatarColors = {}; // student.id -> avatar color
  int _currentPage = 0;
  final int _studentsPerPage = 6;
  final PageController _pageController = PageController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final fetchedStudents = await ApiService.fetchClassmates();
      setState(() {
        _students = fetchedStudents;
        _avatarColors = {
          for (var student in fetchedStudents)
            student.id:
                Colors.primaries[Random().nextInt(Colors.primaries.length)],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch students.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final totalStudents = _students.length;
    final totalPages = (totalStudents / _studentsPerPage).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Total Students: $totalStudents",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: totalPages,
            itemBuilder: (context, pageIndex) {
              final studentsToShow =
                  _students
                      .skip(pageIndex * _studentsPerPage)
                      .take(_studentsPerPage)
                      .toList();

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: studentsToShow.length,
                itemBuilder: (context, index) {
                  final student = studentsToShow[index];
                  final color = _avatarColors[student.id] ?? Colors.grey;
                  return _buildStudentCard(
                    context,
                    name: student.studentName,
                    avatarLetter: student.avatarLetter,

                    avatarColor: color,
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 12.0 : 8.0,
                  height: _currentPage == index ? 12.0 : 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(
    BuildContext context, {
    required String name,
    required String avatarLetter,
    required Color avatarColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: avatarColor,
                    child: Text(
                      avatarLetter,
                      style: TextStyle(color: Colors.white, fontSize: 25),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view_profile') {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          content: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: avatarColor,
                                  child: Text(
                                    avatarLetter,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Current Level: 1", // Placeholder
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Close"),
                            ),
                          ],
                        ),
                  );
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'view_profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                  ],
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
