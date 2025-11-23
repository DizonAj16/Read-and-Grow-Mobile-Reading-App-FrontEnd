import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  static Future<List<Map<String, dynamic>>> fetchTasksForClass(String classId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('assignments')
          .select('''
            id,
            assigned_date,
            due_date,
            instructions,
            tasks (id, title, description),
            quizzes (id, title)
          ''')
          .eq('class_room_id', classId)
          .order('assigned_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error fetching assignments: $e");
      return [];
    }
  }
}
