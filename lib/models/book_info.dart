// Classe auxiliar para o JSONB de cross_references
class CrossRef {
  final String book;
  final String desc;

  CrossRef({required this.book, required this.desc});

  factory CrossRef.fromJson(Map<String, dynamic> json) {
    return CrossRef(
      book: json['book'] ?? '',
      desc: json['desc'] ?? '',
    );
  }
}

// O Model principal da tabela 'book_info'
class BookInfo {
  final String bookAbbrev;
  final String bookName;
  final String? summary;
  final String? author;
  final String? dateWritten;
  final String? originalLanguage;
  final String? historicalContext;
  final List<String> mainThemes; // (Vem do TEXT[])
  final String? trivia;
  final List<CrossRef> crossReferences; // (Vem do JSONB)

  BookInfo({
    required this.bookAbbrev,
    required this.bookName,
    this.summary,
    this.author,
    this.dateWritten,
    this.originalLanguage,
    this.historicalContext,
    required this.mainThemes,
    this.trivia,
    required this.crossReferences,
  });

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    // Converte a lista de temas (TEXT[])
    final themesList = (json['main_themes'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    // Converte a lista de referências (JSONB)
    final refsList = (json['cross_references'] as List<dynamic>?)
        ?.map((e) => CrossRef.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return BookInfo(
      bookAbbrev: json['book_abbrev'],
      bookName: json['book_name'],
      summary: json['summary'],
      author: json['author'],
      dateWritten: json['date_written'],
      originalLanguage: json['original_language'],
      historicalContext: json['historical_context'],
      mainThemes: themesList,
      trivia: json['trivia'],
      crossReferences: refsList,
    );
  }
}