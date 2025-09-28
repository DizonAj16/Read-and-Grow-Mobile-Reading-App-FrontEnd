enum QuestionType { multipleChoice, fillInTheBlank, dragAndDrop, matching, trueFalse }

class QuizQuestion {
  String questionText;
  QuestionType type;
  List<String>? options; // multiple choice or drag/drop
  String? correctAnswer; // for multiple choice or fill-in-the-blank

  List<MatchingPair>? matchingPairs; // for matching type
  String userAnswer; // track student's answer

  QuizQuestion({
    required this.questionText,
    required this.type,
    this.options,
    this.correctAnswer,
    this.matchingPairs,
    String? userAnswer,
  }) : userAnswer = userAnswer ?? '';
}

class MatchingPair {
  String leftItem;       // text to drag
  String rightItemUrl;   // image to drop onto
  String? userSelected;  // track student selection

  MatchingPair({
    required this.leftItem,
    required this.rightItemUrl,
    this.userSelected,
  });
}
