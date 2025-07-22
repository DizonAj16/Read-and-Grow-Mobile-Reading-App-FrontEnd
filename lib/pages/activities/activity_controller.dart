import 'package:flutter/material.dart';

// Level 1
import 'level_1/activity_1.dart';
import 'level_1/activity_2.dart';
// Level 2
import 'level_2/activity3.dart';
// Level 3
import 'level_3/activity4.dart';
// Level 4
import 'level_4/activity5.dart';
import 'level_4/activity6.dart';
import 'level_4/activity7.dart';
import 'level_4/activity8.dart';
import 'level_4/activity9.dart';
// Level 5
import 'level_5/activity10.dart';
import 'level_5/activity11.dart';
import 'level_5/activity12.dart';
import 'level_5/activity13.dart';

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
        return _notFoundWidget(level, activityTitle);
    }
  }

  Widget _getLevel1Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity1Page();
      case "Task 2":
        return const Activity2Page();
      default:
        return _notFoundWidget(1, activityTitle);
    }
  }

  Widget _getLevel2Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity3Page();
      default:
        return _notFoundWidget(2, activityTitle);
    }
  }

  Widget _getLevel3Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
      case "Task 2":
      case "Task 3":
        return const Activity4Page(); // All map to Activity4Page
      default:
        return _notFoundWidget(3, activityTitle);
    }
  }

  Widget _getLevel4Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return const Activity5Page();
      case "Task 2":
        return const Activity6Page();
      case "Task 3":
        return const Activity7Page();
      case "Task 4":
        return const Activity8Page();
      case "Task 5":
        return const Activity9Page();
      default:
        return _notFoundWidget(4, activityTitle);
    }
  }

  Widget _getLevel5Activity(String activityTitle) {
    switch (activityTitle) {
      case "Task 1 - Day 1":
        return const Activity10Page();
      case "Task 2 - Day 2":
        return const Activity11Page();
      case "Task 3 - Day 3":
        return const Activity12Page();
      case "Task 4-5 - Day 4-5":
        return const Activity13Page();

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
}
