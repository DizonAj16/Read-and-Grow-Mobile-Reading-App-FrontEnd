import 'package:flutter/material.dart';

import 'level_1/activity_1.dart';
import 'level_1/activity_2.dart';
import 'level_2/activity3.dart';
import 'level_3/activity4.dart';
import 'level_4/activity5.dart';
import 'level_4/activity6.dart'; // Correct import for the new Activity6Page
import 'level_4/activity7.dart'; // Leave commented if Level 5 is not yet active
import 'level_4/activity8.dart'; // Uncomment when ready
import 'level_4/activity9.dart'; // Uncomment when ready

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
        title: Text(activityTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: activityPage,
    );
  }

  Widget _getActivityPage(int level, String activityTitle) {
    print('Loading: Level $level - $activityTitle');

    switch (level) {
      case 1:
        return _getLevel1Activity(activityTitle);
      case 2:
        return _getLevel2Activity(activityTitle);
      case 3:
        return _getLevel3Activity(activityTitle);
      case 4:
        return _getLevel4Activity(activityTitle);
      // case 5:
      //   return _getLevel5Activity(activityTitle);
      default:
        return Center(
          child: Text("No activity found for $activityTitle in Level $level."),
        );
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
        return const Activity4Page(); // Placeholder, update if different
      case "Task 3":
        return const Activity4Page(); // Placeholder, update if different
      default:
        return Center(
          child: Text("No activity found for $activityTitle in Level 3."),
        );
    }
  }

  Widget _getLevel4Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity5Page();
      case "Task 2":
        return const Activity6Page();
      case "Task 3": // Fixed typo
        return const Activity7Page();
      case "Task 4":
        return const Activity8Page();
      case "Task 5":
        return const Activity9Page();
      default:
        return Center(
          child: Text("No activity found for $activityTitle in Level 4."),
        );
    }
  }

  // Uncomment when Level 5 is active
  // Widget _getLevel5Activity(String activityTitle) {
  //   switch (activityTitle) {
  //     case "Task 1":
  //       return const Activity7Page();
  //     case "Task 2":
  //       return const Activity8Page();
  //     default:
  //       return Center(
  //         child: Text("No activity found for $activityTitle in Level 5."),
  //       );
  //   }
  // }
}
