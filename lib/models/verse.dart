// lib/models/verse.dart
class Verse { 
  final int number;
  final String text;

  Verse({required this.number, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['number'],
      text: json['text'],
    );
  }
}