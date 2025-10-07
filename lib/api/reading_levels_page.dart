import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import 'reading_activity_page.dart';

class ReadingLevelsPage extends StatefulWidget {
  final Student student;

  const ReadingLevelsPage({Key? key, required this.student}) : super(key: key);

  @override
  State<ReadingLevelsPage> createState() => _ReadingLevelsPageState();
}

class _ReadingLevelsPageState extends State<ReadingLevelsPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _currentLevel;
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLevel();
  }

  Future<void> _fetchCurrentLevel() async {
    try {
      final response = await supabase
          .from('reading_levels')
          .select('*, reading_tasks(id, title, description, passage_text)')
          .eq('id', widget.student.currentReadingLevelId!)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _currentLevel = Map<String, dynamic>.from(response);
          _tasks = List<Map<String, dynamic>>.from(response['reading_tasks'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching current reading level: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentLevel == null) {
      return const Scaffold(
        body: Center(child: Text('No reading level assigned yet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading Level ${_currentLevel!['level_number']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentLevel!['level_name'] ?? 'Level',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _currentLevel!['description'] ?? 'No description provided.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('No tasks assigned.'))
                  : ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(task['title']),
                      subtitle: Text(
                        task['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingActivityPage(
                              taskId: task['id'].toString(),
                              passageText: task['passage_text'] ?? '',
                              student: widget.student,
                            ),
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
