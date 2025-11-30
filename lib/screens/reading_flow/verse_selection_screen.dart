// lib/screens/reading_flow/verse_selection_screen.dart (V2.0 - Fix URL da API)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Import necessário
import '../../main.dart';
import '../../models/chapter_response.dart'; 
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
  // Variável para guardar a versão (padrão nvi)
  String _currentVersion = 'nvi';

  @override
  void initState() {
    super.initState();
    // Inicia o processo: 1. Ler Versão -> 2. Buscar Dados
    _chapterDataFuture = _loadVersionAndFetchData();
  }

  Future<ChapterResponse> _loadVersionAndFetchData() async {
    try {
      // 1. Ler a versão preferida do usuário
      final prefs = await SharedPreferences.getInstance();
      _currentVersion = prefs.getString('bible_version') ?? 'nvi';

      // 2. Montar a URL correta com a versão
      // [CORREÇÃO]: Agora inclui a versão na rota (ex: /api/nvi/gn/1)
      final url = "$apiUrl/$_currentVersion/${widget.bookAbbrev}/${widget.chapterNumber}";
      
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
          
          final List<VerseItem> verses = chapterData.items
              .whereType<VerseItem>() 
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
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
                          initialVerseIndex: verse.number, 
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