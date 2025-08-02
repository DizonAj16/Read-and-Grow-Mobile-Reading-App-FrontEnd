import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final String? profileUrl;

  const StudentProfilePage({
    super.key,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    required this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // light pastel yellow
      appBar: AppBar(
        title: const Text(
          "Student Profile",
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'avatar_$name',
              child: CircleAvatar(
                radius: 70,
                backgroundColor: avatarColor,
                backgroundImage:
                    (profileUrl != null && profileUrl!.isNotEmpty)
                        ? NetworkImage(profileUrl!)
                        : null,
                child:
                    (profileUrl == null || profileUrl!.isEmpty)
                        ? Text(
                          avatarLetter,
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ComicNeue',
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ComicNeue',
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                      SizedBox(width: 5),
                      Text(
                        "Current Level: 1",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'ComicNeue',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, size: 22),
              label: const Text("Back"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'ComicNeue',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
