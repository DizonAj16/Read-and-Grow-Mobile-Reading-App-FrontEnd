import 'dart:convert';
import 'dart:io';

enum QuestionType {
  multipleChoice,
  fillInTheBlank,
  dragAndDrop,
  matching,
  trueFalse,
  audio,
}

class QuizQuestion {
  final String? id;
  String questionText;
  QuestionType type;
  List<String>? options;
  String? correctAnswer;
  List<MatchingPair>? matchingPairs;
  String userAnswer;
  int? timeLimitSeconds;
  QuizQuestion({
    this.id,
    required this.questionText,
    required this.type,
    this.options,
    this.correctAnswer,
    this.matchingPairs,
    this.timeLimitSeconds,
    String? userAnswer,
  }) : userAnswer = userAnswer ?? '';
  QuizQuestion copyWith({
    String? id,
    String? questionText,
    QuestionType? type,
    List<String>? options,
    String? correctAnswer,
    List<MatchingPair>? matchingPairs,
    String? userAnswer,
    int? timeLimitSeconds,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      userAnswer: userAnswer ?? this.userAnswer,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
    );
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString();
    final questionText = (map['question_text'] ?? map['questionText'] ?? map['text'] ?? '').toString();
    final typeStr = (map['question_type'] ?? map['type'] ?? '').toString();
    QuestionType type;
    switch (typeStr.toLowerCase()) {
      case 'multiple_choice':
      case 'multiplechoice':
      case 'mcq':
        type = QuestionType.multipleChoice;
        break;
      case 'fill_in_the_blank':
      case 'fillintheblank':
        type = QuestionType.fillInTheBlank;
        break;
      case 'drag_and_drop':
      case 'draganddrop':
        type = QuestionType.dragAndDrop;
        break;
      case 'matching':
        type = QuestionType.matching;
        break;
      case 'true_false':
      case 'truefalse':
        type = QuestionType.trueFalse;
        break;
      case 'audio':
        type = QuestionType.audio;
        break;
      default:
        type = QuestionType.multipleChoice;
    }

    List<String>? options;
    final rawOptions = map['options'] ?? map['question_options'];
    if (rawOptions != null) {
      if (rawOptions is String) {
        try {
          final decoded = jsonDecode(rawOptions);
          if (decoded is List) options = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          options = [rawOptions];
        }
      } else if (rawOptions is List) {
        options = rawOptions.map<String>((o) {
          if (o is Map && (o['option_text'] ?? o['text'] ?? o['label']) != null) {
            return (o['option_text'] ?? o['text'] ?? o['label']).toString();
          }
          return o.toString();
        }).toList();
      }
    }
    String? correctAnswer = map['correct_answer']?.toString() ??
        map['answer']?.toString() ??
        map['correct']?.toString();

    List<MatchingPair>? matchingPairs;
    final rawPairs = map['matching_pairs'] ?? map['matchingPairs'] ?? map['pairs'] ?? map['matching'];
    if (rawPairs != null && rawPairs is List) {
      matchingPairs = rawPairs.map<MatchingPair>((p) {
        if (p is Map<String, dynamic>) return MatchingPair.fromMap(p);
        return MatchingPair(leftItem: p.toString());
      }).toList();
    }

    final userAnswer = map['userAnswer']?.toString();
    int? timeLimit;
    if (map['time_limit_seconds'] != null) {
      timeLimit = int.tryParse(map['time_limit_seconds'].toString());
    } else if (map['timeLimitSeconds'] != null) {
      timeLimit = int.tryParse(map['timeLimitSeconds'].toString());
    }

    return QuizQuestion(
      id: id,
      questionText: questionText,
      type: type,
      options: options,
      correctAnswer: correctAnswer,
      matchingPairs: matchingPairs,
      userAnswer: userAnswer,
      timeLimitSeconds: timeLimit,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'question_text': questionText,
    'question_type': type.name,
    'options': options,
    'correct_answer': correctAnswer,
    'matching_pairs': matchingPairs?.map((p) => p.toMap()).toList(),
    'userAnswer': userAnswer,
    'time_limit_seconds': timeLimitSeconds,
  };
}

class MatchingPair {
  String leftItem;
  File? rightItemFile;
  String? rightItemUrl;
  String userSelected;
  String? correctAnswer;

  MatchingPair({
    required this.leftItem,
    this.rightItemFile,
    this.rightItemUrl,
    String? userSelected,
    this.correctAnswer,
  }) : userSelected = userSelected ?? '';

  factory MatchingPair.fromMap(Map<String, dynamic> map) {
    return MatchingPair(
      leftItem: (map['left_item'] ?? map['leftItem'] ?? map['left'] ?? map['text'] ?? map['label'] ?? '').toString(),
      rightItemUrl: (map['right_item_url'] ?? map['rightItemUrl'] ?? map['right'] ?? map['imageUrl'] ?? map['url'])?.toString(),
      userSelected: map['userSelected']?.toString() ?? map['user_selected']?.toString() ?? '',
      correctAnswer: map['correct_answer']?.toString() ?? map['correctAnswer']?.toString() ?? map['answer']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'leftItem': leftItem,
    'rightItemUrl': rightItemUrl,
    'userSelected': userSelected,
    'correct_answer': correctAnswer,
  };
}
