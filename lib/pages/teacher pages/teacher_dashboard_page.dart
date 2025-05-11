import 'package:flutter/material.dart';
import 'dart:math';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateClassDialog(context);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: "Create Class",
        shape: CircleBorder(), // Ensures the button is circular
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, Teacher!",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 150, // Updated height for the horizontal scrollable cards
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildHorizontalCard(
                    context,
                    title: "Students",
                    value: "100",
                    gradientColors: [Colors.blue, Colors.lightBlueAccent],
                    icon: Icons.people, // Added icon
                  ),
                  SizedBox(width: 16),
                  _buildHorizontalCard(
                    context,
                    title: "Sections",
                    value: "3",
                    gradientColors: [Colors.green, Colors.lightGreenAccent],
                    icon: Icons.class_, // Added icon
                  ),
                  SizedBox(width: 16),
                  _buildHorizontalCard(
                    context,
                    title: "My Classes",
                    value: "25",
                    gradientColors: [Colors.purple, Colors.deepPurpleAccent],
                    icon: Icons.school, // Added icon
                  ),
                  SizedBox(width: 16),
                  _buildHorizontalCard(
                    context,
                    title: "Student Ranks",
                    value: "Top 10",
                    gradientColors: [Colors.orange, Colors.deepOrangeAccent],
                    icon: Icons.star, // Added icon
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Student List",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                StudentListTile(
                  name: "Alice Johnson",
                  section: "1A",
                  level: "1",
                  avatarLetter: "A",
                ),
                StudentListTile(
                  name: "Bob Smith",
                  section: "2B",
                  level: "2",
                  avatarLetter: "B",
                ),
                StudentListTile(
                  name: "Charlie Davis",
                  section: "3C",
                  level: "1",
                  avatarLetter: "C",
                ),
                StudentListTile(
                  name: "Diana Evans",
                  section: "1A",
                  level: "3",
                  avatarLetter: "D",
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle "See more" logic for Student List
                    },
                    child: Text(
                      "See more...",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "My Classes",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                ClassCard(
                  className: "English 1",
                  section: "Grade 1 - Section A", // Added section
                  studentCount: 30,
                ),
                ClassCard(
                  className: "English 2",
                  section: "Grade 2 - Section B", // Added section
                  studentCount: 25,
                ),
                ClassCard(
                  className: "English 3",
                  section: "Grade 3 - Section C", // Added section
                  studentCount: 20,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle "See more" logic for Class List
                    },
                    child: Text(
                      "See more...",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final TextEditingController classNameController = TextEditingController();
    final TextEditingController classSectionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            children: [
              Text(
                "Create Class",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Divider(
                thickness: 1,
                color: Colors.grey.shade300,
              ), // Divider below the title
            ],
          ),
          content: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.9, // 80% of screen width
            height:
                MediaQuery.of(context).size.height *
                0.15, // 40% of screen height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: classNameController,
                  decoration: InputDecoration(
                    labelText: "Class Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: classSectionController,
                  decoration: InputDecoration(
                    labelText: "Class Section",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle class creation logic here
                String className = classNameController.text.trim();
                String classSection = classSectionController.text.trim();
                if (className.isNotEmpty && classSection.isNotEmpty) {
                  // Perform class creation logic
                  Navigator.pop(context); // Close the dialog
                } else {
                  // Show error if fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context, {
    required String title,
    required String value,
    required List<Color> gradientColors,
    required IconData icon, // Added icon parameter
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white), // Added icon at the top
            SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentListTile extends StatelessWidget {
  final String name;
  final String section;
  final String level;
  final String avatarLetter;

  const StudentListTile({
    super.key,
    required this.name,
    required this.section,
    required this.level,
    required this.avatarLetter,
  });

  Color _getRandomColor() {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100, // Adjust the height of the card
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ), // Add padding inside the card
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRandomColor(),
                child: Text(
                  avatarLetter,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center content vertically
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Section: $section | Level: $level",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  // Handle action button logic
                },
                tooltip: "More Actions",
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
  final String section; // Added section property
  final int studentCount;

  const ClassCard({
    super.key,
    required this.className,
    required this.section, // Added section parameter

    required this.studentCount,
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
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/background/classroombg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6), // Darker at the top
                      Colors.transparent, // Transparent at the bottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$section", // Display the section
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
                          Icon(Icons.people, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "$studentCount Students",
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        "Teacher Name",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 16, // Adjusted font size for alignment
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    // Handle edit class logic
                  } else if (value == 'delete') {
                    // Handle delete class logic
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
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Edit Class'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            SizedBox(width: 8),
                            Text('Delete Class'),
                          ],
                        ),
                      ),
                    ],
                icon: Icon(Icons.more_vert, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
