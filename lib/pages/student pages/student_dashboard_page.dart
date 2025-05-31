import 'package:flutter/material.dart';
import '../../widgets/student_page_widgets/horizontal_card.dart';
import '../../widgets/student_page_widgets/activity_tile.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section with greeting and subtitle
          Text(
            "Welcome, Student!",
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
          SizedBox(height: 20),

          // Horizontal cards showing dashboard stats
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Completed tasks card
                StudentDashboardHorizontalCard(
                  title: "Completed Tasks",
                  value: "0",
                  gradientColors: [Colors.blue, Colors.lightBlueAccent],
                  icon: Icons.check_circle,
                ),
                SizedBox(width: 16),
                // Pending tasks card
                StudentDashboardHorizontalCard(
                  title: "Pending Tasks",
                  value: "11",
                  gradientColors: [Colors.orange, Colors.deepOrangeAccent],
                  icon: Icons.pending_actions,
                ),
                SizedBox(width: 16),
                // Badges earned card
                StudentDashboardHorizontalCard(
                  title: "Badges Earned",
                  value: "0",
                  gradientColors: [Colors.green, Colors.lightGreenAccent],
                  icon: Icons.emoji_events,
                ),
                SizedBox(width: 16),
                // Current badge card
                StudentDashboardHorizontalCard(
                  title: "Current Badge",
                  value: "N/A",
                  gradientColors: [Colors.blue, Colors.lightBlueAccent],
                  icon: Icons.emoji_events,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Recent activities section title
          Text(
            "Recent Activities",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          // List of recent activity tiles
          Column(
            children: [
              // Activity: Completed reading task
              StudentDashboardActivityTile(
                title: "Completed Reading Task",
                subtitle: "Story: The Tortoise and the Hare",
                icon: Icons.book,
              ),
              // Activity: Earned a badge
              StudentDashboardActivityTile(
                title: "Earned a Badge",
                subtitle: "Gold Badge for Reading Excellence",
                icon: Icons.emoji_events,
              ),
              // Activity: Submitted assignment
              StudentDashboardActivityTile(
                title: "Submitted Assignment",
                subtitle: "Math Worksheet 1",
                icon: Icons.assignment_turned_in,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
