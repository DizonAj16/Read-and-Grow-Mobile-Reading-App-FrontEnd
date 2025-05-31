import 'package:flutter/material.dart';
import 'class_details_page.dart';

class MyClassPage extends StatelessWidget {
  const MyClassPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            // Title for the page
            Text(
              "My Class",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Display a class card
            ClassCard(
              className: "English 1",
              sectionName: "Grade 1 - Section A",
              teacherName: "Teacher Name",
              backgroundImage: 'assets/background/classroombg.jpg',
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to display a class card
class ClassCard extends StatelessWidget {
  final String className;
  final String sectionName;
  final String teacherName;
  final String backgroundImage;

  const ClassCard({
    super.key,
    required this.className,
    required this.sectionName,
    required this.teacherName,
    required this.backgroundImage,
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
            // Background image for the card with Hero
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
            // Gradient overlay for the card
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
            // Popup menu for class actions
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
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ClassDetailsPage(className: className),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
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
            // Class details
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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

