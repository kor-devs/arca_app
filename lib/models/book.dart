// lib/models/book.dart
class Book { 
  final String name;
  final String abbrev;
  final int chapters;

  Book({required this.name, required this.abbrev, required this.chapters});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      name: json['name'],
      abbrev: json['abbrev']['pt'], 
      chapters: json['chapters'],
    );
  }
}