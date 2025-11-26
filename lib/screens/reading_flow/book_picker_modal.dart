// lib/screens/reading_flow/book_picker_modal.dart (V1.26 - O Pop-up)
// ignore_for_file: library_private_types_in_public_api

import 'package:arca_app/screens/reading_flow/chapter_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../../models/book.dart';


class BookPickerModal extends StatefulWidget {
  const BookPickerModal({super.key});

  @override
  _BookPickerModalState createState() => _BookPickerModalState();
}

class _BookPickerModalState extends State<BookPickerModal> {
  // (Copia a lógica Custo Zero do V1.25)
  late Future<List<Book>> futureBooks;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks();
  }

  Future<List<Book>> fetchBooks() async {
    final response = await http.get(Uri.parse("$apiUrl/books"));
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar livros');
    }
  }

  // (Lógica (V1.25)
  // para navegar para a seleção de capítulo)
  void _onBookTapped(Book book) async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterPickerPage(book: book),
      ),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Pega 90% da altura da tela (Custo Zero))
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Selecione o Livro"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
        body: FutureBuilder<List<Book>>(
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
                    subtitle: Text('${book.chapters} capítulos'),
                    onTap: () {
                      _onBookTapped(book); // (Navega para a Ação 8)
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
    );
  }
}