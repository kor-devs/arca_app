// lib/screens/main_screen.dart (V1.32 - Estado Público)
import 'package:arca_app/constants.dart';
import 'package:flutter/material.dart';

import 'tabs/today_screen.dart';
import 'tabs/bible_reader_screen.dart'; 
import 'tabs/favorites_screen.dart';
import 'tabs/notes_screen.dart'; // (V1.31)
import 'tabs/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // Método estático agora disponível como MainScreen.showBookPickerModal(...)
  static void showBookPickerModal(BuildContext context, String currentAbbrev, int currentChapter, void Function(String, int) onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecione o livro e capítulo (não implementado)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Manter: $currentAbbrev $currentChapter'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelected(currentAbbrev, currentChapter);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  // --- A CORREÇÃO (Bug `_MainScreenState`) ---
  // (Corretamente) torna o 'State' (V1.32) PÚBLICO
  // (removendo o '_') para (corretamente)
  // ser acessado pelo 'verse_of_the_day_card.dart' (V1.32))
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
// --- FIM DA CORREÇÃO ---

  int _selectedIndex = 0;

  final GlobalKey<FavoritesScreenState> _favoritesKey = GlobalKey<FavoritesScreenState>();
  final GlobalKey<BibleReaderScreenState> _bibleReaderKey = GlobalKey<BibleReaderScreenState>();
  final GlobalKey<NotesScreenState> _notesKey = GlobalKey<NotesScreenState>();
  
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // (A Lógica V1.31 (Custo Zero)
    // (corretamente) MANTIDA)
    _widgetOptions = <Widget>[
      const TodayScreen(),
      BibleReaderScreen(key: _bibleReaderKey), 
      FavoritesScreen(
        key: _favoritesKey,
        onJumpToBible: jumpToBible, // (Renomeado V1.32)
      ),
      NotesScreen(
        key: _notesKey,
        onJumpToBible: jumpToBible, // (Renomeado V1.32)
      ),
      const ProfileScreen(),
    ];
  }

  // (Lógica V1.31 (Custo Zero)
  // (corretamente) MANTIDA e (corretamente) Renomeada para V1.32)
  void jumpToBible(String abbrev, int chapter, int verseNumber) {
    // verseNumber is 1-based (e.g. 1 for first verse). BibleReader will
    // resolve it to the correct item index (skipping titles/subtitles).
    _bibleReaderKey.currentState?.loadChapter(abbrev, chapter, verseNumber);
    setState(() {
      _selectedIndex = 1; 
    });
  }

  void _onItemTapped(int index) {
    // (Lógica V1.31 (Custo Zero)
    // (corretamente) MANTIDA)
    if (index == 1) {
      _bibleReaderKey.currentState?.refreshContent();
    } else if (index == 2) { 
      _favoritesKey.currentState?.refreshFavorites();
    } else if (index == 3) {
      _notesKey.currentState?.refreshNotes();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // --- CORREÇÃO NAVBAR IPHONE WEB ---
      bottomNavigationBar: Container(
        // Define a cor de fundo do container para cobrir a área preta/branca do iPhone
        color: Colors.white, 
        child: SafeArea(
          // 'top: false' garante que o SafeArea não empurre nada pra baixo vindo do topo
          top: false, 
          child: Padding(
            // Adiciona 8 pixels extras para afastar da barra de sair
            padding: const EdgeInsets.only(bottom: 8.0), 
            child: BottomNavigationBar(
              // Remove a elevação interna para não ficar com sombra duplicada se tiver container
              elevation: 0, 
              backgroundColor: Colors.white, // Garante fundo branco
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home, color: arcaOrange),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_outlined),
                  activeIcon: Icon(Icons.auto_stories, color: arcaOrange),
                  label: 'Bíblia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_outline),
                  activeIcon: Icon(Icons.bookmark, color: arcaOrange),
                  label: 'Favoritos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note_outlined),
                  activeIcon: Icon(Icons.edit_note, color: arcaOrange),
                  label: 'Notas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dehaze_rounded),
                  activeIcon: Icon(Icons.dehaze_sharp, color: arcaOrange),
                  label: 'Opções',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
      // --- FIM DA CORREÇÃO ---
    );
  }

  void navigateToNotesTab({required String bookAbbrev, required int chapter, required int verseNumber, required String verseText, required String bookName}) {
    // Atualiza a lista de notas e muda para a aba Notas
    _notesKey.currentState?.refreshNotes();
    setState(() {
      _selectedIndex = 3;
    });
  }

  void refreshContent() {
    _notesKey.currentState?.refreshNotes();
  }

  void refreshBibleTab() {
    _bibleReaderKey.currentState?.refreshContent();
  }
}