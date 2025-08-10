import 'package:deped_reading_app_laravel/constants.dart';
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
    final avatarLetter =
        teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '?';
    final colors = [
      Colors.pink[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    final avatarColor = colors[teacherName.hashCode % colors.length];

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          // Fixed header (not affected by scroll)
          _buildCurvedHeader(context),

          // Scrollable content below
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Main Profile Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: _buildProfileCard(avatarColor, avatarLetter),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Superpowers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "🌟 Teacher Superpowers 🌟",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSuperpowerCard(
                          "Knowledge Ninja",
                          Icons.lightbulb,
                          Colors.pink[300]!,
                        ),
                        _buildSuperpowerCard(
                          "Homework Hero",
                          Icons.auto_awesome,
                          Colors.blue[300]!,
                        ),
                        _buildSuperpowerCard(
                          "Story Sage",
                          Icons.menu_book,
                          Colors.purple[300]!,
                        ),
                        _buildSuperpowerCard(
                          "Patience Pro",
                          Icons.self_improvement,
                          Colors.green[300]!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimaryColor, // main primary color
              Color(0xFFB71C1C), // darker shade for depth
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            "Teacher Profile",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'ComicNeue',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Color avatarColor, String avatarLetter) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: avatarColor.withOpacity(0.25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.85),
              Colors.white.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: avatarColor.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: avatarColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    teacherAvatar != null && teacherAvatar!.isNotEmpty
                        ? FadeInImage.assetNetwork(
                          placeholder:
                              'assets/placeholder/avatar_placeholder.jpg',
                          image: teacherAvatar!,
                          fit: BoxFit.cover,
                          imageErrorBuilder:
                              (_, __, ___) => _buildAvatarFallback(
                                avatarLetter,
                                avatarColor,
                              ),
                        )
                        : _buildAvatarFallback(avatarLetter, avatarColor),
              ),
            ),
            const SizedBox(height: 20),

            // Name
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
                color: avatarColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

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
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
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
      ),
    );
  }

  Widget _buildSuperpowerCard(String title, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'ComicNeue',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String letter, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }
}

// Custom wave header
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 20,
    );
    path.quadraticBezierTo(
      3 / 4 * size.width,
      size.height - 40,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
