import 'package:flutter/material.dart';
import 'level_1/activity_1.dart';
import 'level_1/activity_2.dart';
import 'level_1/activity_3.dart';
import 'level_1/activity_4.dart';
import 'level_1/activity_5.dart';
import 'level_1/activity_6.dart';
import 'level_1/activity_7.dart';
import 'level_1/activity_8.dart';
import 'level_1/activity_9.dart';
import 'level_1/activity_10.dart';
import 'level_1/activity_11.dart';
import 'level_1/activity_12.dart';
import 'level_1/activity_13.dart';

class ActivityController extends StatelessWidget {
  final String activityTitle;
  final VoidCallback? onCompleted; // ✅ New: Callback to update task status

  const ActivityController({
    super.key,
    required this.activityTitle,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Widget activityPage = _getActivityPage(activityTitle);

    return Scaffold(
      appBar: AppBar(
        title: Text(activityTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: activityPage,
    );
  }

  /// ✅ Passes `onCompleted` to each Activity Page
  Widget _getActivityPage(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return Activity1Page(onCompleted: onCompleted);
      case "Task 2":
        return Activity2Page(onCompleted: onCompleted);
      case "Task 3":
        return Activity3Page(onCompleted: onCompleted);
      case "Task 4":
        return Activity4Page(onCompleted: onCompleted);
      case "Task 5":
        return Activity5Page(onCompleted: onCompleted);
      case "Task 6":
        return Activity6Page(onCompleted: onCompleted);
      case "Task 7":
        return Activity7Page(onCompleted: onCompleted);
      case "Task 8":
        return Activity8Page(onCompleted: onCompleted);
      case "Task 9":
        return Activity9Page(onCompleted: onCompleted);
      case "Task 10":
        return Activity10Page(onCompleted: onCompleted);
      case "Task 11":
        return Activity11Page(onCompleted: onCompleted);
      case "Task 12":
        return Activity12Page(onCompleted: onCompleted);
      case "Task 13":
        return Activity13Page(onCompleted: onCompleted);
      default:
        return Center(child: Text("No activity found for $activityTitle."));
    }
  }
}
