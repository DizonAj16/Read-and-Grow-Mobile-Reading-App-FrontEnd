import 'package:flutter/material.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
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

          // Horizontal Cards Section
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHorizontalCard(
                  context,
                  title: "Completed Tasks",
                  value: "0",
                  gradientColors: [Colors.blue, Colors.lightBlueAccent],
                  icon: Icons.check_circle,
                ),
                SizedBox(width: 16),
                _buildHorizontalCard(
                  context,
                  title: "Pending Tasks",
                  value: "11",
                  gradientColors: [Colors.orange, Colors.deepOrangeAccent],
                  icon: Icons.pending_actions,
                ),
                SizedBox(width: 16),
                _buildHorizontalCard(
                  context,
                  title: "Badges Earned",
                  value: "0",
                  gradientColors: [Colors.green, Colors.lightGreenAccent],
                  icon: Icons.emoji_events,
                ),
                _buildHorizontalCard(
                  context,
                  title: "Current Badge",
                  value: "N/A",
                  gradientColors: [Colors.blue, Colors.lightBlueAccent],
                  icon: Icons.emoji_events,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Recent Activities Section
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
              _buildActivityTile(
                context,
                title: "Completed Reading Task",
                subtitle: "Story: The Tortoise and the Hare",
                icon: Icons.book,
              ),
              _buildActivityTile(
                context,
                title: "Earned a Badge",
                subtitle: "Gold Badge for Reading Excellence",
                icon: Icons.emoji_events,
              ),
              _buildActivityTile(
                context,
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

  // Function to build a horizontal card for statistics
  Widget _buildHorizontalCard(
    BuildContext context, {
    required String title,
    required String value,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white), // Icon at the top
            SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build a tile for recent activities
  Widget _buildActivityTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
