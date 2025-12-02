// lib/screens/main_screen.dart (V4.1 - Suporte a Plano de Leitura)
import 'package:arca_app/constants.dart';
import 'package:flutter/material.dart';

import 'tabs/today_screen.dart';
import 'tabs/bible_reader_screen.dart'; 
import 'tabs/profile_screen.dart';
import 'tabs/reading_club_screen.dart';
import 'tabs/notes_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void showBookPickerModal(BuildContext context, String currentAbbrev, int currentChapter, void Function(String, int) onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecione o livro e capítulo', style: Theme.of(context).textTheme.titleMedium),
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
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {

  int _selectedIndex = 0;
  final GlobalKey<BibleReaderScreenState> _bibleReaderKey = GlobalKey<BibleReaderScreenState>();
  
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Navbar com 4 itens (Início, Bíblia, Clube, Opções)
    _widgetOptions = <Widget>[
      const TodayScreen(),
      BibleReaderScreen(key: _bibleReaderKey), 
      const ReadingClubScreen(),
      const ProfileScreen(),
    ];
  }

  // [MODIFICADO] Aceita planId e dayNumber opcionais para o Clube de Leitura
  void jumpToBible(String abbrev, int chapter, int verseNumber, [int? planId, int? dayNumber]) {
    // Passa os dados do plano para o leitor
    _bibleReaderKey.currentState?.loadChapter(abbrev, chapter, verseNumber, planId, dayNumber);
    
    setState(() {
      _selectedIndex = 1; // Vai para a aba do meio (Bíblia)
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _bibleReaderKey.currentState?.exitPlanMode();
      refreshBibleTab();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void refreshBibleTab() {
    _bibleReaderKey.currentState?.refreshContent();
  }

  void refreshContent() {
    refreshBibleTab();
  }

  void navigateToNotesTab({
    required String bookAbbrev, 
    required int chapter, 
    required int verseNumber, 
    required String verseText, 
    required String bookName
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesScreen(
          onJumpToBible: (abbrev, ch, verse) {
            Navigator.pop(context); 
            jumpToBible(abbrev, ch, verse); 
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        color: Colors.white, 
        child: SafeArea(
          top: false, 
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), 
            child: BottomNavigationBar(
              elevation: 0, 
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  activeIcon: Icon(Icons.home, color: arcaOrange),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_outlined),
                  activeIcon: Icon(Icons.auto_stories, color: arcaOrange),
                  label: 'Bíblia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined), // Ícone de Mapa/Jornada
                  activeIcon: Icon(Icons.explore, color: arcaOrange),
                  label: 'Jornadas', // Nome novo
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
    );
  }
}