// lib/screens/reading_flow/reading_screen.dart (V1.51 - Corrigido para "items")
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../models/chapter_response.dart'; // (Corretamente) Usa o V1.49.1 (Custo Zero)
import '../../constants.dart';
import '../../main.dart';
// (O 'import ../../models/verse.dart' (V1.25)
// (V1.26) (Custo Zero) (corretamente) FOI REMOVIDO (V1.51) (Custo Zero))

class ReadingScreen extends StatefulWidget { 
  final ChapterResponse chapterData; 
  final int startIndex;

  const ReadingScreen({
    super.key, 
    required this.chapterData, 
    required this.startIndex,
  });

  @override
  ReadingScreenState createState() => ReadingScreenState();
}
class ReadingScreenState extends State<ReadingScreen> { 
  // (Estados V1.25 (Custo Zero) 100% MANTIDOS)
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _lastVisibleIndex = 0; 
  final Color _highlightColor = arcaNeonGreen; 
  bool _isLoadingFavorites = true;
  final Set<int> _favoriteVerseNumbers = {}; 

  // --- A CORREÇÃO (V1.51 - Lista Filtrada) ---
  // (Filtra (corretamente) 'items' (V1.49) (Custo Zero)
  // (corretamente) *uma vez* (V1.51) (Custo Zero)
  // (Agilidade Máxima))
  late final List<VerseItem> _versesOnlyList;
  // --- FIM DA CORREÇÃO ---

  @override
  void initState() {
    super.initState();
    
    // --- A CORREÇÃO (V1.51 - Filtra os Itens) ---
    _versesOnlyList = widget.chapterData.items
        .whereType<VerseItem>()
        .toList();
    // --- FIM DA CORREÇÃO ---

    _loadFavoritesForThisChapter();
    _lastVisibleIndex = widget.startIndex;
    _itemPositionsListener.itemPositions.addListener(_onScrollChanged);
  }
  
  @override
  void dispose() {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    _itemPositionsListener.itemPositions.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onScrollChanged() {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      _lastVisibleIndex = positions.first.index;
    }
  }

  Future<void> _saveLastReadLocation() async {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastBookAbbrev', widget.chapterData.bookAbbrev);
    await prefs.setInt('lastChapter', widget.chapterData.chapterNumber);
    await prefs.setInt('lastVerseIndex', _lastVisibleIndex);
  }

  Future<void> _loadFavoritesForThisChapter() async {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    try {
      final response = await supabase
          .from('favorite_verses')
          .select('verse_number')
          .eq('profile_id', supabase.auth.currentUser!.id)
          .eq('book_name', widget.chapterData.bookName)
          .eq('chapter', widget.chapterData.chapterNumber);

      if (response.isNotEmpty) {
        final favorites = response
            .map<int>((item) => item['verse_number'] as int)
            .toSet();
        _favoriteVerseNumbers.addAll(favorites);
      }
    } catch (e) {
      // Ignora erro
    }
    setState(() { 
      _isLoadingFavorites = false; 
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { 
        _itemScrollController.scrollTo(
          index: widget.startIndex,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  // --- A CORREÇÃO (V1.51 - Usa 'VerseItem') ---
  // (Corretamente) muda o tipo (V1.51) (Custo Zero) de 'Verse' (V1.26)
  // (V1.25) (Custo Zero)
  // para 'VerseItem' (V1.49) (Custo Zero))
  Future<void> _toggleFavorite(VerseItem verse) async {
    final verseNumber = verse.number;
    final isFavorite = _favoriteVerseNumbers.contains(verseNumber);
    try {
      if (isFavorite) {
        setState(() {
          _favoriteVerseNumbers.remove(verseNumber);
        });
        await supabase
            .from('favorite_verses')
            .delete()
            .eq('profile_id', supabase.auth.currentUser!.id)
            .eq('book_name', widget.chapterData.bookName)
            .eq('chapter', widget.chapterData.chapterNumber)
            .eq('verse_number', verseNumber);
      } else {
        setState(() {
          _favoriteVerseNumbers.add(verseNumber);
        });
        await supabase.from('favorite_verses').insert({
          'profile_id': supabase.auth.currentUser!.id,
          'book_name': widget.chapterData.bookName,
          'chapter': widget.chapterData.chapterNumber,
          'verse_number': verseNumber,
          'verse_text': verse.text,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar favorito: $e')),
      );
    }
  }
  // --- FIM DA CORREÇÃO ---
  
  @override
  Widget build(BuildContext context) {
    // (Lógica V1.25 (Custo Zero) 100% MANTIDA)
    return WillPopScope(
      onWillPop: () async {
        await _saveLastReadLocation();
        return true; 
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.chapterData.bookName} ${widget.chapterData.chapterNumber}"),
          leading: BackButton(
            onPressed: () async {
              await _saveLastReadLocation();
              Navigator.of(context).pop();
            },
          ),
        ),
        
        body: _isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener, 
          padding: const EdgeInsets.all(16.0),
          
          // --- A CORREÇÃO (V1.51 - Usa '.length' (V1.51) (Custo Zero) da Lista Filtrada) ---
          itemCount: _versesOnlyList.length, 
          itemBuilder: (context, index) {
            final verse = _versesOnlyList[index]; // (Usa (corretamente) a Lista Filtrada (V1.51))
            // --- FIM DA CORREÇÃO ---
            
            final bool isFavorite = _favoriteVerseNumbers.contains(verse.number);

            return InkWell(
              onLongPress: () {
                _toggleFavorite(verse);
              },
              child: Container(
                color: isFavorite ? _highlightColor : Colors.transparent, 
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18),
                    children: [
                      TextSpan(
                        text: "${verse.number} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: verse.text),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}