import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flip_card/flip_card.dart';

void main() {
  runApp(const Flashcards());
}

class Flashcards extends StatelessWidget {
  const Flashcards({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      ),
      home: const FlashcardFoldersScreen(),
    );
  }
}

// Screen 1: Flashcard Folder Screen
class FlashcardFoldersScreen extends StatefulWidget {
  const FlashcardFoldersScreen({super.key});

  @override
  State<FlashcardFoldersScreen> createState() => _FlashcardFoldersScreenState();
}

class _FlashcardFoldersScreenState extends State<FlashcardFoldersScreen> {
  List<Map<String, dynamic>> _flashcardSets = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcardSets();
  }

  void _loadFlashcardSets() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedSets = prefs.getStringList('flashcard_sets') ?? [];
    setState(() {
      _flashcardSets = savedSets
          .map((set) => jsonDecode(set) as Map<String, dynamic>)
          .toList();
    });
  }

  void _navigateToCreateFlashcardSet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateFlashcardSetScreen()),
    );
    _loadFlashcardSets();
  }

  void _deleteFlashcardSet(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedSets = prefs.getStringList('flashcard_sets') ?? [];
    savedSets.removeAt(index);
    await prefs.setStringList('flashcard_sets', savedSets);
    _loadFlashcardSets();
  }

  void _navigateToViewFlashcardSet(Map<String, dynamic> flashcardSet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewFlashcardScreen(flashcardSet: flashcardSet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Flashcard Sets",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _flashcardSets.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "No flashcards made yet. Tap the + button to create a new set.",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        itemCount: _flashcardSets.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              title: Text(
                _flashcardSets[index]['title'],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                _flashcardSets[index]['description'],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              leading: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(Icons.folder, color: Colors.blue, size: 24.0),
              ),
              onTap: () => _navigateToViewFlashcardSet(_flashcardSets[index]),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFlashcardSet(index),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateFlashcardSet,
        backgroundColor: Colors.orange[300],
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Screen 2: Flashcard Creation Screen
class CreateFlashcardSetScreen extends StatefulWidget {
  const CreateFlashcardSetScreen({super.key});

  @override
  State<CreateFlashcardSetScreen> createState() =>
      _CreateFlashcardSetScreenState();
}

class _CreateFlashcardSetScreenState extends State<CreateFlashcardSetScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<Map<String, String>> _flashcards = [];

  void _addFlashcard() {
    setState(() {
      _flashcards.add({'term': '', 'definition': ''});
    });
  }

  void _saveFlashcards() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the set!')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String flashcardSet = jsonEncode({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'flashcards': _flashcards,
    });

    List<String> savedSets = prefs.getStringList('flashcard_sets') ?? [];
    savedSets.add(flashcardSet);
    await prefs.setStringList('flashcard_sets', savedSets);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flashcard set saved locally!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: true,
        title: const Text(
            "New Flashcard Set",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Enter a title',
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Add a description...',
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _flashcards.length,
                itemBuilder: (context, index) {
                  return _buildFlashcardTile(index);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addFlashcard,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Flashcard"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveFlashcards,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Set"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardTile(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flashcard ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                _flashcards[index]['term'] = value;
              },
              decoration: const InputDecoration(
                labelText: 'Enter term',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                _flashcards[index]['definition'] = value;
              },
              decoration: const InputDecoration(
                labelText: 'Enter definition',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 3: View Flashcard Screen
class ViewFlashcardScreen extends StatefulWidget {
  final Map<String, dynamic> flashcardSet;

  const ViewFlashcardScreen({super.key, required this.flashcardSet});

  @override
  State<ViewFlashcardScreen> createState() => _ViewFlashcardScreenState();
}

class _ViewFlashcardScreenState extends State<ViewFlashcardScreen> {
  int _currentCardIndex = 0;

  Future<void> _refreshFlashcards() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedSets = prefs.getStringList('flashcard_sets') ?? [];

      int setIndex = savedSets.indexWhere((set) =>
      jsonDecode(set)['title'] == widget.flashcardSet['title']);

      if (setIndex != -1) {
        Map<String, dynamic> updatedSet = jsonDecode(savedSets[setIndex]);

        setState(() {
          widget.flashcardSet['flashcards'] = updatedSet['flashcards'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard set not found!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error refreshing flashcards!')),
      );
    }
  }

  void _deleteFlashcard(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedSets = prefs.getStringList('flashcard_sets') ?? [];

    int setIndex = savedSets.indexWhere((set) =>
    jsonDecode(set)['title'] == widget.flashcardSet['title']);

    if (setIndex != -1) {
      Map<String, dynamic> updatedSet = jsonDecode(savedSets[setIndex]);

      updatedSet['flashcards'].removeAt(index);

      savedSets[setIndex] = jsonEncode(updatedSet);
      await prefs.setStringList('flashcard_sets', savedSets);

      setState(() {
        widget.flashcardSet['flashcards'].removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcard deleted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> flashcardsDynamic = widget.flashcardSet['flashcards'] ?? [];
    List<Map<String, dynamic>> flashcards = List<Map<String, dynamic>>.from(flashcardsDynamic);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.flashcardSet['title'],
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFlashcards,
        child: flashcards.isEmpty
            ? const Center(
          child: Text(
            "No flashcards to show.",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: flashcards.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentCardIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return FlipCard(
                    direction: FlipDirection.VERTICAL,
                    speed: 500,
                    onFlip: () {},
                    front: _buildCardContent(
                      flashcards[index]['definition'],
                      "Definition",
                    ),
                    back: _buildCardContent(
                      flashcards[index]['term'],
                      "Term",
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Card ${_currentCardIndex + 1} of ${flashcards.length}",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () => _navigateToAddFlashcards(widget.flashcardSet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("Add Card"),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () => _deleteFlashcard(_currentCardIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("Delete Card"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(String content, String label) {
    return Card(
      key: ValueKey(label),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddFlashcards(Map<String, dynamic> flashcardSet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFlashcardsScreen(flashcardSet: flashcardSet),
      ),
    );
    setState(() {});
  }
}

class AddFlashcardsScreen extends StatefulWidget {
  final Map<String, dynamic> flashcardSet;

  const AddFlashcardsScreen({super.key, required this.flashcardSet});

  @override
  State<AddFlashcardsScreen> createState() => _AddFlashcardsScreenState();
}

class _AddFlashcardsScreenState extends State<AddFlashcardsScreen> {
  final List<Map<String, String>> _newFlashcards = [];
  int _nextFlashcardNumber = 1;

  void _initializeNextFlashcardNumber() {
    setState(() {
      _nextFlashcardNumber = widget.flashcardSet['flashcards'].length + 1;
    });
  }

  int getNextFlashcardNumber() {
    return _nextFlashcardNumber++;
  }

  void _addNewFlashcard() {
    setState(() {
      _newFlashcards.add({
        'term': '',
        'definition': '',
        'number': getNextFlashcardNumber().toString()
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeNextFlashcardNumber();
  }

  void _saveNewFlashcards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedSets = prefs.getStringList('flashcard_sets') ?? [];

    int index = savedSets.indexWhere((set) =>
    jsonDecode(set)['title'] == widget.flashcardSet['title']);

    if (index != -1) {
      Map<String, dynamic> updatedSet = jsonDecode(savedSets[index]);

      updatedSet['flashcards'].addAll(_newFlashcards);

      savedSets[index] = jsonEncode(updatedSet);
      await prefs.setStringList('flashcard_sets', savedSets);

      setState(() {
        widget.flashcardSet['flashcards'].addAll(_newFlashcards);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New flashcards added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Flashcard set not found!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Flashcards",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _newFlashcards.length,
                itemBuilder: (context, index) {
                  return _buildFlashcardTile(index);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewFlashcard,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Add Flashcard",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saveNewFlashcards,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Save Flashcards",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardTile(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flashcard ${_newFlashcards[index]['number']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                )),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                _newFlashcards[index]['term'] = value;
              },
              decoration: InputDecoration(
                labelText: 'Enter term',
                border: const OutlineInputBorder(),
                labelStyle: const TextStyle(fontFamily: 'Poppins'),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                _newFlashcards[index]['definition'] = value;
              },
              decoration: InputDecoration(
                labelText: 'Enter definition',
                border: const OutlineInputBorder(),
                labelStyle: const TextStyle(fontFamily: 'Poppins'),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}