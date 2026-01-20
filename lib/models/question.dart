class Question {
  final String id;
  final String paperId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.paperId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'paperId': paperId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    return Question(
      id: id,
      paperId: data['paperId'] ?? '',
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: (data['correctAnswerIndex'] ?? 0) as int,
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

