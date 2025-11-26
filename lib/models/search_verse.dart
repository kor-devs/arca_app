// lib/models/search_verse.dart
class SearchVerse {
  final String bookName;
  final String bookAbbrev;
  final int chapter;
  final int number;
  final String text;

  SearchVerse({
    required this.bookName,
    required this.bookAbbrev,
    required this.chapter,
    required this.number,
    required this.text,
  });

  factory SearchVerse.fromJson(Map<String, dynamic> json) {
    return SearchVerse(
      bookName: json['book']['name'],
      bookAbbrev: json['book']['abbrev']['pt'],
      chapter: json['chapter'],
      number: json['number'],
      text: json['text'],
    );
  }
}