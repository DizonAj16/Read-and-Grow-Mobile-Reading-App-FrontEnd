import 'package:deped_reading_app_laravel/pages/student%20pages/lesson_reader_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_quiz_pages.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassContentScreen extends StatefulWidget {
  final String classRoomId;

  const ClassContentScreen({super.key, required this.classRoomId});

  @override
  State<ClassContentScreen> createState() => _ClassContentScreenState();
}

class _ClassContentScreenState extends State<ClassContentScreen> {
  Future<List<Map<String, dynamic>>>? _lessonsFuture;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _fetchLessons();
  }

  Future<List<Map<String, dynamic>>> _fetchLessons() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('⚠️ No authenticated user found.');
      return [];
    }

    final response = await supabase
        .from('assignments')
        .select('''
          id,
          task_id,
          class_room_id,
          tasks (
            id,
            title,
            description,
            "order",
            created_at,
            quizzes (
              id,
              title
            )
          )
        ''')
        .eq('class_room_id', widget.classRoomId);

    if (response.isEmpty) return [];

    final assignments = List<Map<String, dynamic>>.from(response);

    assignments.sort((a, b) {
      final taskA = a['tasks'] ?? {};
      final taskB = b['tasks'] ?? {};
      final orderA = taskA['order'] as int? ?? 0;
      final orderB = taskB['order'] as int? ?? 0;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      final createdAString = taskA['created_at'];
      final createdBString = taskB['created_at'];
      final createdA = createdAString != null ? DateTime.tryParse(createdAString.toString()) : null;
      final createdB = createdBString != null ? DateTime.tryParse(createdBString.toString()) : null;
      if (createdA != null && createdB != null) {
        return createdA.compareTo(createdB);
      }
      final idA = a['id']?.toString() ?? '';
      final idB = b['id']?.toString() ?? '';
      return idA.compareTo(idB);
    });

    final assignmentIds = assignments
        .map((assignment) => assignment['id']?.toString())
        .whereType<String>()
        .toList();

    Map<String, Map<String, dynamic>> latestSubmissionMap = {};
    Map<String, int> attemptCountMap = {};

    if (assignmentIds.isNotEmpty) {
      final submissionsRes = await supabase
          .from('student_submissions')
          .select('assignment_id, score, max_score, attempt_number, submitted_at')
          .eq('student_id', user.id)
          .inFilter('assignment_id', assignmentIds)
          .order('submitted_at', ascending: false);

      for (final submission in submissionsRes) {
        final submissionData = Map<String, dynamic>.from(submission as Map);
        final assignmentId = submissionData['assignment_id']?.toString();
        if (assignmentId == null) continue;
        attemptCountMap[assignmentId] = (attemptCountMap[assignmentId] ?? 0) + 1;

        latestSubmissionMap.putIfAbsent(assignmentId, () => submissionData);
      }
    }

    final lessons = <Map<String, dynamic>>[];
    bool previousQuizCompletedAndPassed = true;
    const double passingThreshold = 0.7;
    const int maxAttempts = 3;

    for (final assignment in assignments) {
      final task = Map<String, dynamic>.from(assignment['tasks'] ?? {});
      final assignmentId = assignment['id']?.toString();
      final taskId = task['id']?.toString();

      if (assignmentId == null || taskId == null) continue;

      final submission = latestSubmissionMap[assignmentId];
      final attemptCount = attemptCountMap[assignmentId] ?? 0;
      final latestAttemptNumber = submission?['attempt_number'] as int? ?? attemptCount;
      final int latestScore = (submission?['score'] as int?) ?? 0;
      final int latestMaxScore = (submission?['max_score'] as int?) ?? 0;
      final bool passedLatest = submission != null &&
          latestMaxScore > 0 &&
          (latestScore / latestMaxScore) >= passingThreshold;
      final bool hasFinalAttempt = passedLatest || latestAttemptNumber >= maxAttempts;
      final bool finalPassed = passedLatest;

      final bool isLocked = !previousQuizCompletedAndPassed;
      final bool canRetake = !isLocked && !hasFinalAttempt;

      if (passedLatest) {
        previousQuizCompletedAndPassed = true;
      } else if (submission == null) {
        previousQuizCompletedAndPassed = false;
      } else if (hasFinalAttempt) {
        previousQuizCompletedAndPassed = false;
      } else {
        previousQuizCompletedAndPassed = false;
      }

      lessons.add({
        "assignment_id": assignmentId,
        "task_id": taskId,
        "class_room_id": assignment['class_room_id']?.toString(),
        "title": task['title'],
        "description": task['description'],
        "quizzes": List<Map<String, dynamic>>.from(
          (task['quizzes'] ?? []) as List,
        ),
        "submission": submission,
        "isTaken": hasFinalAttempt,
        "isLocked": isLocked,
        "attemptCount": attemptCount,
        "hasFinalAttempt": hasFinalAttempt,
        "finalPassed": finalPassed,
        "canRetake": canRetake,
        "latestScore": latestScore,
        "latestMaxScore": latestMaxScore,
      });
    }

    return lessons;
  }

  Future<void> _refreshLessons() async {
    setState(() {
      _refreshKey++;
      _lessonsFuture = _fetchLessons();
    });
    await _lessonsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lessons & Quizzes")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lessonsFuture,
        key: ValueKey(_refreshKey), // Force rebuild when refresh key changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final lessons = snapshot.data ?? [];

          if (lessons.isEmpty) {
            return const Center(child: Text("No lessons or quizzes assigned yet."));
          }

          return RefreshIndicator(
            onRefresh: _refreshLessons,
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final quizzes = (lesson['quizzes'] as List)
                    .cast<Map<String, dynamic>>();

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ExpansionTile(
                    leading: const Icon(Icons.menu_book, color: Colors.blue),
                    title: Text(
                      lesson['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      lesson['description'] ?? 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      if (quizzes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("No quizzes for this lesson."),
                        )
                      else
                        ...quizzes.map<Widget>((quiz) {
                          final quizId = quiz['id']?.toString();
                          final assignmentId = lesson['assignment_id']?.toString();
                          final taskId = lesson['task_id']?.toString();
                          final classRoomId = lesson['class_room_id']?.toString() ?? widget.classRoomId;
                          final submission = lesson['submission'] as Map<String, dynamic>?;
                          final bool hasFinalAttempt = lesson['hasFinalAttempt'] == true;
                          final bool finalPassed = lesson['finalPassed'] == true;
                          final bool canRetake = lesson['canRetake'] == true;
                          final bool isLocked = lesson['isLocked'] == true;
                          final int attemptCount = lesson['attemptCount'] as int? ?? 0;
                          final int latestScore = lesson['latestScore'] as int? ?? 0;
                          final int latestMaxScore = lesson['latestMaxScore'] as int? ?? 0;

                          if (quizId == null || quizId.isEmpty || assignmentId == null || assignmentId.isEmpty) {
                            return ListTile(
                              leading: const Icon(Icons.error, color: Colors.red),
                              title: const Text('Invalid Quiz'),
                              subtitle: const Text('Quiz data is missing', style: TextStyle(color: Colors.red)),
                              enabled: false,
                            );
                          }

                          final String statusText;
                          if (finalPassed) {
                            statusText = 'Final attempt passed – next quiz unlocked';
                          } else if (hasFinalAttempt && !finalPassed) {
                            statusText = 'Final attempt failed – quiz locked';
                          } else if (isLocked) {
                            statusText = 'Locked until previous quiz final attempt passes';
                          } else {
                            statusText = 'Attempt ${attemptCount + 1} of 3';
                          }

                          return ListTile(
                            leading: Icon(
                              finalPassed
                                  ? Icons.check_circle
                                  : hasFinalAttempt
                                      ? Icons.block
                                      : isLocked
                                          ? Icons.lock
                                          : Icons.quiz,
                              color: finalPassed
                                  ? Colors.green
                                  : hasFinalAttempt
                                      ? Colors.red
                                      : isLocked
                                          ? Colors.grey
                                          : Colors.orange,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(quiz['title'] ?? 'Quiz'),
                                ),
                                if (hasFinalAttempt && latestMaxScore > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$latestScore/$latestMaxScore',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              statusText,
                              style: TextStyle(
                                color: finalPassed
                                    ? Colors.green
                                    : hasFinalAttempt
                                        ? Colors.red
                                        : isLocked
                                            ? Colors.grey
                                            : Colors.orange,
                                fontStyle: (hasFinalAttempt || isLocked) ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                            trailing: finalPassed
                                ? const Icon(Icons.check, color: Colors.green)
                                : hasFinalAttempt
                                    ? const Icon(Icons.lock, color: Colors.redAccent)
                                    : isLocked
                                        ? const Icon(Icons.lock_outline, color: Colors.grey)
                                        : const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              if (isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Complete the previous quiz first to unlock this quiz.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              if (hasFinalAttempt) {
                                if (submission != null && mounted) {
                                  _showCompletedQuizDialog(submission);
                                }
                                return;
                              }

                              if (!canRetake) {
                                return;
                              }

                              _openLessonReader(
                                quizId: quizId,
                                assignmentId: assignmentId,
                                taskId: taskId,
                                classRoomId: classRoomId,
                                lessonTitle: lesson['title'] ?? 'Lesson',
                                lessonIndex: index,
                              );
                            },
                          );
                        }).toList(),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCompletedQuizDialog(Map<String, dynamic> submission) {
    if (!mounted) return;

    final score = submission['score'] ?? 0;
    final maxScore = submission['max_score'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have already completed this quiz.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score / $maxScore',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLessonReader({
    required String quizId,
    required String assignmentId,
    required String? taskId,
    required String classRoomId,
    required String lessonTitle,
    required int lessonIndex,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (quizId.isEmpty || assignmentId.isEmpty || taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson or quiz information is incomplete'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonReaderPage(
            taskId: taskId,
            assignmentId: assignmentId,
            classRoomId: classRoomId,
            quizId: quizId,
            studentId: user.id,
            lessonTitle: lessonTitle,
          ),
        ),
      );

      if (!mounted) return;

      final refreshFuture = _refreshLessons();
      final latestLessonsFuture = _lessonsFuture ?? Future.value(<Map<String, dynamic>>[]);
      final results = await Future.wait([
        refreshFuture,
        latestLessonsFuture,
      ]);

      final latestLessons = results[1] as List<Map<String, dynamic>>;

      if (result == StudentQuizOutcome.continueNext) {
        int nextIndex = lessonIndex + 1;
        bool skippedLessons = false;

        while (nextIndex < latestLessons.length) {
          final nextLesson = latestLessons[nextIndex];
          final nextQuizzes = (nextLesson['quizzes'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          if (nextQuizzes.isEmpty) {
            skippedLessons = true;
            nextIndex++;
            continue;
          }

          final nextQuiz = nextQuizzes.first;
          final nextQuizId = nextQuiz['id']?.toString();
          final nextAssignmentId = nextLesson['assignment_id']?.toString();
          final nextTaskId = nextLesson['task_id']?.toString();
          final nextClassRoomId =
              nextLesson['class_room_id']?.toString() ?? widget.classRoomId;

          if (nextQuizId != null &&
              nextAssignmentId != null &&
              nextTaskId != null) {
            if (skippedLessons && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Skipped lessons without quizzes and moved to the next available quiz.'),
                  backgroundColor: Colors.blueAccent,
                ),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openLessonReader(
                quizId: nextQuizId,
                assignmentId: nextAssignmentId,
                taskId: nextTaskId,
                classRoomId: nextClassRoomId,
                lessonTitle: nextLesson['title'] ?? 'Lesson',
                lessonIndex: nextIndex,
              );
            });
            return;
          }

          skippedLessons = true;
          nextIndex++;
        }

        if (skippedLessons && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All remaining lessons have no quizzes. Great job finishing the class!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You completed all lessons in this class!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      } else if (result == StudentQuizOutcome.exitSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz completed successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == StudentQuizOutcome.exitFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz attempt recorded. You can try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      debugPrint('Error navigating to lesson reader: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening lesson: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
