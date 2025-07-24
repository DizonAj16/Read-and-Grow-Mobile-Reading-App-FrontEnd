import 'package:flutter/material.dart';

class TeacherInfoPage extends StatelessWidget {
  final String teacherName;
  final String teacherEmail;
  final String teacherPosition;
  final String? teacherAvatar;

  const TeacherInfoPage({
    super.key,
    required this.teacherName,
    required this.teacherEmail,
    required this.teacherPosition,
    this.teacherAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Profile Avatar
              CircleAvatar(
                radius: 80,
                backgroundImage: teacherAvatar != null
                    ? NetworkImage(teacherAvatar!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: teacherAvatar == null
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),

              // ✅ Teacher Name
              Text(
                teacherName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // ✅ Email Row with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    teacherEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ✅ Position Row with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    teacherPosition,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
