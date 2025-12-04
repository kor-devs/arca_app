class Devotional {
  final int id;
  final int dayOfYear;
  final String title;
  final String theme;
  final String imageUrl;
  final String duration;
  final String author;
  final String verseReference;

  Devotional({
    required this.id,
    required this.dayOfYear,
    required this.title,
    required this.theme,
    required this.imageUrl,
    required this.duration,
    required this.author,
    required this.verseReference,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'],
      dayOfYear: json['day_of_year'],
      title: json['title'],
      // Fallback seguro caso algum campo venha nulo
      theme: json['theme'] ?? 'Espiritualidade',
      imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1507434965515-61970f2bd7c6',
      duration: json['estimated_read_time'] ?? '5 min',
      author: json['author'] ?? 'Equipe Arca',
      verseReference: json['verse_reference'] ?? '',
    );
  }
}