import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question != null ? 'Edit Question' : 'Add Question'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'Enter your question',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Option ${String.fromCharCode(65 + index)}',
                          hintText: 'Enter option text',
                          border: const OutlineInputBorder(),
                          suffixIcon: _optionControllers.length > 2
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeOption(index),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select the radio button next to the correct answer',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.question != null ? 'Update Question' : 'Save Question',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

