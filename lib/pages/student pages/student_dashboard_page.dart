import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/student_page_widgets/horizontal_card.dart';
import '../../widgets/student_page_widgets/activity_tile.dart';

/// Student Dashboard Page - Main entry point
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

  /// Loads the username from shared preferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          SizedBox(height: 20),
          _buildStatisticsCards(),
          SizedBox(height: 20),
          _buildRecentActivitiesSection(context),
        ],
      ),
    );
  }

  /// Welcome section with greeting and subtitle
  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome, ${username ?? ''}!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Here's an overview of your progress.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Horizontal cards showing dashboard stats
  Widget _buildStatisticsCards() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StudentDashboardHorizontalCard(
            title: "Completed Tasks",
            value: "0",
            gradientColors: [Colors.blue, Colors.lightBlueAccent],
            icon: Icons.check_circle,
          ),
          SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Pending Tasks",
            value: "11",
            gradientColors: [Colors.orange, Colors.deepOrangeAccent],
            icon: Icons.pending_actions,
          ),
          SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Badges Earned",
            value: "0",
            gradientColors: [Colors.green, Colors.lightGreenAccent],
            icon: Icons.emoji_events,
          ),
          SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Current Badge",
            value: "N/A",
            gradientColors: [Colors.blue, Colors.lightBlueAccent],
            icon: Icons.emoji_events,
          ),
        ],
      ),
    );
  }

  /// Recent activities section with activity tiles
  Widget _buildRecentActivitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activities",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Column(
          children: [
            StudentDashboardActivityTile(
              title: "Completed Reading Task",
              subtitle: "Story: The Tortoise and the Hare",
              icon: Icons.book,
            ),
            StudentDashboardActivityTile(
              title: "Earned a Badge",
              subtitle: "Gold Badge for Reading Excellence",
              icon: Icons.emoji_events,
            ),
            StudentDashboardActivityTile(
              title: "Submitted Assignment",
              subtitle: "Math Worksheet 1",
              icon: Icons.assignment_turned_in,
            ),
          ],
        ),
      ],
    );
  }
}
