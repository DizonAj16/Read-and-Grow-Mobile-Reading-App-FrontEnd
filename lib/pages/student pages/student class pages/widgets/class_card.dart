import 'package:flutter/material.dart';
import '../class_details_page.dart';

class ClassCard extends StatelessWidget {
  final int classId;
  final String className;
  final String sectionName;
  final String teacherName;
  final String backgroundImage;
  final String realBackgroundImage;
  final String teacherEmail;
  final String teacherPosition;
  final String? teacherAvatar;

  const ClassCard({
    Key? key,
    required this.classId,
    required this.className,
    required this.sectionName,
    required this.teacherName,
    required this.backgroundImage,
    required this.realBackgroundImage,
    required this.teacherEmail,
    required this.teacherPosition,
    this.teacherAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToClassDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
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
              _buildClassInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToClassDetails(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder:
            (context, animation, secondaryAnimation) => ClassDetailsPage(
              className: className,
              backgroundImage: realBackgroundImage,
              teacherName: teacherName,
              teacherEmail: teacherEmail,
              teacherPosition: teacherPosition,
              teacherAvatar: teacherAvatar,
              classId: classId,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildClassInfo(BuildContext context) {
    return Padding(
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
            ),
          ),
          Text(
            sectionName,
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
          _buildTeacherInfo(context),
        ],
      ),
    );
  }

  Widget _buildTeacherInfo(BuildContext context) {
    return Row(
      children: [
        teacherAvatar != null && teacherAvatar!.isNotEmpty
            ? CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(teacherAvatar!),
              backgroundColor: Colors.grey[200],
            )
            : CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        const SizedBox(width: 8),
        Text(
          teacherName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
    );
  }
}
