import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  static Future<List<String>> fetchTasksForStudent(
      BuildContext context,
      String classId,
      ) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch tasks for the given classId
      final response = await supabase
          .from('tasks')
          .select('title')
          .eq('class_id', classId);

      if (response.isEmpty) {
        return [];
      }

      // Map results to a list of strings
      return response
          .map<String>((task) => task['title'].toString())
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching tasks: $e");
      return [];
    }
  }
}
