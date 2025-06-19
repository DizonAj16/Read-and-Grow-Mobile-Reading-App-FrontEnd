import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/teacher.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  Teacher? _teacher;

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    final teacher = await Teacher.fromPrefs();
    setState(() {
      _teacher = teacher;
    });
  }

  Widget _glassCard({
    required Widget child,
    double blur = 5,
    double opacity = 0.18,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(0),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = _teacher?.name ?? "Teacher";
    final teacherPosition = _teacher?.position ?? "";
    final teacherEmail = _teacher?.email ?? "";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Teacher Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.85),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Blended background image with color overlay for effect (copied from landing_page.dart)
          Image.asset(
            'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
          // Add a dark overlay for readability
          Container(
            color: Colors.black.withOpacity(0.35),
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      (MediaQuery.of(context).padding.top + kToolbarHeight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    // Glassmorphism profile card
                    _glassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'teacher-profile-image',
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white70,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/placeholder/teacher_placeholder.png',
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            teacherName,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white, // Ensure high contrast
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                teacherPosition.isNotEmpty
                                    ? teacherPosition
                                    : "Position not set",
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 3,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    // Glassmorphism info card
                    _glassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                            ),
                            title: Text(
                              teacherEmail.isNotEmpty
                                  ? teacherEmail
                                  : "Email not set",
                              style: TextStyle(
                                color: const Color.fromARGB(221, 255, 255, 255),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Divider(height: 0, indent: 16, endIndent: 16, color: Colors.white70,),
                          ListTile(
                            leading: Icon(
                              Icons.phone_outlined,
                              color: Colors.white70,
                            ),
                            title: Text(
                              "+1 234 567 890",
                              style: TextStyle(
                                color: const Color.fromARGB(221, 255, 255, 255),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Divider(height: 0, indent: 16, endIndent: 16, color: Colors.white70,),
                          ListTile(
                            leading: Icon(
                              Icons.school_outlined,
                              color: Colors.white70,
                            ),
                            title: Text(
                              "Elementary School",
                              style: TextStyle(
                                color: const Color.fromARGB(221, 255, 255, 255),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement edit profile
                      },
                      icon: Icon(Icons.edit),
                      label: Text("Edit Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
