class Paper {
  final String id;
  final String title;
  final DateTime createdAt;

  Paper({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Paper.fromFirestore(String id, Map<String, dynamic> data) {
    return Paper(
      id: id,
      title: data['title'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

