// lib/screens/tabs/today_screen.dart (V3.0 - Header Compacto + Devocional)
import 'package:arca_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:arca_app/screens/search_screen.dart';
import 'package:screenshot/screenshot.dart'; 
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:async';

import '../../main.dart';
import '../../models/random_verse.dart';
import 'verse_of_the_day_card.dart';
import '../../constants.dart';
// Import da nova tela de Devocional
import '../reading_flow/devotional_screen.dart';

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
  bool _isSharing = false;

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
      "title": "Devocionais",
      "desc": "Um espaço de reflexão. Seu momento de intimidade com a Palavra de Deus. Um verdadeiro mergulho de intimidade com o Senhor",
      "icon": "🧎🏽"
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
    _startAutoScroll();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel(); 
    _tutorialController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel(); 
    _carouselTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_tutorialController.hasClients) {
        int nextPage = _currentTutorialPage + 1;
        if (nextPage >= _tutorialSteps.length) {
          nextPage = 0;
        }
        _tutorialController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800), 
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showTutorial = prefs.getBool('show_home_tutorial') ?? true; 
    });
  }

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
    setState(() { _isSharing = true; });
    await Future.delayed(const Duration(milliseconds: 50));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando imagem...'), duration: Duration(seconds: 1)));
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(delay: const Duration(milliseconds: 20));
      setState(() { _isSharing = false; });
      
      if (imageBytes != null) {
        final xFile = XFile.fromData(imageBytes, mimeType: 'image/png', name: 'versiculo_arca.png');
        await Share.shareXFiles([xFile], text: "\"${verse.text}\"${verse.reference} \n \n Continue lendo na Arca: arca.kordevs.com");
        try { await supabase.rpc('increment_verse_share', params: {'p_verse_ref': verse.reference}); } catch (_) {}
      }
    } catch (e) {
      debugPrint("Erro share: $e");
      setState(() { _isSharing = false; });
    }
  }

  // --- UI COMPONENTS ---

  // [NOVO] Card de Devocional Compacto e Chamativo
  Widget _buildDevotionalEntry() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navega para a tela de devocional criada anteriormente
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => DevotionalScreen(
                  onJumpToBible: (abbrev, chapter, verse) {
                    // Usamos o 'context' da TodayScreen para achar a MainScreen
                    final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                    mainScreen?.jumpToBible(abbrev, chapter, verse);
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3E0), Colors.white], // Leve tom laranja/branco
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: arcaOrange.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: arcaOrange.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
                )
              ]
            ),
            child: Row(
              children: [
                // Ícone de Destaque
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: arcaOrange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: arcaOrange, size: 24),
                ),
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DEVOCIONAL DE HOJE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: arcaOrange,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "alimento para a alma", // Poderia ser dinâmico com o título do dia
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Seta indicativa
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard() {
    if (!_showTutorial) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20), // Margem reduzida (era 24)
          height: 130, // Altura reduzida (era 140)
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
              Listener(
                onPointerDown: (_) {
                  _carouselTimer?.cancel();
                },
                onPointerUp: (_) {
                  _startAutoScroll();
                },
                child: PageView.builder(
                  controller: _tutorialController,
                  itemCount: _tutorialSteps.length,
                  onPageChanged: (index) => setState(() => _currentTutorialPage = index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Text(_tutorialSteps[index]['icon']!,
                              style: const TextStyle(fontSize: 36)), // Ícone levemente menor
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_tutorialSteps[index]['title']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15, // Fonte ajustada
                                        color: arcaPurple)),
                                const SizedBox(height: 4),
                                Text(_tutorialSteps[index]['desc']!,
                                    style: TextStyle(
                                        fontSize: 12, // Fonte ajustada
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
              
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  padding: EdgeInsets.zero, // Remove padding interno para ficar mais compacto
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  onPressed: _dismissTutorial,
                ),
              ),
              
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_tutorialSteps.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentTutorialPage == index ? 16 : 5,
                      height: 5,
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
      height: 50, // Altura reduzida (era 55)
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: arcaWhite,
        borderRadius: BorderRadius.circular(25), // Mais arredondado (Pill shape)
        boxShadow: [
          BoxShadow(
            color: arcaPurple.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Center(
        child: TextField(
          controller: _homeSearchController,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: arcaPurple, size: 22),
            suffixIcon: IconButton(
               padding: EdgeInsets.zero,
               constraints: const BoxConstraints(),
               icon: const Icon(Icons.arrow_forward_ios_rounded, color: arcaOrange, size: 16),
               onPressed: () {
                 if (_homeSearchController.text.isNotEmpty) {
                    _triggerSearch(_homeSearchController.text);
                 }
               },
            ),
            contentPadding: EdgeInsets.zero,
            hintText: "Busque livro, tema ou palavra...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
      backgroundColor: Colors.transparent,
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
        // Título reduzido e com menos padding
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            "VERSÍCULO DO DIA",
            style: TextStyle(
              fontSize: 11, // Fonte menor
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
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
                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0,4))]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: VerseOfTheDayCard(
                      verse: snapshot.data!,
                      onSharePressed: () => _captureAndShareVerseCard(snapshot.data!), 
                      isSharingMode: _isSharing,
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
    // --- UX UPGRADE: Header mais compacto ---
    const double headerHeight = 200.0; // Reduzido de 260 para 200

    return Scaffold(
      backgroundColor: arcaWhite, 
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.fromARGB(255, 82, 31, 104), arcaPurple], 
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    // Padding Bottom reduzido drasticamente para subir a busca
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 50), 
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _greetingMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(220, 250, 250, 250),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 28, // Fonte reduzida de 40 para 28
                                  fontWeight: FontWeight.w800,
                                  color: arcaWhite,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Logo reduzido
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                            ),
                            child: Image.asset(
                              'assets/images/arca_logo_circle.png',
                              width: 60, // Reduzido de 100 para 60
                              height: 60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Barra de Busca subiu junto com o Header
                Positioned(
                  bottom: -25, 
                  left: 24,
                  right: 24,
                  child: _buildSearchBar(),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 45), // Espaço reduzido

                  // 1. Tutorial (Se ativo)
                  _buildTutorialCard(),
                  
                  // 2. [NOVO] Devocional (Logo abaixo do tutorial ou no topo)
                  _buildDevotionalEntry(),

                  // 3. Versículo
                  _buildVerseOfTheDayCard(),

                  const SizedBox(height: 30), // Padding final
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}