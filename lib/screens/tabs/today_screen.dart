// lib/screens/tabs/today_screen.dart (V2.0 - UX/UI Moderno + Tutorial)
import 'package:arca_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:arca_app/screens/search_screen.dart';
import 'package:screenshot/screenshot.dart'; 
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart'; // Necessário para salvar estado do tutorial
import 'dart:async';

import '../../main.dart';
import '../../models/random_verse.dart';
import 'verse_of_the_day_card.dart';
import '../../constants.dart';

class TodayScreen extends StatefulWidget { 
  const TodayScreen({super.key});
  @override
  TodayScreenState createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  late Future<RandomVerse> futureVerseOfTheDay;
  String _greetingMessage = "";
  String _userName = "Irmão(ã)";
  
  final TextEditingController _homeSearchController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  // --- CONTROLE DO TUTORIAL ---
  Timer? _carouselTimer;
  bool _showTutorial = true;
  final PageController _tutorialController = PageController();
  int _currentTutorialPage = 0;

  final List<Map<String, String>> _tutorialSteps = [
    {
      "title": "Bem-vindo à Arca!",
      "desc": "Sua companhia diária na leitura bíblica e crescimento espiritual.",
      "icon": "👋"
    },
    {
      "title": "Busca Inteligente",
      "desc": "Procure por livros, palavras-chave, ou temas da bíblia.",
      "icon": "🔍"
    },
    {
      "title": "Compartilhe a Palavra",
      "desc": "Compartilhe versículos inspiradores com amigos e familiares.",
      "icon": "📤"
    },
    {
      "title": "Leitura & Notas",
      "desc": "Toque em um versículo para marcar, criar notas ou favoritar.",
      "icon": "📝"
    },
    {
      "title": "Versão de Estudo",
      "desc": "Todo livro da Bíblia com notas de estudo para aprofundar seu entendimento.",
      "icon": "💡"
    },
    {
      "title": "Vamos Começar!",
      "desc": "Sua experiência bíblica personalizada começa agora. Boa leitura!",
      "icon": "🙏"
    },
  ];

  @override
  void initState() {
    super.initState();
    futureVerseOfTheDay = fetchVerseOfTheDay();
    _generateGreeting();
    _checkTutorialStatus();
    // Inicia o carrossel do tutorial
    _startAutoScroll();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel(); // <--- Importante: Matar o timer ao sair da tela
    _tutorialController.dispose();
    super.dispose();
  }

  // Lógica do Carrossel Automático
  void _startAutoScroll() {
    _carouselTimer?.cancel(); // Garante que não tenha duplicidade
    _carouselTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_tutorialController.hasClients) {
        int nextPage = _currentTutorialPage + 1;
        
        // Lógica do Loop Infinito
        if (nextPage >= _tutorialSteps.length) {
          nextPage = 0;
        }

        _tutorialController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800), // Animação suave
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // Verifica se o usuário já fechou o tutorial anteriormente
  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showTutorial = prefs.getBool('show_home_tutorial') ?? true; // Padrão é mostrar
    });
  }

  // Fecha o tutorial e salva na memória
  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_home_tutorial', false);
    setState(() {
      _showTutorial = false;
    });
  }
  
  void _generateGreeting() {
    final user = supabase.auth.currentUser;
    if (user != null && user.userMetadata != null && user.userMetadata!['full_name'] != null) {
      String fullName = user.userMetadata!['full_name'];
      _userName = fullName.split(' ').first; 
    }
    final hour = DateTime.now().hour;
    String timeBasedGreeting;
    if (hour < 12) timeBasedGreeting = "Bom dia";
    else if (hour < 18) timeBasedGreeting = "Boa tarde";
    else timeBasedGreeting = "Boa noite";

    final List<String> options = ["Shalom,", "Graça e Paz,", "$timeBasedGreeting,"];
    setState(() {
      _greetingMessage = options[Random().nextInt(options.length)];
    });
  }

  Future<RandomVerse> fetchVerseOfTheDay() async {
    try {
      final dynamic response = await supabase.rpc('get_random_curated_verse');
      Map<String, dynamic> verseData;
      
      if (response is List) {
        if (response.isEmpty) throw Exception('Vazio');
        verseData = response[0] as Map<String, dynamic>;
      } else {
        verseData = response as Map<String, dynamic>;
      }
      return RandomVerse.fromJson(verseData);
    } catch (e) {
      try {
         final response = await http.get(Uri.parse("$apiUrl/verse-of-the-day"));
         if (response.statusCode == 200) {
           return RandomVerse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
         }
      } catch (_) {}
      throw Exception('Falha ao carregar versículo');
    }
  }

  void _captureAndShareVerseCard(RandomVerse verse) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando imagem...'), duration: Duration(seconds: 1)));
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(delay: const Duration(milliseconds: 20));
      if (imageBytes != null) {
        final xFile = XFile.fromData(imageBytes, mimeType: 'image/png', name: 'versiculo_arca.png');
        await Share.shareXFiles([xFile], text: "Leia a Bíblia com o Arca App! \"${verse.reference}\"");
        try { await supabase.rpc('increment_verse_share', params: {'p_verse_ref': verse.reference}); } catch (_) {}
      }
    } catch (e) {
      debugPrint("Erro share: $e");
    }
  }

  // --- UI COMPONENTS ---

  Widget _buildTutorialCard() {
    if (!_showTutorial) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color.fromARGB(146, 233, 182, 255), arcaWhite],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Stack(
            children: [
              // Listener detecta interação do usuário para pausar o carrossel
              Listener(
                onPointerDown: (_) {
                  // Usuário tocou: para o timer
                  _carouselTimer?.cancel();
                },
                onPointerUp: (_) {
                  // Usuário soltou: reinicia a contagem
                  _startAutoScroll();
                },
                child: PageView.builder(
                  controller: _tutorialController,
                  itemCount: _tutorialSteps.length,
                  onPageChanged: (index) => setState(() => _currentTutorialPage = index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(_tutorialSteps[index]['icon']!,
                              style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_tutorialSteps[index]['title']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: arcaPurple)),
                                const SizedBox(height: 4),
                                Text(_tutorialSteps[index]['desc']!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        height: 1.2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Botão Fechar (X)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[400]),
                  onPressed: _dismissTutorial,
                ),
              ),
              
              // Indicador de Páginas (Bolinhas)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_tutorialSteps.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentTutorialPage == index ? 20 : 6, // Animação de largura
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentTutorialPage == index
                            ? arcaPurple
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 55, // Altura fixa e confortável
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: arcaWhite,
        borderRadius: BorderRadius.circular(16), // Bordas mais arredondadas
        boxShadow: [
          BoxShadow(
            color: arcaPurple.withOpacity(0.25), // Sombra colorida (mais moderna)
            blurRadius: 15,
            offset: const Offset(0, 8), // Sombra deslocada para baixo (elevação)
          )
        ],
      ),
      child: Center(
        child: TextField(
          controller: _homeSearchController,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: arcaPurple, size: 26),
            suffixIcon: IconButton( // Ação clara de busca
               icon: const Icon(Icons.arrow_forward_ios_rounded, color: arcaOrange, size: 18),
               onPressed: () {
                 if (_homeSearchController.text.isNotEmpty) {
                    _triggerSearch(_homeSearchController.text);
                 }
               },
            ),
            contentPadding: const EdgeInsets.all(15),
            hintText: "Busque por livro, capítulo ou palavra-chave",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          ),
          onSubmitted: (query) { 
             if (query.isNotEmpty) {
                _homeSearchController.clear();
                _triggerSearch(query);
             }
          },
        ),
      ),
    );
  }

  void _triggerSearch(String query) async {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Moderno
      builder: (context) => SearchScreen(returnResult: true, initialQuery: query),
    );

    if (result != null && mainScreenState != null) {
      mainScreenState.jumpToBible(
        result['abbrev'] as String,
        result['chapter'] as int,
        result['verse'] as int,
      );
    }
  }

  Widget _buildVerseOfTheDayCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 9.0),
          child: Text(
            "VERSÍCULO DO DIA",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: arcaPurple,
            ),
          ),
        ),
        FutureBuilder<RandomVerse>(
          future: futureVerseOfTheDay,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 180,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                child: const Center(child: CircularProgressIndicator(color: arcaPurple)),
              );
            } else if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16)),
                child: const Text("Não foi possível carregar o versículo."),
              );
            } else if (snapshot.hasData) {
              return Screenshot(
                controller: _screenshotController,
                child: Container(
                  decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,5))]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: VerseOfTheDayCard(
                      verse: snapshot.data!,
                      onSharePressed: () => _captureAndShareVerseCard(snapshot.data!), 
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // LAYOUT MODERNO: Header Gradiente + Corpo Curvo + Elementos Flutuantes
    const double headerHeight = 260.0; 

    return Scaffold(
      backgroundColor: arcaWhite, // Fundo geral branco
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER & SEARCH STACK ---
            Stack(
              clipBehavior: Clip.none, // Permite que a SearchBar "vaze" para fora do header
              alignment: Alignment.center,
              children: [
                // 1. Fundo Roxo com Gradiente (Mais Profundidade)
                Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.fromARGB(255, 82, 31, 104), arcaPurple], // Gradiente roxo rico
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 25, 30, 80), // Padding bottom grande para caber a busca
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _greetingMessage,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(183, 250, 250, 250),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: arcaWhite,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Logo com sombra sutil
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]
                            ),
                            child: Image.asset(
                              'assets/images/arca_logo_circle.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Barra de Busca "Flutuante" (Floating Search Bar)
                // Posicionada na borda inferior do Header
                Positioned(
                  bottom: -25, // Metade dentro, metade fora (Overlap)
                  left: 24,
                  right: 24,
                  child: _buildSearchBar(),
                ),
              ],
            ),

            // --- CORPO DA TELA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 50), // Espaço para compensar a barra de busca flutuante

                  // 3. Tutorial (Novo Recurso)
                  // Só aparece se _showTutorial for true
                  _buildTutorialCard(),

                  // 4. Versículo do Dia
                  _buildVerseOfTheDayCard(),

                  const SizedBox(height: 40), // Espaço final
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}