import 'package:flutter/material.dart';
import 'level_1/activity_1.dart';
import 'level_1/activity_2.dart';
//import 'level_1/activity_3.dart';
//import 'level_2/activity_4.dart';
//import 'level_2/activity_5.dart';
//import 'level_3/activity_6.dart';
//import 'level_3/activity_7.dart';
//import 'level_4/activity_9.dart';
//import 'level_4/activity_10.dart';
//import 'level_5/activity_11.dart';
//import 'level_5/activity_12.dart';
//import 'level_5/activity_13.dart';
//import 'level_5/activity_14.dart';
//import 'level_5/activity_15.dart';

class ActivityController extends StatelessWidget {
  final String activityTitle;

  const ActivityController({super.key, required this.activityTitle});

  @override
  Widget build(BuildContext context) {
    Widget activityPage = _getActivityPage(activityTitle);

    return Scaffold(
      appBar: AppBar(
        title: Text(activityTitle, style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: activityPage,
    );
  }

  Widget _getActivityPage(String activityTitle) {
    switch (activityTitle) {
      case "Task 1":
        return Activity1Page();
            case "Task 2":
        return Activity2Page();
    /*  case "Task 3":
        return Activity3Page();
      case "Task 4":
        return Activity4Page();
      case "Task 5":
        return Activity5Page();
      case "Task 6":
        return Activity6Page();
      case "Task 7":
        return Activity7Page();
      case "Task 9":
        return Activity9Page();
      case "Task 10":
        return Activity10Page();
      case "Task 11":
        return Activity11Page();
      case "Task 12":
        return Activity12Page();
      case "Task 13":
        return Activity13Page();
      case "Task 14":
        return Activity14Page();
      case "Task 15":
        return Activity15Page(); */
      default:
        return Center(child: Text("No activity found for $activityTitle."));
    }
  }
}
