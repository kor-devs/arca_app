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
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import '../../main.dart';
import '../../models/random_verse.dart';
import '../../models/devotional_model.dart';
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

  int _currentStreak = 0;
  bool _isLoadingStats = true;

  bool _isTodayDevotionalCompleted = false;

  Devotional? _todayDevotional;
  
  final TextEditingController _homeSearchController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotController _moodScreenshotController = ScreenshotController();

  // --- CONTROLE DO TUTORIAL ---
  Timer? _carouselTimer;
  bool _showTutorial = true;
  final PageController _tutorialController = PageController();
  int _currentTutorialPage = 0;
  bool _isSharing = false;

  // Variáveis para o Check-in Emocional
  bool _isMoodLoading = false;
  Map<String, dynamic>? _moodResponseVerse;

  final List<Map<String, dynamic>> _badges = [
    // 0 Dias: Sem Medalha
    {'days': 0, 'title': 'Lenha', 'icon': Icons.compost, 'color': [const Color(0xFFCD7F32), const Color.fromARGB(255, 139, 27, 19)]},
    // 3 Dias: Bronze / Início
    {'days': 3, 'title': 'Chama Inicial', 'icon': Icons.whatshot_outlined, 'color': [const Color(0xFFCD7F32), const Color.fromARGB(255, 139, 27, 19)]}, 
    // 7 Dias: Prata / Hábito
    {'days': 7, 'title': 'Labareda', 'icon': Icons.whatshot_sharp, 'color': [const Color(0xFFCD7F32), const Color.fromARGB(255, 139, 27, 19)]}, 
    // 14 Dias: Ouro / Compromisso
    {'days': 14, 'title': 'Incendiário', 'icon': Icons.local_fire_department_rounded, 'color': [const Color(0xFFCD7F32), const Color.fromARGB(255, 139, 27, 19)]},
    // 21 Dias: Diamante / Estilo de Vida
    {'days': 21, 'title': 'Fogo Constante', 'icon': Icons.fireplace_outlined, 'color': [const Color(0xFFCD7F32), const Color.fromARGB(255, 139, 27, 19)]},
    // 30 Dias: Mestre / Legado
    {'days': 30, 'title': 'Sarça Ardente', 'icon': Icons.auto_awesome, 'color': [const Color(0xFFCD7F32), const Color.fromARGB(255, 139, 27, 19)]},
  ];

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

  // Lista de Humores para a UI
  final List<Map<String, dynamic>> _moodOptions = [
    {
      'id': 'feliz', 
      'emoji': '😃', 
      'label': 'Feliz',
      'colors': [arcaOrange, arcaYellow] // Energia
    },
    {
      'id': 'grato', 
      'emoji': '🙏', 
      'label': 'Grato',
      'colors': [arcaPurple, const Color(0xFF9B59B6)] // Espiritualidade
    },
    {
      'id': 'esperancoso', 
      'emoji': '🕊️', 
      'label': 'Com fé',
      'colors': [arcaBlue, Colors.lightBlueAccent] // Esperança/Céu
    },
    {
      'id': 'ansioso', 
      'emoji': '😰', 
      'label': 'Ansioso',
      'colors': [const Color(0xFFE67E22), const Color(0xFFF39C12)] // Atenção suave
    },
    {
      'id': 'triste', 
      'emoji': '😢', 
      'label': 'Triste',
      'colors': [const Color(0xFF5D6D7E), const Color(0xFF85929E)] // Acolhimento (Azul acinzentado)
    },
    {
      'id': 'cansado', 
      'emoji': '😫', 
      'label': 'Cansado',
      'colors': [const Color(0xFF7F8C8D), const Color(0xFFBDC3C7)] // Descanso (Cinza neutro)
    },
  ];

  void _shareMoodVerse() async {
    setState(() { _isSharing = true; });
    // Pequeno delay para garantir renderização
    await Future.delayed(const Duration(milliseconds: 50)); 
    try {
      final Uint8List? imageBytes = await _moodScreenshotController.capture();
      setState(() { _isSharing = false; });
      
      if (imageBytes != null) {
        final xFile = XFile.fromData(imageBytes, mimeType: 'image/png', name: 'humor_arca.png');
        await Share.shareXFiles([xFile], text: "Uma palavra para o seu coração hoje ❤️\n\nAcesse: https://arca.kordevs.com");
        try { await supabase.rpc('track_user_share', params: {'p_resource_type': 'MOOD', 'p_reference': 'humor'}); } catch (_) {}
      }

    } catch (e) {
      debugPrint("Erro share mood: $e");
      setState(() { _isSharing = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    futureVerseOfTheDay = fetchVerseOfTheDay();
    _generateGreeting();
    _checkTutorialStatus();
    _startAutoScroll();
    _fetchDataAndRegisterActivity();
  }

  Future<void> _fetchDataAndRegisterActivity() async {
    // 1. Registra o "Login" para contar no Streak
    await _registerUserActivity('LOGIN');
    
    // 2. Carrega dados (Devocional e Stats atualizados)
    _fetchTodayDevotional();
    // _fetchUserStats(); // Não precisa chamar separado se o _registerUserActivity já atualizar o local state, mas por segurança pode manter ou remover
  }

  Future<void> _registerUserActivity(String type) async {
    try {
      // Chama a RPC (Function) do Supabase criada no Passo 1
      final response = await supabase.rpc('handle_user_activity', params: {
        'p_activity_type': type
      });
      
      if (response != null && mounted) {
        debugPrint("Activity Logged: $response");
        setState(() {
          _currentStreak = response['streak'];
          _isLoadingStats = false;
        });
        
        // Opcional: Mostrar SnackBar se o streak subiu
        if (response['message'].toString().contains('subiu')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Parabéns! ${response['message']}"), backgroundColor: arcaOrange)
          );
        }
      }
    } catch (e) {
      debugPrint("Erro ao registrar atividade: $e");
      // Fallback: tenta carregar o antigo se der erro na RPC
      _fetchUserStats();
    }
  }

  Future<void> _handleMoodSelection(String moodId) async {
    setState(() {
      _isMoodLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // 1. Salva o Log de Humor (Mantém o histórico)
        // Nota: A tabela user_mood_logs continua necessária para o histórico do usuário
        await supabase.from('user_mood_logs').insert({
          'user_id': user.id,
          'mood': moodId,
        });

        // 2. Busca versículo na curated_verses via RPC
        // Passamos o 'moodId' como a tag a ser buscada (ex: 'ansioso')
        final response = await supabase
            .rpc('get_verse_by_mood', params: {'p_mood_tag': moodId});

        if (response != null && mounted) {
          // O response é um Map<String, dynamic> vindo do JSONB
          setState(() {
            _moodResponseVerse = {
              'text': response['text'], // Campo da curated_verses
              'ref': response['reference'], // Campo da curated_verses
              
              // Campos de Navegação (cruciais para o clique funcionar)
              'abbrev': response['book_abbrev'],
              'chapter': response['chapter'],
              'verse': response['verse_number'], // Atenção: seu JSON usa verse_number
              
              // Extra: Podemos usar a imagem de fundo se quiser no futuro
              'image': response['image_url'] 
            };
          });
        } else {
          // Caso não encontre nenhum versículo com essa tag
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Recebemos seu sentimento. Estamos orando por você."))
            );
            setState(() {
              _moodResponseVerse = null;
            });
          }
        }
        
        // 3. Atualiza Streak (Gamification)
        _registerUserActivity('MOOD_CHECKIN');
      }
    } catch (e) {
      debugPrint("Erro mood: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao conectar. Tente novamente."))
        );
      }
    } finally {
      if (mounted) setState(() => _isMoodLoading = false);
    }
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
    if (hour < 12) {
      timeBasedGreeting = "Bom dia";
    } else if (hour < 18) timeBasedGreeting = "Boa tarde";
    else timeBasedGreeting = "Boa noite";

    final List<String> options = ["Shalom,", "Graça e Paz,", "$timeBasedGreeting,"];
    setState(() {
      _greetingMessage = options[Random().nextInt(options.length)];
    });
  }

  Future<void> _fetchUserStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('user_stats')
          .select('current_streak')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentStreak = response['current_streak'] ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar stats: $e");
    }
  }

  Future<void> _fetchTodayDevotional() async {
    final user = supabase.auth.currentUser;
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;

    try {
      // --- MUDANÇA CRÍTICA AQUI ---
      // Adicionamos ', curated_verses(*)' para trazer o versículo vinculado
      final response = await supabase
          .from('devotionals')
          .select('*, curated_verses(*)') 
          .eq('day_of_year', dayOfYear)
          .maybeSingle();

      if (response != null && mounted) {
        final devotional = Devotional.fromJson(response);
        
        // --- 1. LÓGICA DO VERSÍCULO VINCULADO ---
        RandomVerse? linkedVerse;
        
        if (response['curated_verses'] != null) {
          // O Supabase encontrou o versículo vinculado!
          debugPrint(">>> VÍNCULO ENCONTRADO: ${response['curated_verses']['reference']}");
          
          linkedVerse = RandomVerse.fromJson(response['curated_verses']);
          
          // FORÇA a atualização do card "Versículo do Dia"
          setState(() {
            futureVerseOfTheDay = Future.value(linkedVerse);
          });
        } else {
          debugPrint(">>> SEM VÍNCULO. Buscando aleatório...");
        }

        // --- 2. LÓGICA DE LEITURA CONCLUÍDA ---
        bool isCompleted = false;
        if (user != null) {
          final readCheck = await supabase
              .from('user_devotionals')
              .select()
              .eq('user_id', user.id)
              .eq('devotional_id', devotional.id)
              .maybeSingle();

          if (readCheck != null) isCompleted = true;
        }

        // Atualiza a tela com a devocional
        setState(() {
          _todayDevotional = devotional;
          _isTodayDevotionalCompleted = isCompleted;
        });

      } else {
        // Fallback se não achar devocional do dia
        debugPrint("--- Nenhum devocional para o dia $dayOfYear ---");
        // ... (seu código de fallback pode ficar aqui se quiser)
      }
    } catch (e) {
      debugPrint("Erro CRÍTICO no devocional: $e");
    }
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
        await Share.shareXFiles([xFile], text: "\"${verse.text}\"${verse.reference} \n \n Continue a leitura na Arca: arca.kordevs.com");
        try { await supabase.rpc('track_user_share', params: {'p_resource_type': 'VERSE_DAY', 'p_reference': verse.reference}); } catch (_) {}
        try { await supabase.rpc('increment_verse_share', params: {'p_verse_ref': verse.reference}); } catch (_) {}
      }
    } catch (e) {
      debugPrint("Erro share: $e");
      setState(() { _isSharing = false; });
    }
  }

  // --- UI COMPONENTS ---

  Widget _buildMoodTracker() {
    // === ESTADO: VERSÍCULO DE RESPOSTA (Mantém o design aprovado) ===
    if (_moodResponseVerse != null) {
      return Screenshot( // 1. Envolvemos com Screenshot
        controller: _moodScreenshotController,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: arcaWhite, // Fundo sólido necessário para o print sair limpo
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: arcaPurple.withOpacity(0.3)),
            boxShadow: [
               BoxShadow(color: arcaPurple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))
            ]
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (_moodResponseVerse!['abbrev'] != null && 
                    _moodResponseVerse!['chapter'] != null) {
                  final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                  mainScreen?.jumpToBible(
                    _moodResponseVerse!['abbrev'], 
                    _moodResponseVerse!['chapter'], 
                    _moodResponseVerse!['verse'] ?? 1
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: arcaPurple.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.auto_awesome, size: 16, color: arcaPurple),
                            ),
                            const SizedBox(width: 10),
                            Text("Para seu coração:", 
                              style: TextStyle(color: arcaPurple.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        // Botoes de Ação
                        Row(
                          children: [
                            // 2. Botão de Compartilhar NOVO
                            if (!_isSharing) // Esconde o botão durante o print
                            InkWell(
                              onTap: _shareMoodVerse,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(color: arcaOrange.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.share, size: 16, color: arcaOrange),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() { _moodResponseVerse = null; }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"${_moodResponseVerse!['text']}"',
                      style: const TextStyle(
                        fontSize: 16, 
                        height: 1.4,
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic, 
                        color: Color(0xFF2C3E50)
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: arcaOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _moodResponseVerse!['ref']!.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: arcaOrange),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 12, color: arcaOrange)
                        ],
                      ),
                    ),
                    if (_isSharing) // Marca d'água apenas no print
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text("@entrenaarca", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // === ESTADO: BOTÕES VIBRANTES (Fixos) ===
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            "COMO ESTÁ SE SENTINDO HOJE?",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: arcaPurple,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _moodOptions.length,
            clipBehavior: Clip.none,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            padding: const EdgeInsets.all(4), // Padding para a sombra não cortar
            itemBuilder: (context, index) {
              final item = _moodOptions[index];
              final List<Color> gradientColors = item['colors'];

              return Container(
                width: 72, // Tamanho fixo
                decoration: BoxDecoration(
                  // Gradiente sempre visível e vibrante
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  // Sombra colorida suave sempre visível
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isMoodLoading ? null : () => _handleMoodSelection(item['id']),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['emoji'], 
                          style: const TextStyle(fontSize: 28)
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texto branco para contraste no fundo colorido
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
                            ]
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDevotionalEntry() {
  // Se não carregou ainda, não mostra
  if (_todayDevotional == null) return const SizedBox.shrink();

  final dev = _todayDevotional!;
  
  // --- Definição da Variável (O erro estava aqui pois ela não era usada abaixo) ---
  final DateTime now = DateTime.now();
  final String dateString = "${now.day}/${now.month}"; 

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
        child: Text(
          "DEVOCIONAL DO DIA",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: arcaPurple, // Certifique-se que essa cor existe nas suas constants
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C), // Fundo Dark
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Navegação
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => DevotionalScreen(
                    devotionalId: dev.id,
                    initialData: dev,
                    onJumpToBible: (abbrev, chapter, verse) {
                      final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                      mainScreen?.jumpToBible(abbrev, chapter, verse);
                    },
                  ),
                ),
              );
              
              // Se retornou true (concluiu)
              if (result == true) {
                setState(() {
                  _isTodayDevotionalCompleted = true;
                });
                
                // [IMPORTANTE] Delay para o banco processar o update do streak antes de lermos
                await Future.delayed(const Duration(seconds: 1));
                
                // Agora sim buscamos o dado atualizado
                await _fetchUserStats(); 
                _registerUserActivity('LEITURA_CONCLUIDA');
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem de Capa
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: dev.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[850], 
                            child: const Icon(Icons.broken_image, color: Colors.white24)
                          ),
                        ),
                      ),
                    ),
                    // Gradiente Fade
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF1E1E2C).withOpacity(0.0),
                              const Color(0xFF1E1E2C),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // --- 1. BADGE ESQUERDA: DATA E TEMA (Onde usamos dateString) ---
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: arcaOrange),
                            const SizedBox(width: 6),
                            // AQUI ESTÁ O USO DA VARIÁVEL dateString
                            Text(
                              "$dateString • ${dev.theme.toUpperCase()}",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- 2. BADGE DIREITA: CONCLUÍDO (Novo) ---
                    if (_isTodayDevotionalCompleted)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: arcaNeonGreen, // Certifique-se de ter essa cor ou use Colors.greenAccent
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                "CONCLUÍDO",
                                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Conteúdo
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            "Leitura de ${dev.duration}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dev.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Baseado em ${dev.verseReference}",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),
                      
                      // Botão de Ação (Adapta a cor se concluído)
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isTodayDevotionalCompleted ? Colors.green.withOpacity(0.8) : arcaOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                             _isTodayDevotionalCompleted ? "LER NOVAMENTE" : "LER DEVOCIONAL",
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
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
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 20),

                  _buildMoodTracker(),
                  const SizedBox(height: 20),

                  // 2. Versículo
                  _buildVerseOfTheDayCard(),
                  const SizedBox(height: 20),

                  // 3. Intimidade com a Palavra
                  _buildIntimacyCard(),
                  const SizedBox(height: 20),

                  // 4. Devocional do Dia
                  _buildDevotionalEntry(),

                  const SizedBox(height: 30), // Padding final
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildMedalBadge(Map<String, dynamic> badge, bool isUnlocked) {
    final List<Color> colors = badge['color'] as List<Color>;
    
    return Container(
      height: 65, // Medalha maior
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradiente principal (Ouro/Prata/Bronze)
        gradient: LinearGradient(
          colors: isUnlocked ? colors : [Colors.grey.shade800, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Sombra para dar efeito 3D
          if (isUnlocked)
            BoxShadow(color: colors.first.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 4))
        ],
        // Borda externa
        border: Border.all(
          color: isUnlocked ? Colors.white.withOpacity(0.3) : Colors.white10,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.3), // Fundo escuro interno
            border: Border.all(
              color: isUnlocked ? colors.first.withOpacity(0.6) : Colors.transparent, 
              width: 1
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge['icon'],
                color: isUnlocked ? Colors.white : Colors.white24,
                size: 35,
              ),
              // Mantemos apenas o ícone centralizado na medalha; não mostrar o contador de dias
            ],
          ),
        ),
      ),
    );
  }

  // Pull-to-refresh handler: refresh verse, stats and devotional
  Future<void> _refreshPage() async {
    try {
      // trigger a fresh fetch for verse of the day
      setState(() {
        futureVerseOfTheDay = fetchVerseOfTheDay();
      });

      // await all tasks (best-effort)
      await Future.wait([
        futureVerseOfTheDay,
        _fetchUserStats(),
        _fetchTodayDevotional(),
      ]);
    } catch (e) {
      // ignore errors silently; RefreshIndicator will stop spinning
    }
  }

  // --- CARD DE INTIMIDADE (BADGES) ---
  Widget _buildIntimacyCard() {
    if (_isLoadingStats) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 120,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator(color: arcaPurple, strokeWidth: 2)),
      );
    }

    // Lógica de Nível
    Map<String, dynamic> nextBadge = _badges.first;
    Map<String, dynamic> currentBadge = _badges.first;
    
    // Se o usuário tem 0 dias, ele está buscando o primeiro badge
    if (_currentStreak < _badges.first['days']) {
       currentBadge = _badges.first; // Mostra o alvo
       nextBadge = _badges.first;
    } else {
      for (int i = 0; i < _badges.length; i++) {
        if (_currentStreak >= _badges[i]['days']) {
          currentBadge = _badges[i]; // Conquistou este
        }
        if (_currentStreak < _badges[i]['days']) {
          nextBadge = _badges[i]; // Próximo alvo
          break; 
        }
      }
    }

    // Cálculo da Barra
    int target = nextBadge['days'] as int;
    if (_currentStreak >= _badges.last['days']) target = _currentStreak * 2;
    double progress = _currentStreak / target;
    if (progress > 1.0) progress = 1.0;

    // Se o usuário ainda não atingiu o mínimo (3 dias), a medalha fica "bloqueada" visualmente
    bool hasMinimumBadge = _currentStreak >= currentBadge['days'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0249).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        // Gradiente Premium YouVersion-like
        gradient: const LinearGradient(
          colors: [Color(0xFF3b1d60), Color(0xFF632c63)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Imagem de fundo sutil (opcional, simula textura)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final mainScreen = context.findAncestorStateOfType<MainScreenState>();
            mainScreen?.jumpToReadingClub();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                // 1. A Medalha (Esquerda)
                _buildMedalBadge(currentBadge, hasMinimumBadge),
                
                const SizedBox(width: 18),
                
                // 2. Estatísticas (Centro/Direita)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "INTIMIDADE COM A PALAVRA",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$_currentStreak",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text("dias • ",
                            style: TextStyle(color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text("${currentBadge['title']}",
                            style: const TextStyle(color: arcaYellow,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Barra de Progresso com Rótulo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Próx: ${(nextBadge['title'] as String)}", 
                            style: const TextStyle(color: arcaYellow, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                          Text(
                            "$target dias", 
                            style: const TextStyle(color: Colors.white38, fontSize: 10)
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8.0,
                        percent: progress,
                        backgroundColor: Colors.black26,
                        progressColor: (nextBadge['color'] as List<Color>).first, // Usa a cor da medalha alvo
                        barRadius: const Radius.circular(4),
                        animation: true,
                        animationDuration: 1200,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}