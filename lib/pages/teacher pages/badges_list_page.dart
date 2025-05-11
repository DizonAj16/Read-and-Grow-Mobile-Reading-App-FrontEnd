import 'package:flutter/material.dart';

class BadgesListPage extends StatefulWidget {
  const BadgesListPage({super.key});

  @override
  _BadgesListPageState createState() => _BadgesListPageState();
}

class _BadgesListPageState extends State<BadgesListPage> {
  String? _selectedBadge;

  // List of badges with their names and colors
  final List<Map<String, dynamic>> _badges = [
    {"name": "Iron", "color": Colors.grey},
    {"name": "Bronze", "color": Colors.brown},
    {"name": "Silver", "color": Colors.grey.shade300},
    {"name": "Gold", "color": Colors.amber},
    {"name": "Platinum", "color": Colors.blueGrey},
    {"name": "Diamond", "color": Colors.blue},
    {"name": "Immortal", "color": Colors.red},
    {"name": "Radiant", "color": Colors.yellow},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal scrollable list of badges
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _badges.map((badge) {
              final isSelected = _selectedBadge == badge["name"];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: ChoiceChip(
                  label: Text(
                    badge["name"],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    // Update the selected badge
                    setState(() {
                      _selectedBadge = selected ? badge["name"] : null;
                    });
                  },
                  backgroundColor: badge["color"].withOpacity(0.5),
                  selectedColor: badge["color"],
                ),
              );
            }).toList(),
          ),
        ),
        // Display a message when no badge is selected
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "Select a badge to highlight it.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
