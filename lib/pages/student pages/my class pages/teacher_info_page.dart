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
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Avatar
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    teacherAvatar != null && teacherAvatar!.isNotEmpty
                        ? NetworkImage(teacherAvatar!)
                        : null,
                backgroundColor: Theme.of(context).colorScheme.primary, // pastel peach
                child:
                    (teacherAvatar == null || teacherAvatar!.isEmpty)
                        ? Text(
                          teacherName.isNotEmpty
                              ? teacherName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 50,
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),

              const SizedBox(height: 16),

              // ✅ Name
              Text(
                teacherName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'ComicSans',
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      teacherEmail,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontFamily: 'ComicSans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ✅ Position
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.black54,
                    size: 18,
                  ), // gold
                  const SizedBox(width: 6),
                  Text(
                    teacherPosition,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.black54,
                      fontFamily: 'ComicSans',
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
