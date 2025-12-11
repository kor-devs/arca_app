// lib/models/random_verse.dart
class RandomVerse {
  final int id;
  final String bookAbbrev;
  final String bookName;
  final int chapter;
  final int number;
  final String text;
  final String reference;
  final List<String> tags;
  final String imageUrl;

  RandomVerse({
    required this.id,
    required this.bookAbbrev,
    required this.bookName,
    required this.chapter,
    required this.number,
    required this.text,
    required this.reference,
    required this.tags,
    required this.imageUrl,
  });

  factory RandomVerse.fromJson(Map<String, dynamic> json) {
    // --- 1. Lógica de Extração Inteligente (Híbrida) ---
    String extractedAbbrev = '';
    String extractedName = '';
    int extractedNumber = 1;

    // CASO A: Formato Supabase (Tabela 'curated_verses')
    // As colunas são planas: book_abbrev, book_name, verse_number
    if (json.containsKey('book_abbrev')) {
      extractedAbbrev = json['book_abbrev'] ?? '';
      extractedName = json['book_name'] ?? '';
      extractedNumber = json['verse_number'] ?? 1;
    } 
    // CASO B: Formato API Externa (Bible API)
    // A estrutura é aninhada: book: { abbrev: { pt: 'gn' }, name: 'Gênesis' }
    else if (json.containsKey('book') && json['book'] is Map) {
      final bookMap = json['book'];
      extractedName = bookMap['name'] ?? '';
      
      // Tenta pegar a abreviação em PT, senão pega a genérica
      if (bookMap['abbrev'] is Map && bookMap['abbrev'].containsKey('pt')) {
        extractedAbbrev = bookMap['abbrev']['pt'];
      } else {
        extractedAbbrev = bookMap['abbrev'] ?? '';
      }
      
      extractedNumber = json['number'] ?? 1; // API costuma usar 'number'
    }

    // --- 2. Garantia de Imagem ---
    String img = json['image_url'] ?? 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1000';

    return RandomVerse(
      id: json['id'] ?? 0,
      bookAbbrev: extractedAbbrev, // Agora sempre terá valor correto
      bookName: extractedName,
      chapter: json['chapter'] ?? 1,
      number: extractedNumber,
      text: json['text'] ?? '',
      reference: json['reference'] ?? '$extractedName ${json['chapter']}:$extractedNumber',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: img,
    );
  }
}