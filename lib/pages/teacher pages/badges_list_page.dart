import 'package:flutter/material.dart';
import 'badge_detail_page.dart';

class BadgesListPage extends StatefulWidget {
  const BadgesListPage({super.key});

  @override
  _BadgesListPageState createState() => _BadgesListPageState();
}

class _BadgesListPageState extends State<BadgesListPage> {
  String? _selectedBadge;

  // List of badges with their names, colors, and icons
  final List<Map<String, dynamic>> _badges = [
    {"name": "Iron", "color": Colors.grey, "icon": Icons.shield},
    {"name": "Bronze", "color": Colors.brown, "icon": Icons.emoji_events},
    {"name": "Silver", "color": Colors.grey.shade300, "icon": Icons.star},
    {"name": "Gold", "color": Colors.amber, "icon": Icons.emoji_events_outlined},
    {"name": "Platinum", "color": Colors.blueGrey, "icon": Icons.workspace_premium},
    {"name": "Diamond", "color": Colors.blue, "icon": Icons.diamond},
    {"name": "Immortal", "color": Colors.red, "icon": Icons.whatshot},
    {"name": "Radiant", "color": Colors.yellow, "icon": Icons.wb_sunny},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Grid of badge cards
      child: GridView.builder(
        itemCount: _badges.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final badge = _badges[index];
          final isSelected = _selectedBadge == badge["name"];
          return GestureDetector(
            // On tap, navigate to badge detail page with fade transition
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: BadgeDetailPage(
                        badge: badge,
                        tag: badge["name"],
                      ),
                    );
                  },
                ),
              );
            },
            // Hero animation for badge card
            child: Hero(
              tag: badge["name"],
              child: Card(
                elevation: isSelected ? 8 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: isSelected
                      ? BorderSide(
                          color: badge["color"],
                          width: 3,
                        )
                      : BorderSide.none,
                ),
                color: isSelected
                    ? badge["color"].withOpacity(0.8)
                    : Theme.of(context).colorScheme.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge icon in a colored circle
                    CircleAvatar(
                      backgroundColor: badge["color"].withOpacity(0.7),
                      radius: 32,
                      child: Icon(
                        badge["icon"],
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Badge name
                    Text(
                      badge["name"],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // Check icon if selected
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Icon(Icons.check_circle, color: Colors.white, size: 24),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
