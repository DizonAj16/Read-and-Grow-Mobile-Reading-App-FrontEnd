import 'package:flutter/material.dart';

import 'level_1/activity_1.dart';
import 'level_1/activity_2.dart';
import 'level_2/activity3.dart';
import 'level_3/activity4.dart';

class ActivityController extends StatelessWidget {
  final String activityTitle;
  final int studentLevel;

  const ActivityController({
    super.key,
    required this.activityTitle,
    required this.studentLevel,
  });

  @override
  Widget build(BuildContext context) {
    Widget activityPage = _getActivityPage(studentLevel, activityTitle);

    return Scaffold(
      appBar: AppBar(
        title: Text(activityTitle, style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: activityPage,
    );
  }

  Widget _getActivityPage(int level, String activityTitle) {
    print('Loading: Level $level - $activityTitle'); // Debug

    switch (level) {
      case 1:
        return _getLevel1Activity(activityTitle);
      case 2:
        return _getLevel2Activity(activityTitle);
      case 3:
        return _getLevel3Activity(activityTitle);
      default:
        return Center(child: Text("No activity found for $activityTitle."));
    }
  }

  Widget _getLevel1Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity1Page();
      case "Task 2":
        return const Activity2Page();
      default:
        return Center(
          child: Text("No activity found for $activityTitle in Level 1."),
        );
    }
  }

  Widget _getLevel2Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity3Page();
      default:
        return Center(
          child: Text("No activity found for $activityTitle in Level 2."),
        );
    }
  }

  Widget _getLevel3Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity4Page();
      case "Task 2":
        return const Activity4Page(); // You can point this to another page if needed
      default:
        return Center(
          child: Text("No activity found for $activityTitle in Level 3."),
        );
    }
  }
}
