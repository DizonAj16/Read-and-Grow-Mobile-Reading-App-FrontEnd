import 'package:flutter/material.dart';

class BadgeDetailPage extends StatelessWidget {
  final Map<String, dynamic> badge;
  final String tag;

  const BadgeDetailPage({super.key, required this.badge, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar with themed back icon
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero animation for badge card
          Hero(
            tag: tag,
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              color: badge["color"].withOpacity(0.9),
              child: Container(
                width: 260,
                height: 350,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge icon in a circle
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      radius: 60,
                      child: Icon(
                        badge["icon"],
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Badge name
                    Text(
                      badge["name"],
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Badge description
                    Text(
                      "This is the ${badge["name"]} badge.",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
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
