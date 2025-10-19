import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/reading_tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ReadingLevelsPage extends StatefulWidget {
  const ReadingLevelsPage({super.key});

  @override
  State<ReadingLevelsPage> createState() => _ReadingLevelsPageState();
}

class _ReadingLevelsPageState extends State<ReadingLevelsPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? currentLevel;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadingLevel();
  }

  Future<void> _loadReadingLevel() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('students')
        .select('current_reading_level_id, reading_levels(*, reading_tasks(*))')
        .eq('user_id', user.id)
        .maybeSingle();

    if (res != null) {
      setState(() {
        currentLevel = res['reading_levels'];
        tasks = List<Map<String, dynamic>>.from(res['reading_levels']['reading_tasks'] ?? []);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("📚 ${currentLevel?['title'] ?? 'Reading Level'}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLevel?['description'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (_, i) {
                  final task = tasks[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      title: Text(task['title'] ?? 'Untitled Task'),
                      subtitle: Text(task['description'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingTaskPage(task: task),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
