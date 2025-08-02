import 'package:flutter/material.dart';

class TeacherDashboardClassCard extends StatelessWidget {
  final String className;
  final String section;
  final int studentCount;
  final String teacherName;
  final int classId;

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeacherDashboardClassCard({
    Key? key,
    required this.classId,
    required this.className,
    required this.section,
    required this.studentCount,
    required this.teacherName,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
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
            // ✅ Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/background/classroombg.jpg',
                fit: BoxFit.cover,
                height: 150,
                width: double.infinity,
              ),
            ),

            // ✅ Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ✅ Popup menu
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    onView();
                  } else if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('View Class'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Edit Class'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Class'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ),

            // ✅ Class Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    className,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                  ),
                  // Section
                  Text(
                    section,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 1.5,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                  ),
                  const Spacer(),
                  // Footer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 👥 Student count
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "$studentCount Students",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 1.5,
                                      color: Colors.black26,
                                    ),
                                  ],
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
