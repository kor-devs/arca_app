// lib/screens/tabs/bible_screen.dart (V1.51 - Corrigido para "items")
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../main.dart'; 
import '../../models/book.dart';
import '../../models/chapter_response.dart' as cr; // usa alias para evitar colisão com Book
import '../reading_flow/reading_screen.dart';
import '../reading_flow/chapter_screen.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  late Future<List<Book>> futureBooks;
  
  // (Estados V1.25 (Custo Zero) 100% MANTIDOS)
  bool _isLoadingLastRead = true;
  String? _lastReadAbbrev;
  int? _lastReadChapter;
  int? _lastReadVerseIndex;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks();
    _loadLastReadLocation();
  }

  Future<List<Book>> fetchBooks() async {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    final response = await http.get(Uri.parse("$apiUrl/books"));
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar livros');
    }
  }

  Future<void> _loadLastReadLocation() async {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReadAbbrev = prefs.getString('lastBookAbbrev');
      _lastReadChapter = prefs.getInt('lastChapter');
      _lastReadVerseIndex = prefs.getInt('lastVerseIndex');
      _isLoadingLastRead = false;
    });
  }

  Future<void> _navigateToLastRead() async {
    // (Lógica V1.25 (Custo Zero) MANTIDA)
    if (_lastReadAbbrev == null || _lastReadChapter == null || _lastReadVerseIndex == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Carregando $_lastReadAbbrev $_lastReadChapter...')),
    );
    try {
      final url = "$apiUrl/chapter/$_lastReadAbbrev/$_lastReadChapter";
      final response = await http.get(Uri.parse(url));
      
      if (!mounted) return;
      if (response.statusCode != 200) { throw Exception("Capítulo salvo não encontrado"); }
      
      // (Corretamente) Usa o Modelo V1.49.1 (Custo Zero)
      final chapterData = cr.ChapterResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      final startIndex = _lastReadVerseIndex!;

      // --- A CORREÇÃO (V1.51 - Usa '.items') ---
      final List<cr.VerseItem> verses = chapterData.items
          .whereType<cr.VerseItem>() 
          .toList();
      // --- FIM DA CORREÇÃO ---

      if (startIndex < 0 || startIndex >= verses.length) { // (Usa (corretamente) 'verses.length' (V1.51) (Custo Zero))
        throw Exception('Versículo salvo não encontrado no capítulo');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReadingScreen(
            chapterData: chapterData,
            startIndex: startIndex,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar capítulo: $e')),
      );
    }
  }

  Widget _buildContinueReadingCard() {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    if (_isLoadingLastRead || _lastReadAbbrev == null) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor.withAlpha(240), 
      child: InkWell(
        onTap: _navigateToLastRead,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CONTINUAR LEITURA",
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${_lastReadAbbrev!.toUpperCase()} $_lastReadChapter:${_lastReadVerseIndex! + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContinueReadingCard(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text(
              "Livros",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Book>>(
              future: futureBooks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LinearProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar livros: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final books = snapshot.data!;
                  return ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return ListTile(
                        title: Text(book.name),
                        subtitle: Text('Abreviação: ${book.abbrev} (${book.chapters} capítulos)'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChapterScreen(book: book),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('Nenhum dado encontrado.'));
                }
              },
            ),
          ),
        ],
      );
  }
}