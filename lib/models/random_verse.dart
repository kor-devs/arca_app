// lib/models/random_verse.dart
class RandomVerse {
  final String text;
  final String reference;
  final String bookAbbrev;
  final int chapter;
  final int number;

  RandomVerse({
    required this.text, 
    required this.reference,
    required this.bookAbbrev,
    required this.chapter,
    required this.number,
  });

  factory RandomVerse.fromJson(Map<String, dynamic> json) {
    return RandomVerse(
      text: json['text'],
      reference: "${json['book']['name']} ${json['chapter']}:${json['number']}",
      bookAbbrev: json['book']['abbrev']['pt'],
      chapter: json['chapter'],
      number: json['number'],
    );
  }
}