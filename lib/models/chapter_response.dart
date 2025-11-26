// lib/models/chapter_response.dart (V1.49.1 - Import Corrigido)

// (O 'import 'verse.dart';' (V1.49)
// (V1.49) (Custo Zero)
// (corretamente) FOI REMOVIDO (V1.50) (Custo Zero))

abstract class ChapterItem {
  final String type;
  ChapterItem(this.type);
}

class TitleItem extends ChapterItem {
  final String text;
  TitleItem({required this.text}) : super('title');

  factory TitleItem.fromJson(Map<String, dynamic> json) {
    return TitleItem(
      text: json['text'],
    );
  }
}

class VerseItem extends ChapterItem {
  final int number;
  final String text;
  
  VerseItem({required this.number, required this.text}) : super('verse');

  factory VerseItem.fromJson(Map<String, dynamic> json) {
    return VerseItem(
      number: json['number'],
      text: json['text'],
    );
  }

  Verse toVerse() => Verse(verseNumber: number, text: text);
}

// Adiciona Book e Verse para compatibilidade com a UI
class Book {
  final String name;
  final int chapterCount;

  Book({required this.name, required this.chapterCount});

  factory Book.fromJson(Map<String, dynamic> json) {
    // Tenta várias chaves possíveis para compatibilidade
    final name = json['name'] ?? json['bookName'] ?? json['book_name'] ?? '';
    final chapterCount = json['chapterCount'] ?? json['chapter_count'] ?? json['chapters'] ?? 0;
    return Book(name: name, chapterCount: chapterCount is int ? chapterCount : int.tryParse('$chapterCount') ?? 0);
  }
}

class Verse {
  final int verseNumber; // 1-based
  final String text;

  Verse({required this.verseNumber, required this.text});
}

class ChapterResponse {
  final String bookName;
  final String bookAbbrev;
  final int chapterNumber;
  final List<ChapterItem> items; // (V1.49) (Custo Zero)

  // Novas propriedades compatíveis com o código da UI
  final Book book;
  final List<Verse> verses;

  ChapterResponse({
    required this.bookName,
    required this.bookAbbrev,
    required this.chapterNumber,
    required this.items,
    required this.book,
    required this.verses,
  });

  factory ChapterResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = <ChapterItem>[];
    if (json['items'] != null) {
      for (var item in json['items']) {
        if (item['type'] == 'title') {
          itemsList.add(TitleItem.fromJson(item));
        } else if (item['type'] == 'verse') {
          itemsList.add(VerseItem.fromJson(item));
        }
      }
    }

    // Tenta extrair info do objeto 'book' quando disponível
    Book parsedBook;
    if (json['book'] != null && json['book'] is Map<String, dynamic>) {
      parsedBook = Book.fromJson(json['book'] as Map<String, dynamic>);
    } else {
      parsedBook = Book.fromJson({
        'name': json['bookName'] ?? json['book_name'] ?? '',
        'chapterCount': json['chapterCount'] ?? json['chapter_count'] ?? 0,
      });
    }
    
    // Converte items para verses (filtra apenas VerseItem)
    final verseList = itemsList.whereType<VerseItem>().map((vi) => vi.toVerse()).toList();

    return ChapterResponse(
      bookName: json['bookName'] ?? json['book_name'] ?? parsedBook.name,
      bookAbbrev: json['bookAbbrev'] ?? json['book_abbrev'] ?? '',
      chapterNumber: json['chapterNumber'] ?? json['chapter_number'] ?? 0,
      items: itemsList,
      book: parsedBook,
      verses: verseList,
    );
  }
}