// lib/screens/reading_flow/chapter_screen.dart
import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'verse_selection_screen.dart';

class ChapterScreen extends StatelessWidget { 
  final Book book;
  const ChapterScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${book.name} - Selecione o Capítulo")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, childAspectRatio: 1.0, crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: book.chapters,
          itemBuilder: (context, index) {
            final chapterNumber = index + 1;
            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerseSelectionScreen(
                        bookAbbrev: book.abbrev,
                        chapterNumber: chapterNumber,
                      ),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    '$chapterNumber',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}