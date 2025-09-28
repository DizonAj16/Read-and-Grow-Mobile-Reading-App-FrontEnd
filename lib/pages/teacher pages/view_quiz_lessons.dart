import 'package:flutter/material.dart';
import '../../../../api/supabase_api_service.dart';
import '../../../../models/quiz_questions.dart';

class LessonQuizListScreen extends StatefulWidget {
  const LessonQuizListScreen({super.key});

  @override
  State<LessonQuizListScreen> createState() => _LessonQuizListScreenState();
}

class _LessonQuizListScreenState extends State<LessonQuizListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _lessons = await ApiService.getLessons() ?? [];
      _quizzes = await ApiService.getQuizzes() ?? [];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lessons & Quizzes'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Lessons'), Tab(text: 'Quizzes')],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildLessonList(),
            _buildQuizList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList() {
    if (_lessons.isEmpty) return const Center(child: Text('No lessons added yet.'));
    return ListView.builder(
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(lesson['title'] ?? 'No Title'),
            subtitle: Text(lesson['description'] ?? ''),
            trailing: ElevatedButton(
              child: const Text('View Quiz'),
              onPressed: () {
                if (lesson['quiz_id'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPreviewScreen(quizId: lesson['quiz_id']),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizList() {
    if (_quizzes.isEmpty) return const Center(child: Text('No quizzes added yet.'));
    return ListView.builder(
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(quiz['title'] ?? 'No Title'),
            trailing: ElevatedButton(
              child: const Text('View'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPreviewScreen(quizId: quiz['id']),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ===========================================
// INTERACTIVE QUIZ SCREEN
// ===========================================
class QuizPreviewScreen extends StatefulWidget {
  final String quizId;
  const QuizPreviewScreen({super.key, required this.quizId});

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      final fetchedQuestions = await ApiService.getQuizQuestions(widget.quizId) ?? [];
      _questions = fetchedQuestions.map((q) {
        q.options ??= [];
        q.matchingPairs ??= [];
        q.userAnswer = q.userAnswer ?? '';
        return q;
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quiz: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) setState(() => _currentIndex++);
  }

  void _prevQuestion() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions')));

    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Quiz Preview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentIndex + 1}/${_questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(q.questionText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            // MULTIPLE CHOICE
            if (q.type == QuestionType.multipleChoice && q.options!.isNotEmpty)
              Column(
                children: List.generate(q.options!.length, (i) {
                  return ListTile(
                    title: Text(q.options![i]),
                    leading: Radio<String>(
                      value: q.options![i],
                      groupValue: q.userAnswer,
                      onChanged: (val) => setState(() => q.userAnswer = val ?? ''),
                    ),
                  );
                }),
              ),

            // DRAG & DROP
            if (q.type == QuestionType.dragAndDrop && q.options!.isNotEmpty)
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = q.options?.removeAt(oldIndex);
                      q.options?.insert(newIndex, item!);
                    });
                  },
                  children: [
                    for (int i = 0; i < q.options!.length; i++)
                      ListTile(
                        key: ValueKey(q.options![i] + i.toString()),
                        title: Text(q.options![i]),
                        trailing: const Icon(Icons.drag_handle),
                      )
                  ],
                ),
              ),

            // MATCHING
            if (q.type == QuestionType.matching && q.matchingPairs!.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Drag the text to madddtch the images',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          // Left column: draggable items
                          Expanded(
                            child: ListView(
                              children: q.matchingPairs!
                                  .where((pair) => pair.userSelected == null) // <-- only show unmatched items
                                  .map(
                                    (pair) => Draggable<String>(
                                  data: pair.leftItem,
                                  feedback: Material(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.blue,
                                      child: Text(pair.leftItem, style: const TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                  childWhenDragging: Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.grey[300],
                                    child: Text(pair.leftItem),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    color: Colors.blue[100],
                                    child: Text(pair.leftItem),
                                  ),
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Right column: drop targets (images)
                          Expanded(
                            child: ListView(
                              children: q.matchingPairs!
                                  .map(
                                    (pair) => DragTarget<String>(
                                  onAccept: (received) {
                                    setState(() {
                                      pair.userSelected = received;
                                    });
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      padding: const EdgeInsets.all(8),
                                      height: 100,
                                      color: Colors.green[100],
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: (pair.rightItemUrl != null && pair.rightItemUrl!.isNotEmpty)
                                                ? Image.network(pair.rightItemUrl!, fit: BoxFit.contain)
                                                : const SizedBox(),
                                          ),
                                          Text(pair.userSelected ?? 'Drop text here'),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // FILL IN THE BLANK
            if (q.type == QuestionType.fillInTheBlank)
              TextField(
                decoration: const InputDecoration(labelText: 'Your Answer'),
                onChanged: (val) => q.userAnswer = val,
              ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  ElevatedButton(onPressed: _prevQuestion, child: const Text('Previous')),
                if (_currentIndex < _questions.length - 1)
                  ElevatedButton(onPressed: _nextQuestion, child: const Text('Next')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
