import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paper.dart';
import '../models/question.dart';
import 'add_question_screen.dart';

class PaperDetailScreen extends StatefulWidget {
  final Paper paper;

  const PaperDetailScreen({super.key, required this.paper});

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Paper _currentPaper;

  @override
  void initState() {
    super.initState();
    _currentPaper = widget.paper;
    // Listen to paper updates
    _firestore.collection('papers').doc(widget.paper.id).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentPaper = Paper.fromFirestore(snapshot.id, snapshot.data()!);
        });
      }
    });
  }

  Future<void> _editPaperName() async {
    final TextEditingController titleController = TextEditingController(text: _currentPaper.title);

    await showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          title: const Text('Edit Paper Name'),
          content: SizedBox(
            width: screenWidth > 600 ? 400 : null,
          child: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Paper Title',
              hintText: 'Enter paper title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a paper title')),
                );
                return;
              }

              try {
                await _firestore.collection('papers').doc(_currentPaper.id).update({
                  'title': titleController.text.trim(),
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paper name updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating paper: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
        );
      },
    );
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting question: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPaper.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, size: isMobile ? 20 : 24),
            onPressed: _editPaperName,
            tooltip: 'Edit Paper Name',
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 24),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('questions')
              .where('paperId', isEqualTo: _currentPaper.id)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: isMobile ? 48 : 64, color: Colors.red),
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz,
                          size: isMobile ? 48 : 96, color: Colors.grey.shade400),
                      SizedBox(height: isMobile ? 16 : 24),
                      Text(
                        'No questions yet',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 24,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 8),
                      Text(
                        isMobile
                            ? 'Tap the + button to add a question'
                            : 'Click the + button to add a question',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final questions = snapshot.data!.docs.map((doc) {
              return Question.fromFirestore(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
            }).toList();

            return ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: isMobile ? 8 : 16),
                  child: _buildQuestionCard(context, question, index, isMobile, screenWidth),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddQuestionScreen(paperId: _currentPaper.id),
                  ),
                );
              },
              tooltip: 'Add Question',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddQuestionScreen(paperId: _currentPaper.id),
                  ),
                );
              },
              tooltip: 'Add Question',
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
    );
  }

  Widget _buildQuestionCard(
      BuildContext context, Question question, int index, bool isMobile, double screenWidth) {
    final maxWidth = screenWidth > 800 ? 800.0 : screenWidth - (isMobile ? 16 : 48);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      radius: isMobile ? 16 : 24,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 18,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.questionText,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          ...question.options.asMap().entries.map((entry) {
                            final isCorrect = entry.key == question.correctAnswerIndex;
                            return Padding(
                              padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 8 : 12),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.shade50
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCorrect
                                        ? Colors.green.shade300
                                        : Colors.grey.shade300,
                                    width: isCorrect ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: isMobile ? 16 : 20,
                                      color: isCorrect ? Colors.green : Colors.grey,
                                    ),
                                    SizedBox(width: isMobile ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        '${String.fromCharCode(65 + entry.key)}. ${entry.value}',
                                        style: TextStyle(
                                          fontWeight:
                                              isCorrect ? FontWeight.bold : FontWeight.normal,
                                          fontSize: isMobile ? 12 : 16,
                                          color: isCorrect
                                              ? Colors.green.shade900
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue, size: isMobile ? 20 : 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddQuestionScreen(
                                  paperId: _currentPaper.id,
                                  question: question,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Edit Question',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: isMobile ? 20 : 24),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Question'),
                                content: const Text(
                                    'Are you sure you want to delete this question?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteQuestion(question.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          tooltip: 'Delete Question',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

