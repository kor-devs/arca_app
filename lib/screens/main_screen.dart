// lib/screens/main_screen.dart (V1.35 - Navbar Limpa + Métodos Legados Adaptados)
import 'package:arca_app/constants.dart';
import 'package:flutter/material.dart';

import 'tabs/today_screen.dart';
import 'tabs/bible_reader_screen.dart'; 
import 'tabs/profile_screen.dart';
// Import necessário para o método navigateToNotesTab funcionar
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
  // Mantemos APENAS a chave do Leitor, pois ele é a única aba com estado persistente complexo
  final GlobalKey<BibleReaderScreenState> _bibleReaderKey = GlobalKey<BibleReaderScreenState>();
  
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Navbar com 3 itens (Design Limpo)
    _widgetOptions = <Widget>[
      const TodayScreen(),
      BibleReaderScreen(key: _bibleReaderKey), 
      const ProfileScreen(),
    ];
  }

  // Navegação para a Bíblia
  void jumpToBible(String abbrev, int chapter, int verseNumber) {
    _bibleReaderKey.currentState?.loadChapter(abbrev, chapter, verseNumber);
    setState(() {
      _selectedIndex = 1; // Vai para a aba do meio (Bíblia)
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      refreshBibleTab();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- MÉTODOS RESTAURADOS E ADAPTADOS ---

  // 1. Refresh da Bíblia (Crucial)
  void refreshBibleTab() {
    _bibleReaderKey.currentState?.refreshContent();
  }

  // 2. Refresh Genérico (Adaptado)
  // Antigamente atualizava notas. Como a tela de notas não é mais fixa,
  // apenas garantimos que a Bíblia esteja atualizada (ex: ícones de notas nos versículos).
  void refreshContent() {
    refreshBibleTab();
  }

  // 3. Navegar para Notas (Adaptado)
  // Antigamente trocava de aba (index 3). Agora não existe index 3.
  // Solução: Empurramos a tela de Notas por cima (Push), como fazemos no Perfil.
  void navigateToNotesTab({
    required String bookAbbrev, 
    required int chapter, 
    required int verseNumber, 
    required String verseText, 
    required String bookName
  }) {
    // Abre a tela de notas como um modal/nova página
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesScreen(
          onJumpToBible: (abbrev, ch, verse) {
            Navigator.pop(context); // Fecha notas
            jumpToBible(abbrev, ch, verse); // Vai pra bíblia
          },
        ),
      ),
    );
  }
  // ---------------------------------------

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
              // Apenas 3 Itens
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
                  icon: Icon(Icons.dehaze_rounded),
                  activeIcon: Icon(Icons.dehaze_sharp, color: arcaOrange),
                  label: 'Mais',
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