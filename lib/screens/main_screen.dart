// lib/screens/main_screen.dart (V5.2 - Com Controle de Refresh da Jornada)
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
  
  // Chaves Globais para controlar as abas
  final GlobalKey<BibleReaderScreenState> _bibleReaderKey = GlobalKey<BibleReaderScreenState>();
  // [NOVO] Chave para controlar a Jornada e forçar refresh
  final GlobalKey<ReadingClubScreenState> _readingClubKey = GlobalKey<ReadingClubScreenState>();
  
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const TodayScreen(),
      BibleReaderScreen(key: _bibleReaderKey), 
      ReadingClubScreen(key: _readingClubKey), // [MODIFICADO] Passando a chave
      const ProfileScreen(),
    ];
  }

  void jumpToBible(String abbrev, int chapter, int verseNumber, [int? planId, int? dayNumber]) {
    _bibleReaderKey.currentState?.loadChapter(abbrev, chapter, verseNumber, planId, dayNumber);
    setState(() {
      _selectedIndex = 1; // Vai para a aba do meio (Bíblia)
    });
  }

  // [NOVO] Método chamado pela Bíblia ao terminar o dia
  void jumpToReadingClub() {
    // Força atualização dos dados (barra de progresso)
    _readingClubKey.currentState?.refreshData();
    setState(() {
      _selectedIndex = 2; // Volta para a aba de Jornadas
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Se clicou na Bíblia, sai do modo plano
      _bibleReaderKey.currentState?.exitPlanMode();
      refreshBibleTab();
    }
    if (index == 2) {
      // [NOVO] Se clicou na Jornada, atualiza os dados
      _readingClubKey.currentState?.refreshData();
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
                  icon: Icon(Icons.church_outlined),
                  activeIcon: Icon(Icons.church, color: arcaOrange),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_outlined),
                  activeIcon: Icon(Icons.auto_stories, color: arcaOrange),
                  label: 'Bíblia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined), 
                  activeIcon: Icon(Icons.explore, color: arcaOrange),
                  label: 'Jornada',
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