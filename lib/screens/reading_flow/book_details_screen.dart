// lib/screens/reading_flow/book_details_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:arca_app/constants.dart';
import 'package:arca_app/models/book.dart';
import 'package:arca_app/models/book_info.dart';
import 'package:arca_app/services/bible_service.dart';
import 'package:flutter/material.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book; // (Recebe o livro selecionado do book_picker_modal)
  
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  // (Instancia nosso novo service - Custo Zero)
  final BibleService _bibleService = BibleService();
  
  // (Armazena o resultado da API para o FutureBuilder)
  late Future<BookInfo> _bookInfoFuture;

  @override
  void initState() {
    super.initState();
    // (Inicia a chamada de API Custo Zero)
    _bookInfoFuture = _bibleService.fetchBookInfo(widget.book.abbrev);
  }

  @override
  Widget build(BuildContext context) {
    // (Controlador de Abas Nativo do Flutter - Custo Zero)
    return DefaultTabController(
      length: 2, // (Duas abas: Capítulos e Sobre)
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.book.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: "CAPÍTULOS"),
              Tab(text: "SOBRE O LIVRO"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Aba 1: Capítulos (Reaproveitamento do seu chapter_picker_page.dart) ---
            _buildChapterGrid(context),

            // --- Aba 2: Sobre o Livro (A nova Versão de Estudo) ---
            _buildStudyInfo(context),
          ],
        ),
      ),
    );
  }

  // (Esta é a lógica do seu 'chapter_picker_page.dart' - 100% Custo Zero)
  Widget _buildChapterGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.book.chapters,
        itemBuilder: (context, index) {
          final chapterNumber = index + 1;
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                // (Mantém a lógica V1.26: Retorna a seleção para bible_reader_screen)
                Navigator.of(context).pop({
                  'abbrev': widget.book.abbrev,
                  'chapter': chapterNumber
                });
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
    );
  }

  // (Este é o novo Widget que consome os dados do Supabase - Custo Zero)
  Widget _buildStudyInfo(BuildContext context) {
    return FutureBuilder<BookInfo>(
      future: _bookInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: arcaPurple));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("Erro ao carregar dados de estudo."));
        }

        final info = snapshot.data!;

        // (Renderiza os dados V3 que criamos no backend)
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildStudySection("Resumo", Text(info.summary ?? "N/A")),
            
            _buildStudySection("Ficha Técnica",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Autor:", info.author ?? "Desconhecido"),
                  _buildInfoRow("Data:", info.dateWritten ?? "Desconhecida"),
                  _buildInfoRow("Língua:", info.originalLanguage ?? "N/A"),
                ],
              )
            ),

            if (info.mainThemes.isNotEmpty)
              _buildStudySection("Temas Principais", 
                Wrap( // (Wrap é perfeito para tags - Custo Zero)
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: info.mainThemes.map((tema) => Chip(
                    label: Text(tema),
                    backgroundColor: arcaPurple.withOpacity(0.1),
                  )).toList(),
                )
              ),

            _buildStudySection("Contexto Histórico", Text(info.historicalContext ?? "N/A")),
            _buildStudySection("Curiosidades", Text(info.trivia ?? "N/A")),

            if (info.crossReferences.isNotEmpty)
              _buildStudySection("Referências Relacionadas", 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: info.crossReferences.map((ref) {
                    // (Aqui você pode adicionar a lógica de navegação)
                    return ListTile(
                      leading: const Icon(Icons.link, color: arcaPurple),
                      title: Text("${ref.book.toUpperCase()}: ${ref.desc}"),
                      onTap: () {
                      },
                    );
                  }).toList(),
                )
              ),
              
            const SizedBox(height: 40), // (Espaçador no final)
          ],
        );
      },
    );
  }

  // (Widget auxiliar para manter o design limpo - Custo Zero)
  Widget _buildStudySection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: arcaPurple,
            ),
          ),
          const Divider(color: arcaPurple),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
  
  // (Widget auxiliar para a Ficha Técnica)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ]
        ),
      ),
    );
  }
}