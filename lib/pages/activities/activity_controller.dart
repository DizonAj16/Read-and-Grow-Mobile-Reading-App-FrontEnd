import 'package:flutter/material.dart';

// Level 1
import 'level_1/activity_1.dart';
import 'level_1/activity_2.dart';
// Level 2
import 'level_2/activity_3.dart';
// Level 3
import 'level_3/activity_4.dart';
// Level 4
import 'level_4/activity_5.dart';
import 'level_4/activity_6.dart';
import 'level_4/activity_7.dart';
import 'level_4/activity_8.dart';
import 'level_4/activity_9.dart';
// Level 5
import 'level_5/activity_10.dart';
import 'level_5/activity_11.dart';
import 'level_5/activity_12.dart';
import 'level_5/activity_13.dart';

class ActivityController extends StatelessWidget {
  final String activityTitle;
  final int studentLevel;
  final VoidCallback? onCompleted;

  const ActivityController({
    super.key,
    required this.activityTitle,
    required this.studentLevel,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Widget activityPage = _getActivityPage(studentLevel, activityTitle);

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
    debugPrint('Loading: Level $level - $activityTitle');

    switch (level) {
      case 1:
        return _getLevel1Activity(activityTitle);
      case 2:
        return _getLevel2Activity(activityTitle);
      case 3:
        return _getLevel3Activity(activityTitle);
      case 4:
        return _getLevel4Activity(activityTitle);
      case 5:
        return _getLevel5Activity(activityTitle);
      default:
        return _restrictedWidget(level);
    }
  }

  // Level 1 Activities
  Widget _getLevel1Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return Activity1Page(onCompleted: onCompleted);
      case "Task 2":
        return Activity2Page(onCompleted: onCompleted);
      default:
        return _notFoundWidget(1, activityTitle);
    }
  }

  // Level 2 Activities
  Widget _getLevel2Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return Activity3Page(onCompleted: onCompleted);
      default:
        return _notFoundWidget(2, activityTitle);
    }
  }

  // Level 3 Activities
  Widget _getLevel3Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
      case "Task 2":
      case "Task 3":
        return Activity4Page(onCompleted: onCompleted);
      default:
        return _notFoundWidget(3, activityTitle);
    }
  }

  // Level 4 Activities
  Widget _getLevel4Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return Activity5Page(onCompleted: onCompleted);
      case "Task 2":
        return Activity6Page(onCompleted: onCompleted);
      case "Task 3":
        return Activity7Page(onCompleted: onCompleted);
      case "Task 4":
        return Activity8Page(onCompleted: onCompleted);
      case "Task 5":
        return Activity9Page(onCompleted: onCompleted);
      default:
        return _notFoundWidget(4, activityTitle);
    }
  }

  // Level 5 Activities
  Widget _getLevel5Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1 - Day 1":
        return Activity10Page(onCompleted: onCompleted);
      case "Task 2 - Day 2":
        return Activity11Page(onCompleted: onCompleted);
      case "Task 3 - Day 3":
        return Activity12Page(onCompleted: onCompleted);
      case "Task 4-5 - Day 4-5": // ✅ fixed this to match task title
        return Activity13Page(onCompleted: onCompleted);
      default:
        return _notFoundWidget(5, activityTitle);
    }
  }

  Widget _notFoundWidget(int level, String title) {
    return Center(
      child: Text(
        "No activity found for '$title' in Level $level.",
        style: const TextStyle(fontSize: 18, color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _restrictedWidget(int level) {
    return Center(
      child: Text(
        "This activity is not available for your grade level (Level $level).",
        style: const TextStyle(fontSize: 18, color: Colors.orange),
        textAlign: TextAlign.center,
      ),
    );
  }
}
