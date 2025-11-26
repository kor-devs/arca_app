// lib/screens/reading_flow/chapter_picker_page.dart (V1.26)
import 'package:flutter/material.dart';
import '../../models/book.dart';

class ChapterPickerPage extends StatelessWidget { 
  final Book book;
  const ChapterPickerPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${book.name} - Selecione o Capítulo")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(builder: (context, constraints) {
          // Desired approximate tile width (including spacing). Adjust to taste.
          const double desiredTileWidth = 72.0;
          final double availableWidth = constraints.maxWidth;
          int crossAxisCount = (availableWidth / desiredTileWidth).floor();
          crossAxisCount = crossAxisCount.clamp(3, 8);
          const double spacing = 8.0;
          // childAspectRatio keeps tiles roughly square; reduce if you want shorter tiles
          const double childAspectRatio = 1.0;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: book.chapters,
            itemBuilder: (context, index) {
              final chapterNumber = index + 1;
              // Compute a font size proportional to tile width but clamped
              final double tileWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
              final double fontSize = (tileWidth * 0.28).clamp(12.0, 18.0);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).pop({
                      'abbrev': book.abbrev,
                      'chapter': chapterNumber
                    });
                  },
                  child: Center(
                    child: Text(
                      '$chapterNumber',
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}