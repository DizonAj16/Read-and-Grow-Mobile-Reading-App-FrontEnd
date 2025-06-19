import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  String _studentName = '';
  String _studentLrn = '';
  String _studentGrade = '';
  String _studentSection = '';

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('student_name') ?? '';
      _studentLrn = prefs.getString('student_lrn') ?? '';
      _studentGrade = prefs.getString('student_grade') ?? '';
      _studentSection = prefs.getString('student_section') ?? '';
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Student Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.85),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Blended background image with color overlay
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
                            tag: 'student-profile-image',
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white70,
                              child: Icon(
                                Icons.account_circle,
                                size: 120,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            _studentName.isNotEmpty ? _studentName : "Student",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
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
                          Text(
                            "Student",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
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
                    ),
                    SizedBox(height: 30),
                    // Glassmorphism info card
                    _glassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.badge, color: Colors.white70),
                            title: Text(
                              "LRN: ${_studentLrn.isNotEmpty ? _studentLrn : 'Not set'}",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Divider(height: 0, indent: 16, endIndent: 16, color: Colors.white70),
                          ListTile(
                            leading: Icon(Icons.grade, color: Colors.white70),
                            title: Text(
                              "Grade: ${_studentGrade.isNotEmpty ? _studentGrade : 'Not set'}",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Divider(height: 0, indent: 16, endIndent: 16, color: Colors.white70),
                          ListTile(
                            leading: Icon(Icons.class_, color: Colors.white70),
                            title: Text(
                              "Section: ${_studentSection.isNotEmpty ? _studentSection : 'Not set'}",
                              style: TextStyle(
                                color: Colors.white,
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