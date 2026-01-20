import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/question.dart';

class AddQuestionScreen extends StatefulWidget {
  final String paperId;
  final Question? question;

  const AddQuestionScreen({
    super.key,
    required this.paperId,
    this.question,
  });

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late int _correctAnswerIndex;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    final isEditMode = widget.question != null;
    
    _questionController = TextEditingController(
      text: isEditMode ? widget.question!.questionText : '',
    );

    if (isEditMode) {
      _optionControllers = widget.question!.options
          .map((option) => TextEditingController(text: option))
          .toList();
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
    } else {
      _optionControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      _correctAnswerIndex = 0;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctAnswerIndex >= _optionControllers.length) {
          _correctAnswerIndex = _optionControllers.length - 1;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
    }
  }

  Future<void> _saveQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
      return;
    }

    if (_correctAnswerIndex >= _optionControllers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid correct answer')),
      );
      return;
    }

    try {
      // Find the actual index in the filtered options list
      final filteredOptions = <String>[];
      final optionIndexMap = <int, int>{};
      int filteredIndex = 0;

      for (int i = 0; i < _optionControllers.length; i++) {
        final text = _optionControllers[i].text.trim();
        if (text.isNotEmpty) {
          filteredOptions.add(text);
          optionIndexMap[i] = filteredIndex;
          filteredIndex++;
        }
      }

      final correctIndexInFiltered = optionIndexMap[_correctAnswerIndex] ?? 0;

      final isEditMode = widget.question != null;

      if (isEditMode) {
        await _firestore.collection('questions').doc(widget.question!.id).update({
          'questionText': _questionController.text.trim(),
          'options': filteredOptions,
          'correctAnswerIndex': correctIndexInFiltered,
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question updated successfully')),
          );
        }
      } else {
        await _firestore.collection('questions').add({
          'paperId': widget.paperId,
          'questionText': _questionController.text.trim(),
          'options': filteredOptions,
          'correctAnswerIndex': correctIndexInFiltered,
          'createdAt': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isEditMode = widget.question != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${isEditMode ? 'updating' : 'adding'} question: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 800 ? 700.0 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.question != null ? 'Edit Question' : 'Add Question',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWeb ? 32 : 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter your question',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Answer Options',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ..._optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: _correctAnswerIndex,
                              onChanged: (value) {
                                setState(() {
                                  _correctAnswerIndex = value!;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Option ${String.fromCharCode(65 + index)}',
                                  hintText: 'Enter option text',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.radio_button_checked,
                                    size: 20,
                                    color: _correctAnswerIndex == index
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  suffixIcon: _optionControllers.length > 2
                                      ? IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeOption(index),
                                          tooltip: 'Remove Option',
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: isWeb ? 28 : 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select the radio button next to the correct answer',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: isWeb ? 15 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isWeb ? 18 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.question != null ? 'Update Question' : 'Save Question',
                    style: TextStyle(fontSize: isWeb ? 17 : 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

