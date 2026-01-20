import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paper.dart';
import 'paper_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addPaper() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a paper title')),
      );
      return;
    }

    try {
      await _firestore.collection('papers').add({
        'title': _titleController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      _titleController.clear();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paper added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding paper: $e')),
        );
      }
    }
  }

  Future<void> _editPaper(Paper paper) async {
    final TextEditingController titleController = TextEditingController(text: paper.title);

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
                await _firestore.collection('papers').doc(paper.id).update({
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

  void _showAddPaperDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          title: const Text('Add Paper'),
          content: SizedBox(
            width: screenWidth > 600 ? 400 : null,
          child: TextField(
            controller: _titleController,
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
            onPressed: () {
              _titleController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addPaper,
            child: const Text('Add'),
          ),
        ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isLargeScreen = screenWidth > 600;
    final crossAxisCount = isLargeScreen ? (screenWidth > 1200 ? 3 : 2) : 1;
    final childAspectRatio = isLargeScreen ? 1.5 : 1.1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Papers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 24),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('papers')
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
                      Icon(Icons.description,
                          size: isMobile ? 48 : 96, color: Colors.grey.shade400),
                      SizedBox(height: isMobile ? 16 : 24),
                      Text(
                        'No papers yet',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 24,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 8),
                      Text(
                        isMobile
                            ? 'Tap the + button to add a paper'
                            : 'Click the + button to add a paper',
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

            final papers = snapshot.data!.docs.map((doc) {
              return Paper.fromFirestore(
                  doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            if (isLargeScreen) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: papers.length,
                itemBuilder: (context, index) {
                  final paper = papers[index];
                  return _buildPaperCard(context, paper, isMobile);
                },
              );
            } else {
              return ListView.builder(
                itemCount: papers.length,
                    itemBuilder: (context, index) {
                  final paper = papers[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                    child: _buildPaperCard(context, paper, isMobile),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _showAddPaperDialog,
              tooltip: 'Add Paper',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: _showAddPaperDialog,
              tooltip: 'Add Paper',
              icon: const Icon(Icons.add),
              label: const Text('Add Paper'),
            ),
    );
  }

  Widget _buildPaperCard(BuildContext context, Paper paper, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaperDetailScreen(paper: paper),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: isMobile ? 20 : 32,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue, size: isMobile ? 18 : 24),
                    onPressed: () => _editPaper(paper),
                    tooltip: 'Edit Paper Name',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                paper.title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                'Created: ${paper.createdAt.day}/${paper.createdAt.month}/${paper.createdAt.year}',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Questions',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: isMobile ? 2 : 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: isMobile ? 12 : 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

