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

    // Fetch assignments with tasks and quizzes
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

    // Sort assignments by order and creation date
    assignments.sort((a, b) {
      final taskA = a['tasks'] ?? {};
      final taskB = b['tasks'] ?? {};
      final orderA = taskA['order'] as int? ?? 0;
      final orderB = taskB['order'] as int? ?? 0;
      if (orderA != orderB) return orderA.compareTo(orderB);

      final createdA = DateTime.tryParse(taskA['created_at']?.toString() ?? '');
      final createdB = DateTime.tryParse(taskB['created_at']?.toString() ?? '');
      if (createdA != null && createdB != null)
        return createdA.compareTo(createdB);

      return (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? '');
    });

    // Prepare assignment IDs
    final assignmentIds =
        assignments
            .map((a) => a['id']?.toString())
            .whereType<String>()
            .toList();

    // Fetch student submissions
    Map<String, Map<String, dynamic>> latestSubmissionMap = {};
    Map<String, int> attemptCountMap = {};

    if (assignmentIds.isNotEmpty) {
      final submissionsRes = await supabase
          .from('student_submissions')
          .select(
            'assignment_id, score, max_score, attempt_number, submitted_at',
          )
          .eq('student_id', user.id)
          .inFilter('assignment_id', assignmentIds)
          .order('submitted_at', ascending: false);

      for (final submission in submissionsRes) {
        final sub = Map<String, dynamic>.from(submission as Map);
        final assignmentId = sub['assignment_id']?.toString();
        if (assignmentId == null) continue;

        attemptCountMap[assignmentId] =
            (attemptCountMap[assignmentId] ?? 0) + 1;
        latestSubmissionMap.putIfAbsent(assignmentId, () => sub);
      }
    }

    // Build lessons list
    final lessons = <Map<String, dynamic>>[];
    bool previousQuizCompletedAndPassed =
        true; // Start with true for first lesson
    const double passingThreshold = 0.5;
    const int maxAttempts = 3;
    int lessonCounter = 0;

    for (final assignment in assignments) {
      final task = Map<String, dynamic>.from(assignment['tasks'] ?? {});
      final assignmentId = assignment['id']?.toString();
      final taskId = task['id']?.toString();
      if (assignmentId == null || taskId == null) continue;

      final submission = latestSubmissionMap[assignmentId];
      final attemptCount = attemptCountMap[assignmentId] ?? 0;
      final latestAttemptNumber =
          submission?['attempt_number'] as int? ?? attemptCount;

      // Ensure numeric values for score
      final int latestScore =
          int.tryParse(submission?['score']?.toString() ?? '0') ?? 0;
      final int latestMaxScore =
          int.tryParse(submission?['max_score']?.toString() ?? '0') ?? 0;

      // Determine pass/fail
      final bool passedLatest =
          submission != null &&
          latestMaxScore > 0 &&
          (latestScore / latestMaxScore) >= passingThreshold;

      final bool hasFinalAttempt =
          passedLatest || latestAttemptNumber >= maxAttempts;
      final bool finalPassed = passedLatest;

      // SPECIAL CASE: First lesson should never be locked
      // Check if this is the first lesson in the list
      final bool isFirstLesson = lessons.isEmpty;
      final bool isLocked =
          isFirstLesson ? false : !previousQuizCompletedAndPassed;
      final bool canRetake = !isLocked && !hasFinalAttempt;

      // Update previous for next lesson - ONLY IF FINAL ATTEMPT PASSED
      if (hasFinalAttempt) {
        previousQuizCompletedAndPassed = finalPassed;
      } else {
        // If no final attempt yet, keep previous state
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
        "isFirstLesson": isFirstLesson, // Add this flag for easier reference
        "lessonIndex": lessonCounter, // Add index for navigation
      });

      lessonCounter++;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary.withOpacity(
        0.05,
      ), // Light background using primary color
      body: Column(
        children: [
          // Wave header
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    Color.alphaBlend(
                      colorScheme.primary.withOpacity(0.7),
                      Colors.red.shade900,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                "Lessons & Quizzes",
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Expanded scrollable content
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _lessonsFuture,
              key: ValueKey(_refreshKey),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }

                final lessons = snapshot.data ?? [];
                if (lessons.isEmpty) {
                  return Center(
                    child: Text(
                      "No lessons or quizzes assigned yet.",
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: _refreshLessons,
                  child: ListView.builder(
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final quizzes =
                          (lesson['quizzes'] as List)
                              .cast<Map<String, dynamic>>();

                      return Card(
                        margin: const EdgeInsets.all(12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.menu_book,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            lesson['title'] ?? 'Untitled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            lesson['description'] ?? 'No description available',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          children:
                              quizzes.isEmpty
                                  ? [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        "No quizzes for this lesson.",
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ]
                                  : quizzes.map<Widget>((quiz) {
                                    final quizId = quiz['id']?.toString();
                                    final assignmentId =
                                        lesson['assignment_id']?.toString();
                                    final taskId =
                                        lesson['task_id']?.toString();
                                    final classRoomId =
                                        lesson['class_room_id']?.toString() ??
                                        widget.classRoomId;
                                    final submission =
                                        lesson['submission']
                                            as Map<String, dynamic>?;
                                    final bool hasFinalAttempt =
                                        lesson['hasFinalAttempt'] == true;
                                    final bool finalPassed =
                                        lesson['finalPassed'] == true;
                                    final bool canRetake =
                                        lesson['canRetake'] == true;
                                    final bool isLocked =
                                        lesson['isLocked'] == true;
                                    final int attemptCount =
                                        lesson['attemptCount'] as int? ?? 0;
                                    final int latestScore =
                                        lesson['latestScore'] as int? ?? 0;
                                    final int latestMaxScore =
                                        lesson['latestMaxScore'] as int? ?? 0;

                                    if (quizId == null ||
                                        quizId.isEmpty ||
                                        assignmentId == null ||
                                        assignmentId.isEmpty) {
                                      return ListTile(
                                        leading: Icon(
                                          Icons.error,
                                          color: colorScheme.error,
                                        ),
                                        title: Text('Invalid Quiz'),
                                        subtitle: Text(
                                          'Quiz data is missing',
                                          style: TextStyle(
                                            color: colorScheme.error,
                                          ),
                                        ),
                                        enabled: false,
                                      );
                                    }

                                    final String statusText;
                                    Color statusColor;

                                    if (finalPassed) {
                                      statusText =
                                          'Final attempt passed – next quiz unlocked';
                                      statusColor = Colors.green;
                                    } else if (hasFinalAttempt &&
                                        !finalPassed) {
                                      statusText =
                                          'Final attempt failed – quiz locked';
                                      statusColor = Colors.red;
                                    } else if (isLocked) {
                                      statusText =
                                          'Locked until previous quiz final attempt passes';
                                      statusColor = Colors.grey;
                                    } else {
                                      statusText =
                                          'Attempt ${attemptCount + 1} of 3';
                                      statusColor = colorScheme.primary;
                                    }

                                    final bool canViewMaterialOnly =
                                        (taskId != null && taskId.isNotEmpty) &&
                                        assignmentId.isNotEmpty &&
                                        classRoomId.isNotEmpty &&
                                        (finalPassed ||
                                            hasFinalAttempt ||
                                            !canRetake);

                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            finalPassed
                                                ? Icons.check_circle
                                                : hasFinalAttempt
                                                ? Icons.block
                                                : isLocked
                                                ? Icons.lock
                                                : Icons.quiz,
                                            color:
                                                finalPassed
                                                    ? Colors.green
                                                    : hasFinalAttempt
                                                    ? Colors.red
                                                    : isLocked
                                                    ? Colors.grey
                                                    : colorScheme.primary,
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  quiz['title'] ?? 'Quiz',
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              if (hasFinalAttempt &&
                                                  latestMaxScore > 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '$latestScore/$latestMaxScore',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.green.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontStyle:
                                                  (hasFinalAttempt || isLocked)
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                            ),
                                          ),
                                          trailing:
                                              finalPassed
                                                  ? Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                  )
                                                  : hasFinalAttempt
                                                  ? Icon(
                                                    Icons.lock,
                                                    color: Colors.redAccent,
                                                  )
                                                  : isLocked
                                                  ? Icon(
                                                    Icons.lock_outline,
                                                    color: Colors.grey,
                                                  )
                                                  : Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 16,
                                                    color: colorScheme.primary,
                                                  ),
                                          onTap: () {
                                            if (isLocked) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Complete the previous quiz first to unlock this quiz.',
                                                  ),
                                                  backgroundColor:
                                                      colorScheme.primary,
                                                ),
                                              );
                                              return;
                                            }

                                            if (hasFinalAttempt || !canRetake) {
                                              if (submission != null &&
                                                  mounted) {
                                                _showCompletedQuizDialog(
                                                  submission,
                                                  colorScheme: colorScheme,
                                                );
                                              }
                                              return;
                                            }

                                            // Navigate to the lesson reader FIRST, then quiz
                                            _openQuizPage(
                                              quizId: quizId,
                                              assignmentId: assignmentId,
                                              taskId: taskId,
                                              classRoomId: classRoomId,
                                              lessonTitle:
                                                  lesson['title'] ?? 'Lesson',
                                              lessonIndex: index,
                                            );
                                          },
                                        ),
                                        // In the canViewMaterialOnly section of ClassContentScreen
                                        if (canViewMaterialOnly)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 72,
                                              right: 16,
                                              bottom: 12,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  _openLessonReader(
                                                    quizId: quizId,
                                                    assignmentId: assignmentId,
                                                    taskId: taskId,
                                                    classRoomId: classRoomId,
                                                    lessonTitle:
                                                        lesson['title'] ??
                                                        'Lesson',
                                                    lessonIndex: index,
                                                    viewOnly: true,
                                                    fromQuizReview:
                                                        false, // NEW: Add this flag
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.menu_book_outlined,
                                                  color: colorScheme.primary,
                                                ),
                                                label: Text(
                                                  'View material',
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
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
    );
  }

  void _showCompletedQuizDialog(
    Map<String, dynamic> submission, {
    required ColorScheme colorScheme,
  }) {
    if (!mounted) return;

    final score = submission['score'] ?? 0;
    final maxScore = submission['max_score'] ?? 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Quiz Results',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You have already completed this quiz.',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
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
                          color: colorScheme.onSurface.withOpacity(0.6),
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
                child: Text('OK', style: TextStyle(color: colorScheme.primary)),
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
    bool viewOnly = false,
    bool fromQuizReview = false, // NEW: Add this parameter
  }) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (quizId.isEmpty ||
        assignmentId.isEmpty ||
        taskId == null ||
        taskId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lesson or quiz information is incomplete'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    if (user == null || user.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    try {
      bool shouldShowLoading = false;

      // Don't check current lesson status for the FIRST lesson
      // Only check for subsequent lessons (lessonIndex > 0)
      if (lessonIndex > 0 && !viewOnly) {
        // Show loading indicator only when checking status
        shouldShowLoading = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
        );

        // Check if previous lesson is passed
        final previousLessonPassed = await _checkPreviousLessonStatus(
          lessonIndex,
        );

        // Dismiss loading
        if (mounted && shouldShowLoading) {
          Navigator.pop(context);
          shouldShowLoading = false;
        }

        if (!previousLessonPassed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Complete the previous lesson first to unlock this lesson.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // For the first lesson or when previous is passed, proceed without checking
      // NO LOADING INDICATOR when opening the lesson reader itself
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LessonReaderPage(
                taskId: taskId,
                assignmentId: assignmentId,
                classRoomId: classRoomId,
                quizId: quizId,
                studentId: user.id,
                lessonTitle: lessonTitle,
                viewOnly: viewOnly,
                fromQuizReview: fromQuizReview, // NEW: Pass the flag
              ),
        ),
      );

      if (!mounted) return;

      if (viewOnly || result == null) {
        // Refresh lessons list in case something changed
        await _refreshLessons();
        return;
      }

      // Handle quiz outcome from regular (non-viewOnly) quiz attempt
      if (result == StudentQuizOutcome.continueNext) {
        // Find next available lesson
        await _findAndNavigateToNextLesson(lessonIndex);
      } else if (result == StudentQuizOutcome.exitSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quiz completed successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (result == StudentQuizOutcome.exitFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please try the quiz again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Refresh lessons list
      await _refreshLessons();
    } catch (error) {
      debugPrint('Error navigating to lesson reader: $error');
      if (mounted) {
        // Dismiss loading if still showing
        if (Navigator.of(context).canPop()) Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening lesson: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Helper method to check previous lesson status
  Future<bool> _checkPreviousLessonStatus(int currentIndex) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return false;

    // Fetch all lessons to get the previous one
    final allLessons = await _fetchLessons();

    // If currentIndex is 0, there's no previous lesson - allow access
    if (currentIndex == 0) {
      return true;
    }

    // Get the previous lesson
    final previousLesson = allLessons[currentIndex - 1];
    final previousAssignmentId = previousLesson['assignment_id']?.toString();

    if (previousAssignmentId == null) return false;

    final submissionRes =
        await supabase
            .from('student_submissions')
            .select('score, max_score')
            .eq('assignment_id', previousAssignmentId)
            .eq('student_id', user.id)
            .order('submitted_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (submissionRes == null) {
      // No submission yet for previous lesson
      return false;
    }

    final score = (submissionRes['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (submissionRes['max_score'] as num?)?.toDouble() ?? 0;

    const double passingThreshold = 0.5;
    return maxScore > 0 && (score / maxScore) >= passingThreshold;
  }

  // Update the _findAndNavigateToNextLesson method
  Future<void> _findAndNavigateToNextLesson(int currentIndex) async {
    final latestLessons = await _fetchLessons();
    int nextIndex = currentIndex + 1;

    while (nextIndex < latestLessons.length) {
      final nextLesson = latestLessons[nextIndex];
      final bool isLocked = nextLesson['isLocked'] == true;

      if (!isLocked) {
        final nextQuizzes =
            (nextLesson['quizzes'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

        if (nextQuizzes.isNotEmpty) {
          final nextQuiz = nextQuizzes.first;
          final nextQuizId = nextQuiz['id']?.toString();
          final nextAssignmentId = nextLesson['assignment_id']?.toString();
          final nextTaskId = nextLesson['task_id']?.toString();
          final nextClassRoomId =
              nextLesson['class_room_id']?.toString() ?? widget.classRoomId;

          if (nextQuizId != null &&
              nextAssignmentId != null &&
              nextTaskId != null) {
            // Navigate to next lesson
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
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The next lesson is locked. Complete the current lesson first.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;
      }

      nextIndex++;
    }

    if (nextIndex >= latestLessons.length && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Congratulations! You have completed all available lessons in this class.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Helper method to check current lesson status
  Future<bool> _checkCurrentLessonStatus(String assignmentId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return false;

    final submissionRes =
        await supabase
            .from('student_submissions')
            .select('score, max_score')
            .eq('assignment_id', assignmentId)
            .eq('student_id', user.id)
            .order('submitted_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (submissionRes == null) return false;

    final score = (submissionRes['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (submissionRes['max_score'] as num?)?.toDouble() ?? 0;

    const double passingThreshold = 0.5;
    return maxScore > 0 && (score / maxScore) >= passingThreshold;
  }

  Future<void> _openQuizPage({
    required String quizId,
    required String assignmentId,
    required String? taskId,
    required String classRoomId,
    required String lessonTitle,
    required int lessonIndex,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // First navigate to LessonReaderPage (not viewOnly, so they can read and then take quiz)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LessonReaderPage(
              taskId: taskId!,
              assignmentId: assignmentId,
              classRoomId: classRoomId,
              quizId: quizId,
              studentId: user.id,
              lessonTitle: lessonTitle,
              viewOnly:
                  false, // NOT viewOnly - they can click "Done Reading • Take Quiz"
            ),
      ),
    );

    if (!mounted) return;

    // Handle the result from LessonReaderPage
    // In ClassContentScreen, update the code that handles 'review_lesson' result:
    if (result == 'review_lesson') {
      // Navigate to lesson reader with fromQuizReview flag
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LessonReaderPage(
                taskId: taskId!,
                assignmentId: assignmentId,
                classRoomId: classRoomId,
                quizId: quizId,
                studentId: user.id,
                lessonTitle: lessonTitle,
                viewOnly: true,
                fromQuizReview: true, // NEW: Add this flag
              ),
        ),
      );

      // After reviewing lesson, refresh the lessons list
      await _refreshLessons();
    } else if (result == StudentQuizOutcome.continueNext) {
      // Find next available lesson
      await _findAndNavigateToNextLesson(lessonIndex);
    } else if (result == StudentQuizOutcome.exitSuccess ||
        result == StudentQuizOutcome.exitFailure) {
      // Refresh the lessons list to update status
      await _refreshLessons();
    }
  }
}

// WaveClipper (same as before)
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 60,
    );
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
