// lib/screens/reading_flow/verse_selection_screen.dart (V1.50 - Corrigido para "items")
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../../models/chapter_response.dart'; // (Corretamente) Usa o V1.49.1 (Custo Zero)
import '../tabs/bible_reader_screen.dart'; 

class VerseSelectionScreen extends StatefulWidget {
  final String bookAbbrev;
  final int chapterNumber;
  final bool returnResult;

  const VerseSelectionScreen({
    super.key, 
    required this.bookAbbrev, 
    required this.chapterNumber,
    this.returnResult = false
  });

  @override
  _VerseSelectionScreenState createState() => _VerseSelectionScreenState();
}

class _VerseSelectionScreenState extends State<VerseSelectionScreen> {
  late Future<ChapterResponse> _chapterDataFuture;

  @override
  void initState() {
    super.initState();
    _chapterDataFuture = _fetchChapterData();
  }

  Future<ChapterResponse> _fetchChapterData() async {
    try {
      final url = "$apiUrl/chapter/${widget.bookAbbrev}/${widget.chapterNumber}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return ChapterResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception("Capítulo não encontrado (Erro ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Erro ao carregar dados: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecione o Versículo"),
      ),
      body: FutureBuilder<ChapterResponse>(
        future: _chapterDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Nenhum dado encontrado."));
          }

          final chapterData = snapshot.data!;
          
          // --- A CORREÇÃO (V1.50 - Usa '.items') ---
          // (Filtra (corretamente) a lista 'items' (V1.48) (Custo Zero)
          // para (corretamente) pegar *apenas*
          // os 'VerseItem' (V1.49) (Custo Zero))
          final List<VerseItem> verses = chapterData.items
              .whereType<VerseItem>() 
              .toList();
          // --- FIM DA CORREÇÃO ---

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            // (Corretamente) usa a lista 'verses' (V1.50) (Custo Zero) filtrada)
            itemCount: verses.length, 
            itemBuilder: (context, index) {
              final verse = verses[index];
              return ElevatedButton(
                child: Text("${verse.number}"),
                onPressed: () {
                  if (widget.returnResult) {
                    Navigator.of(context).pop(verse.number); 
                  } else {
                    // FLUXO LEGADO:
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BibleReaderScreen(
                          initialBook: chapterData.bookAbbrev,
                          initialChapter: chapterData.chapterNumber,
                          initialVerseIndex: verse.number, // <--- SEM O -1 (Fix do Scroll)
                        ),
                      ),
                      (Route<dynamic> route) => route.isFirst,
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}