// lib/models/devotional_model.dart
class Devotional {
  final int id;
  final int dayOfYear;
  final String title;
  final String theme;
  final String imageUrl;
  final String duration;
  final String author;
  final String verseReference;
  
  // [NOVOS CAMPOS DE TEXTO]
  final String verseText;
  final String theologyContent;
  final String reflectionContent;

  // [NOVOS CAMPOS DE NAVEGAÇÃO]
  final String bookAbbrev;
  final int chapter;
  final int verseNumber;

  Devotional({
    required this.id,
    required this.dayOfYear,
    required this.title,
    required this.theme,
    required this.imageUrl,
    required this.duration,
    required this.author,
    required this.verseReference,
    required this.verseText,
    required this.theologyContent,
    required this.reflectionContent,
    required this.bookAbbrev,
    required this.chapter,
    required this.verseNumber,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'],
      dayOfYear: json['day_of_year'],
      title: json['title'],
      theme: json['theme'] ?? 'Espiritualidade',
      imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1507434965515-61970f2bd7c6',
      duration: json['estimated_read_time'] ?? '5 min',
      author: json['author'] ?? 'Equipe Arca',
      verseReference: json['verse_reference'] ?? '',
      
      verseText: json['verse_text'] ?? '',
      theologyContent: json['theology_content'] ?? '',
      reflectionContent: json['reflection_content'] ?? '',

      // [MAPEAMENTO DO BANCO]
      bookAbbrev: json['book_abbrev'] ?? 'gn', // Fallback para Genesis se nulo
      chapter: json['chapter'] ?? 1,
      verseNumber: json['verse_number'] ?? 1,
    );
  }
}