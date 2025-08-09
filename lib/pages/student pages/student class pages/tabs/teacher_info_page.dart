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
    // Extract first letter for fallback avatar
    final avatarLetter =
        teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '?';
    final avatarColor = Colors.blue[200]!;

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // Teacher card with fun shape
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teacher avatar with decorative frame
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: avatarColor,
                        child: ClipOval(
                          child:
                              teacherAvatar != null && teacherAvatar!.isNotEmpty
                                  ? FadeInImage.assetNetwork(
                                    placeholder:
                                        'assets/placeholder/avatar_placeholder.jpg',
                                    image: teacherAvatar!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    imageErrorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return _buildAvatarFallback(
                                        avatarLetter,
                                        avatarColor,
                                      );
                                    },
                                  )
                                  : _buildAvatarFallback(
                                    avatarLetter,
                                    avatarColor,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rest of your existing code...
                    Column(
                      children: [
                        Text(
                          teacherName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info cards
                    _buildInfoCard(
                      icon: Icons.email_rounded,
                      color: Colors.pink[300]!,
                      title: "Email",
                      value: teacherEmail,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.school_rounded,
                      color: Colors.purple[300]!,
                      title: "Position",
                      value: teacherPosition,
                    ),
                  ],
                ),
              ),

              // Fun elements section
              const SizedBox(height: 20),
              Text(
                "⭐ Teacher Superpowers ⭐",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontFamily: 'ComicNeue',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSuperpowerCard("Knows Everything", Icons.lightbulb),
                    _buildSuperpowerCard("Homework Wizard", Icons.auto_awesome),
                    _buildSuperpowerCard("Story Master", Icons.menu_book),
                  ],
                ),
              ),

              // Back button with fun animation
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'ComicNeue',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontFamily: 'ComicNeue',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperpowerCard(String title, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'ComicNeue',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String letter, Color backgroundColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 50,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ComicNeue',
          ),
        ),
      ),
    );
  }
}
