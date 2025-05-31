import 'package:flutter/material.dart';

class TeacherDashboardClassCard extends StatelessWidget {
  final String className;
  final String section;
  final int studentCount;

  const TeacherDashboardClassCard({
    Key? key,
    required this.className,
    required this.section,
    required this.studentCount,
  }) : super(key: key);

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
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
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
                    section,
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
                              fontSize: 16,
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
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: Colors.blue, // Blue for view
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
                          color: Colors.grey, // Gray for edit
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
                          color: Colors.red, // Red for delete
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
