import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, String>> notes = [];
  double _textSize = 16.0;
  FlutterTts flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isHighContrast = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotes();
    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNotes = prefs.getStringList('notes') ?? [];

    print('Loaded Notes: $savedNotes');

    setState(() {
      notes = savedNotes
          .map((note) => Map<String, String>.from(json.decode(note)))
          .toList();
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNotes = prefs.getStringList('notes') ?? [];

    savedNotes = notes.map((note) => json.encode(note)).toList();

    print('Saving Notes: $savedNotes');

    await prefs.setStringList('notes', savedNotes);
  }

  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String? content;

      try {
        if (fileName.endsWith('.txt')) {
          content = await file.readAsString();
        } else if (fileName.endsWith('.pdf')) {
          content = await _extractTextFromPDF(file);
        } else if (fileName.endsWith('.docx')) {
          content = await _extractTextFromDocx(file);
        } else {
          content = "Unsupported file format.";
        }
      } catch (e) {
        content = "Error reading file: $e";
      }

      _addNote(
        title: fileName,
        content: content,
        date: DateTime.now().toLocal().toString().split(' ')[0],
        tags: 'General',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document uploaded: $fileName')),
      );
    }
  }

  Future<String> _extractTextFromDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final documentXml = archive.firstWhere(
            (element) => element.name == 'word/document.xml',
        orElse: () => ArchiveFile('word/document.xml', 0, []),
      );

      if (documentXml.content.isEmpty) {
        return "No document found in the DOCX file.";
      }

      final documentXmlString = utf8.decode(documentXml.content as List<int>);
      final documentXmlElement = XmlDocument.parse(documentXmlString);

      final textElements = documentXmlElement.findAllElements('w:t');
      final text = textElements.map((e) => e.text).join(" ");

      return text;
    } catch (e) {
      return "Error reading DOCX file: $e";
    }
  }

  Future<String> _extractTextFromPDF(File file) async {
    // PDF Extract Logic Here
    return "PDF content extraction not implemented yet.";
  }

  void _addNote({
    required String title,
    required String content,
    required String date,
    required String tags,
  }) {
    setState(() {
      notes.add({
        'title': title,
        'content': content,
        'date': date,
        'tags': tags,
      });
    });
    _saveNotes();
  }

  void _toggleListen(String content) async {
    if (_isListening) {
      await flutterTts.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
    });

    final chunks = _splitTextIntoChunks(content);

    for (var chunk in chunks) {
      if (!_isListening) break;
      await flutterTts.speak(chunk);
      await flutterTts.awaitSpeakCompletion(true);
    }

    setState(() {
      _isListening = false;
    });
  }

  List<String> _splitTextIntoChunks(String text) {
    final maxLength = 1000;
    List<String> chunks = [];

    for (int i = 0; i < text.length; i += maxLength) {
      chunks.add(text.substring(
          i, i + maxLength > text.length ? text.length : i + maxLength));
    }

    return chunks;
  }

  void _editNoteDialog(int index) {
    TextEditingController contentController =
    TextEditingController(text: notes[index]['content']);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Edit Note'),
            content: TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Edit your note here...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    notes[index]['content'] = contentController.text;
                  });
                  _saveNotes();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _deleteNoteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Note'),
            content: const Text('Are you sure you want to delete this note?'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    notes.removeAt(index);
                  });
                  _saveNotes();
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _toggleHighContrast() {
    setState(() {
      _isHighContrast = !_isHighContrast;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isHighContrast
        ? ThemeData.dark().copyWith(primaryColor: Colors.yellow)
        : ThemeData.light();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Study Guides"),
          backgroundColor: Colors.teal[300],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: _toggleHighContrast,
              tooltip: "Toggle High Contrast",
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                "Generated Notes:",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              notes.isEmpty
                  ? const Text(
                "No notes available. Upload a document to begin.",
                style: TextStyle(fontSize: 13),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                itemBuilder: (context, index) =>
                    _buildNoteCard(index, context),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _uploadDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Document"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[300],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text("Adjust Text Size:"),
                    Slider(
                      min: 10,
                      max: 30,
                      value: _textSize,
                      onChanged: (value) {
                        setState(() {
                          _textSize = value;
                        });
                      },
                      label: "${_textSize.toInt()}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(int index, BuildContext context) {
    final note = notes[index];
    String content = note['content']!;

    List<String> paragraphs = _splitContentIntoParagraphs(content);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['title']!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Date: ${note['date']}", style: TextStyle(fontSize: 14)),
            Text("Tags: ${note['tags']}", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            for (var paragraph in paragraphs)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: paragraph,
                      style: TextStyle(fontSize: _textSize),
                    ),
                  ],
                ),
                textAlign: TextAlign.justify,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _editNoteDialog(index),
                  child: const Text("Edit"),
                ),
                ElevatedButton(
                  onPressed: () => _toggleListen(note['content']!),
                  child: Text(_isListening ? "Stop" : "Listen"),
                ),
                ElevatedButton(
                  onPressed: () => _deleteNoteDialog(index),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _splitContentIntoParagraphs(String content) {
    List<String> paragraphs = [];
    StringBuffer currentParagraph = StringBuffer();

    List<String> lines = content.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) {
        if (currentParagraph.isNotEmpty) {
          paragraphs.add(currentParagraph.toString().trim());
          currentParagraph.clear();
        }
      } else {
        currentParagraph.writeln(line);
      }
    }

    if (currentParagraph.isNotEmpty) {
      paragraphs.add(currentParagraph.toString().trim());
    }

    return paragraphs;
  }
}
