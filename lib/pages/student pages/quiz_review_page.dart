import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class QuizReviewPage extends StatefulWidget {
  final String submissionId;
  final String studentId;

  const QuizReviewPage({
    super.key,
    required this.submissionId,
    required this.studentId,
  });

  @override
  State<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> questions = [];
  int score = 0;
  int maxScore = 0;
  String quizTitle = "Quiz Review";
  String studentName = "Student";

  @override
  void initState() {
    super.initState();
    _loadQuizReview();
  }

  Future<void> _loadQuizReview() async {
    setState(() => isLoading = true);

    try {
      debugPrint("\n===============================");
      debugPrint("➡️ STARTING QUIZ REVIEW LOAD");
      debugPrint("===============================\n");

      debugPrint("🟦 Fetching submission ID: ${widget.submissionId}");

      // STEP 1: FETCH SUBMISSION AND STUDENT INFO
      final submissionRes =
          await supabase
              .from('student_submissions')
              .select(
                'score, max_score, assignment_id, quiz_answers, student_id',
              )
              .eq('id', widget.submissionId)
              .maybeSingle();

      debugPrint("📥 Submission: $submissionRes");

      if (submissionRes == null) return;

      score = submissionRes['score'] ?? 0;
      maxScore = submissionRes['max_score'] ?? 0;

      // Get student name
      final studentRes =
          await supabase
              .from('students')
              .select('student_name')
              .eq('id', submissionRes['student_id'])
              .maybeSingle();

      if (studentRes != null) {
        studentName = studentRes['student_name'] ?? 'Student';
      }

      final assignmentId = submissionRes['assignment_id'];
      debugPrint("📌 Assignment ID: $assignmentId");

      // STEP 2: FETCH ASSIGNMENT & QUIZ
      final assignmentWithQuiz =
          await supabase
              .from('assignments')
              .select('id, quiz_id, quizzes(id, title)')
              .eq('id', assignmentId)
              .single();

      debugPrint("🧩 Assignment Join: $assignmentWithQuiz");

      final quizId = assignmentWithQuiz['quiz_id'];
      debugPrint("🆔 Quiz ID: $quizId");

      final quizData = assignmentWithQuiz['quizzes'] as Map<String, dynamic>?;
      if (quizData != null && quizData['title'] != null) {
        quizTitle = quizData['title'];
      }

      // STEP 3: PARSE USER ANSWERS
      List<Map<String, dynamic>> userAnswersList = [];
      try {
        final raw = submissionRes['quiz_answers'];
        if (raw is String) {
          userAnswersList = List<Map<String, dynamic>>.from(jsonDecode(raw));
        } else if (raw is List) {
          userAnswersList = List<Map<String, dynamic>>.from(raw);
        }
      } catch (e) {
        debugPrint("⚠️ JSON decode error: $e");
      }

      debugPrint("📝 Parsed User Answers: $userAnswersList");

      // STEP 4: FETCH QUESTIONS WITH OPTION_IMAGES
      final questionsRes = await supabase
          .from('quiz_questions')
          .select(
            'id, question_text, question_type, question_image_url, option_images',
          )
          .eq('quiz_id', quizId)
          .order('sort_order', ascending: true);

      debugPrint("📋 Questions from DB: ${questionsRes.length}");

      if (questionsRes == null || questionsRes.isEmpty) {
        debugPrint("❌ No questions found for quiz ID: $quizId");
        return;
      }

      final questionIds =
          (questionsRes as List).map((q) => q['id'].toString()).toList();

      // STEP 5: FETCH OPTIONS
      final optionsRes = await supabase
          .from('question_options')
          .select('id, question_id, option_text, is_correct')
          .filter('question_id', 'in', questionIds);

      debugPrint("📊 Options from DB: ${optionsRes.length}");

      // STEP 6: FETCH MATCHING PAIRS FOR MATCHING QUESTIONS
      final matchingPairsRes = await supabase
          .from('matching_pairs')
          .select('id, question_id, left_item, right_item_url')
          .filter('question_id', 'in', questionIds);

      debugPrint("🔗 Matching pairs from DB: ${matchingPairsRes.length}");

      // Organize matching pairs by question_id
      final matchingPairsMap = <String, List<Map<String, dynamic>>>{};
      for (final pair in matchingPairsRes) {
        final qid = pair['question_id'].toString();
        matchingPairsMap.putIfAbsent(qid, () => []);
        matchingPairsMap[qid]!.add({
          'left_item': pair['left_item'],
          'right_item_url': pair['right_item_url'],
        });
      }

      // Organize options by question_id
      final optionsMap = <String, List<Map<String, dynamic>>>{};
      for (final opt in optionsRes) {
        final qid = opt['question_id'].toString();
        optionsMap.putIfAbsent(qid, () => []);
        optionsMap[qid]!.add(Map<String, dynamic>.from(opt));
      }

      // STEP 7: BUILD FINAL QUESTION LIST
      int correctCount = 0;

      questions =
          (questionsRes as List).map((q) {
            final qId = q['id'].toString();
            final type = q['question_type'];
            final opts = optionsMap[qId] ?? [];
            final questionImageUrl = q['question_image_url'];
            final matchingPairs = matchingPairsMap[qId] ?? [];

            // Get option_images from database
            final optionImages = q['option_images'] ?? {};
            debugPrint("📸 Option images for question $qId: $optionImages");
            debugPrint("📸 Options for question $qId: $opts");
            debugPrint("🔗 Matching pairs for question $qId: $matchingPairs");

            final userAnswer = userAnswersList.firstWhere(
              (e) => e['id'].toString() == qId,
              orElse: () => {},
            );

            String studentAnswer = "";
            String correctAnswer = "";
            String? studentAnswerImage;
            String? correctAnswerImage;
            bool isCorrect = false;
            Map<String, String> optionImagesMap = {};
            List<Map<String, dynamic>> userMatchingSelections = [];

            // Handle multiple choice with images (both formats)
            if (type == "multiple_choice_with_images" ||
                type == "multiplechoicewithimages") {
              // Convert option_images JSON to map
              if (optionImages is Map) {
                optionImages.forEach((key, value) {
                  if (value is String && value.isNotEmpty) {
                    optionImagesMap[key.toString()] = value;
                  }
                });
              }

              debugPrint("🗺️ Option images map: $optionImagesMap");

              final correctOpt = opts.firstWhere(
                (o) => o['is_correct'] == true,
                orElse:
                    () => {'option_text': '(No correct answer)', 'id': null},
              );

              String rawUserAnswer = "";
              String? userSelectedOptionId;
              String? correctOptionId = correctOpt['id']?.toString();

              if (userAnswer.isNotEmpty) {
                if (userAnswer.containsKey("userAnswer")) {
                  rawUserAnswer = userAnswer["userAnswer"].toString();
                  debugPrint("🎯 User answer text: $rawUserAnswer");
                }
                if (userAnswer.containsKey("selected_option_id")) {
                  userSelectedOptionId =
                      userAnswer["selected_option_id"].toString();
                  debugPrint(
                    "🎯 User selected option ID: $userSelectedOptionId",
                  );
                }

                // If no selected_option_id but we have userAnswer text, try to find matching option
                if (userSelectedOptionId == null && rawUserAnswer.isNotEmpty) {
                  for (var opt in opts) {
                    if (opt["option_text"] == rawUserAnswer) {
                      userSelectedOptionId = opt["id"]?.toString();
                      debugPrint(
                        "🔍 Found matching option by text: $userSelectedOptionId",
                      );
                      break;
                    }
                  }
                }
              }

              studentAnswer =
                  rawUserAnswer.isEmpty ? "(No answer)" : rawUserAnswer;
              correctAnswer = correctOpt['option_text'] ?? "(No correct)";

              // Get image URLs from optionImagesMap using option indices
              if (userSelectedOptionId != null) {
                // Find the index of the user's selected option
                int selectedIndex = opts.indexWhere(
                  (o) => o['id'].toString() == userSelectedOptionId,
                );
                if (selectedIndex != -1) {
                  studentAnswerImage =
                      optionImagesMap[selectedIndex.toString()];
                  debugPrint(
                    "🖼️ Student answer image at index $selectedIndex: $studentAnswerImage",
                  );
                }
              }

              if (correctOptionId != null) {
                // Find the index of the correct option
                int correctIndex = opts.indexWhere(
                  (o) => o['id'].toString() == correctOptionId,
                );
                if (correctIndex != -1) {
                  correctAnswerImage = optionImagesMap[correctIndex.toString()];
                  debugPrint(
                    "✅ Correct answer image at index $correctIndex: $correctAnswerImage",
                  );
                }
              }

              // Check if answer is correct
              isCorrect = rawUserAnswer == correctAnswer;
              debugPrint("✓ Is correct: $isCorrect");

              // Add option images to option data for display
              for (int i = 0; i < opts.length; i++) {
                final imageUrl = optionImagesMap[i.toString()];
                opts[i]['option_image_url'] = imageUrl;
                debugPrint(
                  "📋 Option $i (${opts[i]['option_text']}): $imageUrl",
                );
              }
            } else if (type == "fill_in_the_blank_with_image" ||
                type == "fillintheblankwithimage") {
              final correctOpt = opts.firstWhere(
                (o) => o['is_correct'] == true,
                orElse: () => {'option_text': '(No correct answer)'},
              );
              correctAnswer = correctOpt['option_text'] ?? "(No correct)";

              String rawUserAnswer = "";
              if (userAnswer.isNotEmpty &&
                  userAnswer.containsKey("userAnswer")) {
                rawUserAnswer = userAnswer["userAnswer"].toString();
              }
              studentAnswer =
                  rawUserAnswer.isEmpty ? "(No answer)" : rawUserAnswer;
              isCorrect =
                  studentAnswer.trim().toLowerCase() ==
                  correctAnswer.trim().toLowerCase();
            } else if (type == "matching") {
              // Handle matching type questions
              debugPrint(
                "🔍 Checking for matching_pairs in userAnswer: ${userAnswer.containsKey('matching_pairs')}",
              );

              if (userAnswer.isNotEmpty &&
                  userAnswer.containsKey("matching_pairs")) {
                final matchingPairsData = userAnswer["matching_pairs"];
                debugPrint(
                  "🔍 matching_pairs data type: ${matchingPairsData.runtimeType}",
                );

                if (matchingPairsData is List) {
                  debugPrint(
                    "🔍 matching_pairs is List with length: ${matchingPairsData.length}",
                  );

                  // First, extract the correct matching pairs (from rightItemUrl in quiz_answers)
                  matchingPairs.clear();

                  // Then extract user matching selections from the same data
                  for (var pair in matchingPairsData) {
                    if (pair is Map) {
                      debugPrint("🔍 Processing pair: $pair");

                      // Add to correct matching pairs
                      matchingPairs.add({
                        'left_item': pair['leftItem'] ?? '',
                        'right_item_url': pair['rightItemUrl'] ?? '',
                      });

                      // Add to user selections
                      userMatchingSelections.add({
                        'left_item': pair['leftItem'] ?? '',
                        'user_selected': pair['userSelected'] ?? '',
                        'correct_image_url': pair['rightItemUrl'] ?? '',
                      });
                    }
                  }
                }
              }

              // For matching questions, check if all pairs are correct
              if (matchingPairs.isNotEmpty &&
                  userMatchingSelections.isNotEmpty) {
                int correctMatches = 0;
                for (var userSelection in userMatchingSelections) {
                  final leftItem = userSelection['left_item']?.toString() ?? '';
                  final userSelected =
                      userSelection['user_selected']?.toString() ?? '';

                  debugPrint("🔍 Checking match: $leftItem -> $userSelected");

                  // In your data structure, userSelected contains the text (like "nag")
                  // and the leftItem is also "nag", so if userSelected == leftItem, it's correct
                  if (userSelected == leftItem) {
                    correctMatches++;
                    debugPrint("✅ Match correct: $leftItem == $userSelected");
                  } else {
                    debugPrint("❌ Match wrong: $leftItem != $userSelected");
                  }
                }
                isCorrect = correctMatches == matchingPairs.length;
                debugPrint(
                  "🔍 Matching question result: $correctMatches/${matchingPairs.length} correct, isCorrect: $isCorrect",
                );
              } else {
                debugPrint(
                  "🔍 No matching data found: pairs=${matchingPairs.length}, selections=${userMatchingSelections.length}",
                );
              }
            } else {
              // For other question types, also handle option images if they exist
              if (optionImages is Map) {
                optionImages.forEach((key, value) {
                  if (value is String && value.isNotEmpty) {
                    optionImagesMap[key.toString()] = value;
                  }
                });
              }

              // Add option images to option data for display
              for (int i = 0; i < opts.length; i++) {
                final imageUrl = optionImagesMap[i.toString()];
                opts[i]['option_image_url'] = imageUrl;
                debugPrint(
                  "📋 Option $i (${opts[i]['option_text']}): $imageUrl",
                );
              }

              final correctOpt = opts.firstWhere(
                (o) => o['is_correct'] == true,
                orElse: () => {'option_text': '(No correct answer)'},
              );
              correctAnswer = correctOpt['option_text'] ?? "(No correct)";

              String rawUserAnswer = "";
              if (userAnswer.isNotEmpty) {
                if (userAnswer.containsKey("userAnswer")) {
                  rawUserAnswer = userAnswer["userAnswer"].toString();
                }
                if (userAnswer.containsKey("selected_option_id")) {
                  final selected = userAnswer["selected_option_id"];
                  final studentOpt = opts.firstWhere(
                    (o) => o["id"] == selected,
                    orElse: () => {"option_text": rawUserAnswer},
                  );
                  rawUserAnswer = studentOpt["option_text"].toString();
                }
              }
              studentAnswer =
                  rawUserAnswer.isEmpty ? "(No answer)" : rawUserAnswer;
              isCorrect =
                  studentAnswer.trim().toLowerCase() ==
                  correctAnswer.trim().toLowerCase();
            }

            if (isCorrect) correctCount++;

            return {
              'id': qId,
              'questionText': q['question_text'],
              'type': type,
              'questionImageUrl': questionImageUrl,
              'options': opts,
              'studentAnswer': studentAnswer,
              'studentAnswerImage': studentAnswerImage,
              'correctAnswer': correctAnswer,
              'correctAnswerImage': correctAnswerImage,
              'isCorrect': isCorrect,
              'optionImagesMap': optionImagesMap,
              'matchingPairs': matchingPairs,
              'userMatchingSelections': userMatchingSelections,
            };
          }).toList();

      score = correctCount;
      maxScore = questions.length;

      debugPrint("✅ Questions loaded: ${questions.length}");
      debugPrint("✅ Score: $score/$maxScore");
    } catch (e, stackTrace) {
      debugPrint("❌ FATAL ERROR: $e");
      debugPrint("❌ Stack trace: $stackTrace");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final percentage = maxScore > 0 ? (score / maxScore * 100).round() : 0;
    Color scoreColor;
    IconData scoreIcon;

    if (percentage >= 80) {
      scoreColor = Colors.green;
      scoreIcon = Icons.emoji_events;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      scoreIcon = Icons.thumb_up;
    } else {
      scoreColor = primaryColor;
      scoreIcon = Icons.lightbulb_outline;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(scoreIcon, size: 48, color: scoreColor),
            const SizedBox(height: 12),
            Text(
              '$score / $maxScore',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% Correct',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: maxScore > 0 ? score / maxScore : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionImage(String? imageUrl, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: primaryColor, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMultipleChoiceWithImagesSection(Map<String, dynamic> q) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    final studentAnswer = q['studentAnswer'];
    final studentAnswerImage = q['studentAnswerImage'];
    final correctAnswer = q['correctAnswer'];
    final correctAnswerImage = q['correctAnswerImage'];
    final isCorrect = q['isCorrect'];
    final optionImagesMap = q['optionImagesMap'] ?? {};
    final questionImageUrl = q['questionImageUrl'];

    debugPrint("\n🎨 BUILDING MCQ WITH IMAGES SECTION");
    debugPrint("🎨 Student answer: '$studentAnswer'");
    debugPrint("🎨 Student answer image: '$studentAnswerImage'");
    debugPrint("🎨 Correct answer: '$correctAnswer'");
    debugPrint("🎨 Correct answer image: '$correctAnswerImage'");
    debugPrint("🎨 Is correct: $isCorrect");
    debugPrint("🎨 Option images map: $optionImagesMap");
    debugPrint("🎨 Question image URL: $questionImageUrl");

    // Get all options
    final options = q['options'] as List<Map<String, dynamic>>;
    debugPrint("🎨 Total options: ${options.length}");

    // Find the correct option
    Map<String, dynamic>? correctOption;
    for (var option in options) {
      if (option['is_correct'] == true) {
        correctOption = option;
        break;
      }
    }

    // Find the student's selected option
    Map<String, dynamic>? selectedOption;
    if (studentAnswer.isNotEmpty && studentAnswer != "(No answer)") {
      for (var option in options) {
        if (option['option_text'] == studentAnswer) {
          selectedOption = option;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display question image if it exists
        if (questionImageUrl != null && questionImageUrl.isNotEmpty)
          _buildQuestionImage(questionImageUrl, 'Question Image:'),

        // Student Answer Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Your Selection:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildOptionCard(
                text: studentAnswer,
                imageUrl: studentAnswerImage,
                isCorrect: isCorrect,
                isStudentAnswer: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Correct Answer Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Correct Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildOptionCard(
                text: correctAnswer,
                imageUrl: correctAnswerImage,
                isCorrect: true,
                isStudentAnswer: false,
              ),
            ],
          ),
        ),

        // Show all available options
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.list, color: Colors.grey[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'All Available Options:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    options.map((option) {
                      final optionText = option['option_text'] ?? "";
                      final optionImage = option['option_image_url'];
                      final isThisCorrect = option['is_correct'] == true;
                      final isThisSelected = studentAnswer == optionText;

                      return Container(
                        width: 100,
                        child: _buildSmallOptionCard(
                          text: optionText,
                          imageUrl: optionImage,
                          isCorrect: isThisCorrect,
                          isSelected: isThisSelected,
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String text,
    required String? imageUrl,
    required bool isCorrect,
    required bool isStudentAnswer,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final borderColor =
        isStudentAnswer
            ? (isCorrect ? Colors.green : Colors.red) // Changed to red
            : Colors.green;
    final backgroundColor = isStudentAnswer ? Colors.white : Colors.white;
    final textColor =
        isStudentAnswer
            ? (isCorrect
                ? Colors.green[800]
                : Colors.red[800]) // Changed to red
            : Colors.green[800];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[100],
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (text.isNotEmpty && text != "(No answer)")
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (text.isEmpty || text == "(No answer)")
                  Text(
                    text.isEmpty ? 'No answer provided' : text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 4),
                if (isStudentAnswer)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.close,
                        color:
                            isCorrect
                                ? Colors.green
                                : Colors.red, // Changed to red
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'Correct' : 'Wrong',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isCorrect
                                  ? Colors.green
                                  : Colors.red, // Changed to red
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallOptionCard({
    required String text,
    required String? imageUrl,
    required bool isCorrect,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isSelected
                  ? (isCorrect ? Colors.green : Colors.red) // Changed to red
                  : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
              child: Container(
                height: 60,
                width: double.infinity,
                color: Colors.grey[100],
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                if (text.isNotEmpty)
                  Text(
                    text.length > 15 ? '${text.substring(0, 15)}...' : text,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected
                              ? (isCorrect
                                  ? Colors.green[800]
                                  : Colors.red[800]) // Changed to red
                              : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (text.isEmpty && imageUrl != null)
                  Text(
                    'Image only',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (isCorrect) Icon(Icons.check, color: Colors.green, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillInTheBlankWithImageSection(Map<String, dynamic> q) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    final studentAnswer = q['studentAnswer'];
    final correctAnswer = q['correctAnswer'];
    final isCorrect = q['isCorrect'];
    final questionImageUrl = q['questionImageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display question image
        if (questionImageUrl != null && questionImageUrl.isNotEmpty)
          _buildQuestionImage(questionImageUrl, 'Question Image:'),

        // Student Answer Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Your Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isCorrect
                            ? Colors.green[300]!
                            : Colors.red[300]!, // Changed to red
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                child: Text(
                  studentAnswer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        isCorrect
                            ? Colors.green[800]
                            : Colors.red[800], // Changed to red
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Correct Answer Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Correct Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!, width: 2),
                ),
                child: Text(
                  correctAnswer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingSection(Map<String, dynamic> q) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    final matchingPairs = q['matchingPairs'] as List<Map<String, dynamic>>;
    final userMatchingSelections =
        q['userMatchingSelections'] as List<Map<String, dynamic>>;
    final isCorrect = q['isCorrect'];
    final questionImageUrl = q['questionImageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display question image
        if (questionImageUrl != null && questionImageUrl.isNotEmpty)
          _buildQuestionImage(questionImageUrl, 'Question Image:'),

        // Student Matching Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Your Matching:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Display user's matching attempts
              if (userMatchingSelections.isNotEmpty)
                Column(
                  children:
                      userMatchingSelections.map((selection) {
                        final leftItem =
                            selection['left_item']?.toString() ?? '';
                        final userSelected =
                            selection['user_selected']?.toString() ?? '';
                        final correctImageUrl =
                            selection['correct_image_url']?.toString() ?? '';
                        final isSelectionCorrect = userSelected == leftItem;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  isSelectionCorrect
                                      ? Colors.green
                                      : Colors.red, // Changed to red
                              width: isSelectionCorrect ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Left item (text)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    leftItem,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              // Arrow
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color:
                                      isSelectionCorrect
                                          ? Colors.green
                                          : Colors.red, // Changed to red
                                  size: 16,
                                ),
                              ),

                              // User's selected item
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelectionCorrect
                                            ? Colors.green[50]
                                            : Colors.red[50], // Changed to red
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        userSelected,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isSelectionCorrect
                                                  ? Colors.green[800]
                                                  : Colors
                                                      .red[800], // Changed to red
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (correctImageUrl.isNotEmpty &&
                                          userSelected == leftItem)
                                        Container(
                                          height: 40,
                                          margin: const EdgeInsets.only(top: 4),
                                          child: Image.network(
                                            correctImageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                )
              else
                Text(
                  'No matching attempt recorded',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Correct Matching Pairs Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Correct Matching Pairs:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (matchingPairs.isNotEmpty)
                Column(
                  children:
                      matchingPairs.map((pair) {
                        final leftItem = pair['left_item']?.toString() ?? '';
                        final rightItemUrl =
                            pair['right_item_url']?.toString() ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green[200]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Left item (text)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    leftItem,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              // Arrow
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),

                              // Right item (image)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Correct match',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (rightItemUrl.isNotEmpty)
                                        Container(
                                          height: 40,
                                          margin: const EdgeInsets.only(top: 4),
                                          child: Image.network(
                                            rightItemUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                )
              else
                Text(
                  'No correct pairs defined',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // Matching result summary
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isCorrect ? Colors.green[50] : Colors.red[50], // Changed to red
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isCorrect
                      ? Colors.green[100]!
                      : Colors.red[100]!, // Changed to red
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.close,
                color:
                    isCorrect
                        ? Colors.green[700]
                        : Colors.red[700], // Changed to red
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'All pairs matched correctly!'
                      : 'Some pairs were not matched correctly.',
                  style: TextStyle(
                    color:
                        isCorrect
                            ? Colors.green[700]
                            : Colors.red[700], // Changed to red
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardQuestionSection(Map<String, dynamic> q) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    final studentAnswer = q['studentAnswer'];
    final correctAnswer = q['correctAnswer'];
    final isCorrect = q['isCorrect'];
    final questionImageUrl = q['questionImageUrl'];
    final options = q['options'] as List<Map<String, dynamic>>;
    final optionImagesMap = q['optionImagesMap'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display question image
        if (questionImageUrl != null && questionImageUrl.isNotEmpty)
          _buildQuestionImage(questionImageUrl, 'Question Image:'),

        // Student Answer Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Your Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isCorrect
                            ? Colors.green[300]!
                            : Colors.red[300]!, // Changed to red
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                child: Text(
                  studentAnswer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        isCorrect
                            ? Colors.green[800]
                            : Colors.red[800], // Changed to red
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Correct Answer Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Correct Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!, width: 2),
                ),
                child: Text(
                  correctAnswer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show all options if this is a multiple choice question
        if (options.isNotEmpty)
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list, color: Colors.grey[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'All Options:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children:
                          options.map((option) {
                            final optionText = option['option_text'] ?? "";
                            final optionImage = option['option_image_url'];
                            final isThisCorrect = option['is_correct'] == true;
                            final isThisSelected = studentAnswer == optionText;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isThisSelected
                                          ? (isCorrect
                                              ? Colors.green
                                              : Colors.red) // Changed to red
                                          : Colors.grey[300]!,
                                  width: isThisSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Option image if available
                                  if (optionImage != null &&
                                      optionImage.isNotEmpty)
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Image.network(
                                        optionImage,
                                        fit: BoxFit.contain,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    ),

                                  // Option text and status
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              optionText,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    isThisSelected
                                                        ? (isCorrect
                                                            ? Colors.green[800]
                                                            : Colors
                                                                .red[800]) // Changed to red
                                                        : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          if (isThisCorrect)
                                            Icon(
                                              Icons.check,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final isCorrect = q['isCorrect'];
    final type = q['type'];
    final questionText = q['questionText'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isCorrect
                  ? Colors.green[100]!
                  : Colors.red[100]!, // Changed to red
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with number and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isCorrect
                            ? Colors.green[50]
                            : Colors.red[50], // Changed to red
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isCorrect
                              ? Colors.green[200]!
                              : Colors.red[200]!, // Changed to red
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.close,
                        size: 14,
                        color:
                            isCorrect
                                ? Colors.green[700]
                                : Colors.red[700], // Changed to red
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'Correct' : 'Wrong',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isCorrect
                                  ? Colors.green[700]
                                  : Colors.red[700], // Changed to red
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Question type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Text(
                type.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Question text
            Text(
              questionText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 20),

            // Question-specific content based on type
            if (type == "multiple_choice_with_images" ||
                type == "multiplechoicewithimages")
              _buildMultipleChoiceWithImagesSection(q)
            else if (type == "fill_in_the_blank_with_image" ||
                type == "fillintheblankwithimage")
              _buildFillInTheBlankWithImageSection(q)
            else if (type == "matching")
              _buildMatchingSection(q)
            else
              _buildStandardQuestionSection(q),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          quizTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : questions.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No questions found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Container(
                color: Colors.grey[50],
                child: Column(
                  children: [
                    // Score Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildScoreCard(),
                    ),

                    // Questions List
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              return _buildQuestionCard(
                                questions[index],
                                index,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
