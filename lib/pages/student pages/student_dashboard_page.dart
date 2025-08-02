import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/student_page_widgets/horizontal_card.dart';
import '../../widgets/student_page_widgets/activity_tile.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEEE), // Soft background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // <- vertical centering
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _buildWelcomeSection(context)),
                      const SizedBox(height: 20),
                      _buildStatisticsCards(),
                      const SizedBox(height: 30),
                      _buildRecentActivitiesSection(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

Widget _buildWelcomeSection(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.purple.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.purple.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: Lottie.asset(
            'assets/animation/waving_hello.json',
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Hi ${username ?? ''}! 👋",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Ready to learn and have fun today?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.purple.shade400,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildStatisticsCards() {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StudentDashboardHorizontalCard(
            title: "✅ Completed",
            value: "0",
            gradientColors: [Colors.lightGreen, Colors.green],
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "🕒 Pending",
            value: "11",
            gradientColors: [Colors.orangeAccent, Colors.deepOrange],
            icon: Icons.pending_actions,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "🏅 Badges",
            value: "0",
            gradientColors: [Colors.pinkAccent, Colors.redAccent],
            icon: Icons.emoji_events_outlined,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "🎖 Badge",
            value: "N/A",
            gradientColors: [Colors.blueAccent, Colors.lightBlue],
            icon: Icons.star_border,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    // Simulated empty list (replace with your actual logic later)
    final List activities = [];

    if (activities.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  "No recent activities yet!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your activities will appear here once you start learning.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Otherwise, show actual activities
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📚 Recent Activities",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children:
              activities.map((activity) {
                // replace with actual data rendering
                return StudentDashboardActivityTile(
                  title: activity.title,
                  subtitle: activity.subtitle,
                  icon: activity.icon,
                );
              }).toList(),
        ),
      ],
    );
  }
}
