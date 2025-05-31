import 'package:flutter/material.dart';
import 'dart:math';

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  // Generate a list of random students for demo purposes
  final List<Map<String, dynamic>> _students = List.generate(20, (index) {
    // Generate random student data
    final random = Random();
    final firstNames = [
      "Alice",
      "Bob",
      "Charlie",
      "Diana",
      "Eve",
      "Frank",
      "Grace",
      "Hank",
      "Ivy",
      "Jack",
    ];
    final lastNames = [
      "Johnson",
      "Smith",
      "Davis",
      "Evans",
      "Brown",
      "Wilson",
      "Taylor",
      "Anderson",
      "Thomas",
      "Moore",
    ];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final firstName = firstNames[random.nextInt(firstNames.length)];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final avatarColor = colors[random.nextInt(colors.length)];
    return {
      "name": "$firstName $lastName",
      "avatarLetter": firstName[0],
      "avatarColor": avatarColor,
    };
  });

  int _currentPage = 0;
  final int _studentsPerPage = 6; // Number of students per page
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final int totalStudents = _students.length;
    final int totalPages = (totalStudents / _studentsPerPage).ceil();

    return Column(
      children: [
        // Display total number of students at the top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Total Students: $totalStudents",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // PageView for paginated student grid
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: totalPages,
            itemBuilder: (context, pageIndex) {
              final List<Map<String, dynamic>> studentsToShow =
                  _students
                      .skip(pageIndex * _studentsPerPage)
                      .take(_studentsPerPage)
                      .toList();

              // Grid of student cards for the current page
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
                  return _buildStudentCard(
                    context,
                    name: student["name"]!,
                    avatarLetter: student["avatarLetter"]!,
                    avatarColor: student["avatarColor"]!,
                  );
                },
              );
            },
          ),
        ),
        // Pagination indicators (dots) for page navigation
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

  // Builds a card widget for each student with avatar, name, and actions
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
          // Student avatar and name
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
          // Popup menu for student actions (e.g., view profile)
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
                                  name, // Student name in dialog
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Current Level: 1", // Placeholder for student level
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
                  (BuildContext context) => [
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
