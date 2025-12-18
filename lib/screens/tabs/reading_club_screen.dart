// lib/screens/tabs/reading_club_screen.dart (V8.0 - FULL FILE - GAMIFIED MAP FIXED)
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Certifique-se de ter este package
import 'package:cached_network_image/cached_network_image.dart'; // Certifique-se de ter este package
import 'dart:math' as math;
import 'dart:async';

import '../../main.dart';
import '../../constants.dart';
import '../main_screen.dart';
import '../../services/notification_service.dart';
import '../reading_flow/devotional_screen.dart';


class ReadingClubScreen extends StatefulWidget {
  const ReadingClubScreen({super.key});

  @override
  State<ReadingClubScreen> createState() => ReadingClubScreenState();
}

class ReadingClubScreenState extends State<ReadingClubScreen> with TickerProviderStateMixin {
  // --- DADOS E ESTADO ---
  bool _isLoading = true;
  List<Map<String, dynamic>> _myActivePlans = [];
  List<Map<String, dynamic>> _featuredPlans = [];
  List<Map<String, dynamic>> _allPlans = [];
  
  // Stats do Usuário
  int _streak = 0; 
  int _totalDevotionalsRead = 0; 
  int _totalShares = 0;
  int _totalInvites = 0;
  //final int _totalPlansCompleted = 0;
  
  // O Ciclo é baseado no nível atual. Nível 1 = Ciclo 1. Nível 2 = Ciclo 2.
  int get _currentCycle => _calculateLevelInfo()['level'] as int;

  // Metas Escalonáveis (Multiplicam pelo ciclo atual)
  // Ex: Ciclo 1 = 7 dias. Ciclo 2 = 14 dias. Ciclo 3 = 21 dias.
  int get _targetIntimacy => 7 * _currentCycle;
  int get _targetShares => 20 * _currentCycle;
  int get _targetInvites => 10 * _currentCycle;

  // 1. Base: Progresso do Plano Atual (Mantido)
  double _getPlansProgress() {
    if (_myActivePlans.isEmpty) return 0.0;
    final plan = _myActivePlans.first;
    final total = plan['reading_plans']['duration_days'] as int;
    final current = plan['current_day'] as int;
    return (current / total).clamp(0.0, 1.0);
  }

  // 2. Meio: Intimidade (Meta dinâmica baseada no ciclo)
  double _getDevotionalProgress() {
    return (_streak / _targetIntimacy).clamp(0.0, 1.0);
  }

  // 3. Esquerda: Semear (Meta dinâmica)
  double _getShareProgress() {
    return (_totalShares / _targetShares).clamp(0.0, 1.0);
  }

  // 4. Direita: Evangelista (Meta dinâmica)
  double _getInviteProgress() {
    return (_totalInvites / _targetInvites).clamp(0.0, 1.0);
  }
  
  // Verifica se o usuário "zerou" o mapa atual
  bool _isMapCompleted() {
    return _getPlansProgress() >= 1.0 &&
           _getDevotionalProgress() >= 1.0 &&
           _getShareProgress() >= 1.0 &&
           _getInviteProgress() >= 1.0;
  }

  // Gera a lista de nós para o mapa Zig-Zag
  List<Map<String, dynamic>> _generateNodes() {
    final bool mapCompleted = _isMapCompleted();

    return [
      // NÓ 1 (Base): Planos
      {
        'id': 'plans',
        'icon': Icons.auto_stories,
        'label': "Planos Bíblicos",
        'sub': _myActivePlans.isNotEmpty ? "Dia ${_myActivePlans.first['current_day']}" : "Iniciar",
        'progress': _getPlansProgress(),
        'color': arcaOrange,
        'onTap': () => _openReadingHub(initialTab: 0),
        'alignment': -0.5, // Esquerda
      },
      // NÓ 2: Intimidade
      {
        'id': 'intimacy',
        'icon': Icons.local_fire_department,
        'label': "Intimidade",
        'sub': "$_streak / $_targetIntimacy Dias",
        'progress': _getDevotionalProgress(),
        'color': Colors.redAccent,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meta do Nível $_currentCycle: $_targetIntimacy dias seguidos"))),
        'alignment': 0.5, // Direita
      },
      // NÓ 3: Semear
      {
        'id': 'share',
        'icon': Icons.share,
        'label': "Semear",
        'sub': "$_totalShares / $_targetShares",
        'progress': _getShareProgress(),
        'color': Colors.blue,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meta do Nível $_currentCycle: $_targetShares compartilhamentos"))),
        'alignment': -0.5, // Direita
      },
      // NÓ 4: Evangelista
      {
        'id': 'invite',
        'icon': Icons.group_add,
        'label': "Evangelista",
        'sub': "$_totalInvites / $_targetInvites",
        'progress': _getInviteProgress(),
        'color': Colors.purpleAccent,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meta do Nível $_currentCycle: $_targetInvites convites"))),
        'alignment': 0.5, // Esquerda
      },
      // NÓ 5 (Topo): Próximo Nível (Boss)
      {
        'id': 'boss',
        'icon': mapCompleted ? Icons.star : Icons.lock, // Estrela se desbloqueado
        'label': mapCompleted ? "DEVOCIONAL FINAL" : "Bloqueado",
        'sub': mapCompleted ? "Toque para Subir" : "Complete a Trilha",
        'progress': mapCompleted ? 1.0 : 0.0,
        'color': mapCompleted ? arcaOrange : Colors.grey, // Laranja destaque
        'scale': 1.5, // Bem maior que os outros
        'isLocked': !mapCompleted,
        'onTap': () {
          if (!mapCompleted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete a trilha para enfrentar o desafio final!")));
          } else {
             _openBossDevotional(); // <--- NOVA FUNÇÃO
          }
        },
        'alignment': 0.0,
      },
    ];
  }

  // --- AÇÃO DO BOSS ---
  void _openBossDevotional() {
    // 1. Identificar qual devocional abrir (pode ser hardcoded por nível ou vindo do banco)
    // Exemplo: Nível 1 abre devocional ID 100, Nível 2 abre ID 200...
    int bossDevotionalId = 100 + _currentCycle; 

    // 2. Navegar (Usando a tela que já temos)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DevotionalScreen(
          devotionalId: bossDevotionalId, 
          // Opcional: Passar um parametro 'isBoss: true' para a tela mudar o visual se quiser
          onJumpToBible: (abbrev, ch, verse) {
            // Lógica de salto normal
          },
        ),
      ),
    ).then((completed) async {
      // 3. SE O USUÁRIO COMPLETOU (Retorno true do pop)
      if (completed == true) {
        // Damos um "Level Up" manual
        // Adicionamos XP extra para garantir a subida de nível
        await _grantLevelUpBonus();
      }
    });
  }

  Future<void> _grantLevelUpBonus() async {
    setState(() => _isLoading = true);
    try {
      // RPC fictícia ou update manual. Vamos simular somando leituras.
      // A ideia é garantir que ele passe o threshold do próximo nível.
      final user = supabase.auth.currentUser;
      if (user != null) {
         // Adiciona 5 leituras fictícias como bônus de conclusão de mapa
         await supabase.rpc('increment_devotional_count', params: {'amount': 5}); 
         
         await _loadData(); // Recarrega -> O Nível sobe -> O Bioma muda!
         
         if (mounted) {
           _showLevelUpDialog();
         }
      }
    } catch (e) {
      debugPrint("Erro bonus: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLevelUpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("NOVO NÍVEL ALCANÇADO! 🚀"),
        content: const Text("Você completou a jornada e subiu para um novo patamar espiritual. O cenário mudou, e novos desafios aguardam!"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("GLÓRIA A DEUS!"))],
      )
    );
  }

  // --- CONTROLLERS ---
  late AnimationController _floatController;
  late TabController _modalTabController;
  final ScrollController _scrollController = ScrollController();

  // Níveis de Gamificação (XP necessário para subir)
  final List<int> _levelMilestones = [5, 15, 30, 60, 150, 365];

  @override
  void initState() {
    super.initState();
    _modalTabController = TabController(length: 2, vsync: this);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Apenas carrega os dados. O scroll acontecerá lá dentro quando terminar.
    _loadData();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _modalTabController.dispose();
    super.dispose();
  }

  // Método público para ser chamado pela MainScreen
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_myActivePlans.isEmpty) setState(() { _isLoading = true; });
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Carrega Planos (Mantém igual)
      final activeResp = await supabase.from('user_active_plans').select('*, reading_plans(*)').eq('user_id', user.id).eq('is_completed', false).order('last_read_at', ascending: false);
      _myActivePlans = List<Map<String, dynamic>>.from(activeResp);

      final plansResp = await supabase.from('reading_plans').select().order('is_featured', ascending: false);
      _allPlans = List<Map<String, dynamic>>.from(plansResp);
      _featuredPlans = _allPlans.where((p) => p['is_featured'] == true).toList();

      try {
        final statsResp = await supabase
            .from('user_stats')
            .select('current_streak, total_devotionals_read, total_shares, total_invites') 
            .eq('user_id', user.id)
            .maybeSingle();
            
        if (statsResp != null) {
          _streak = statsResp['current_streak'] ?? 0;
          int dbTotal = statsResp['total_devotionals_read'] ?? 0;
          _totalDevotionalsRead = (dbTotal > 0) ? dbTotal : _streak;
          _totalShares = statsResp['total_shares'] ?? 0;
          _totalInvites = statsResp['total_invites'] ?? 0;
        }
      } catch (e) {
        debugPrint("Aviso: Stats error $e");
        _streak = 0; 
        _totalDevotionalsRead = 0;
      }

    } catch (e) {
      debugPrint("Erro data: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
        
        // [CORREÇÃO AQUI]
        // Agenda o scroll para o frame seguinte, garantindo que o Mapa já foi renderizado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // maxScrollExtent é o final da lista (onde fica o Nó 1, a base da montanha)
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    }
  }

  // --- LÓGICA DE NÍVEL ---
  Map<String, dynamic> _calculateLevelInfo() {
    int level = 1;
    int nextGoal = _levelMilestones[0];
    int prevGoal = 0;

    for (int i = 0; i < _levelMilestones.length; i++) {
      if (_totalDevotionalsRead >= _levelMilestones[i]) {
        level = i + 2; 
        prevGoal = _levelMilestones[i];
        nextGoal = (i + 1 < _levelMilestones.length) ? _levelMilestones[i+1] : _levelMilestones[i] * 2;
      } else {
        nextGoal = _levelMilestones[i];
        break;
      }
    }

    int currentXp = _totalDevotionalsRead - prevGoal;
    int neededXp = nextGoal - prevGoal;
    double percent = (neededXp > 0) ? (currentXp / neededXp).clamp(0.0, 1.0) : 0.0;

    return {
      'level': level,
      'nextGoal': nextGoal,
      'percent': percent,
      'total': _totalDevotionalsRead,
      'rankName': _getRankName(level),
      'biomeColors': _getBiomeColors(level),
    };
  }

  String _getRankName(int level) {
    if (level == 1) return "Peregrino";
    if (level == 2) return "Explorador";
    if (level == 3) return "Discípulo";
    if (level == 4) return "Guardião";
    if (level == 5) return "Embaixador";
    return "Lenda da Fé";
  }

  // --- CONFIGURAÇÃO DOS BIOMAS ---
  
  // 1. Cores do Fundo (Gradiente)
  List<Color> _getBiomeColors(int level) {
    if (level <= 2) return [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)]; // Deserto (Laranja claro)
    if (level <= 4) return [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]; // Floresta (Verde claro)
    return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)]; // Céu (Lilás/Celestial)
  }

  // 2. Cor da Estrada (Ouro no céu, Terra na floresta, Areia no deserto)
  Color _getPathColor(int level) {
    if (level <= 2) return const Color(0xFFD7CCC8); // Terra seca (Deserto)
    if (level <= 4) return const Color(0xFF795548); // Terra fértil (Floresta)
    return const Color(0xFFFFD700); // OURO (Céu)
  }

  // 3. Decorações (Ping-Pong: Alternância forçada Esquerda/Direita)
  Widget _buildBiomeDecorations(int level, double width, double height) {
    List<Widget> items = [];
    // Usamos o nível para variar a "cara" do aleatório, mas a estrutura será fixa
    final math.Random random = math.Random(level); 

    List<String> assets;
    
    if (level <= 2) { 
      // DESERTO
      assets = ['🌵', '🌵', '🌾', '🪨', '🪨', '🦂', '☀️', '🦎'];
    } else if (level <= 4) { 
      // FLORESTA
      assets = ['🌲', '🌲', '🌳', '🍄', '🪵', '🌿', '🦊', '🦋'];
    } else { 
      // CÉU
      assets = ['☁️', '☁️', '✨', '🕊️', '🌈', '⭐', '🪐', '🦅'];
    }

    // Aumentamos para 20 itens para preencher bem
    int itemCount = 10; 
    double segmentHeight = height / itemCount;

    for (int i = 0; i < itemCount; i++) {
      String asset = assets[random.nextInt(assets.length)];
      
      // Tamanho variado
      double size = 22 + random.nextDouble() * 24; 

      // Posição Y: Rigorosamente segmentada para não encavalar verticalmente
      double topPos = (i * segmentHeight) + (random.nextDouble() * (segmentHeight * 0.5));

      // LÓGICA PING-PONG:
      // Se 'i' é par, vai pra Esquerda. Se ímpar, vai pra Direita.
      // Isso impede que fiquem todos do mesmo lado.
      bool placeOnLeft = (i % 2 == 0);
      
      // Ajuste fino para inverter a ordem a cada nível para não ficar monótono
      if (level % 2 != 0) placeOnLeft = !placeOnLeft;

      double leftPos;
      if (placeOnLeft) {
        // Lado Esquerdo Extremo (0% a 18% da tela) - Longe da estrada
        leftPos = random.nextDouble() * (width * 0.18);
      } else {
        // Lado Direito Extremo (82% a 100% da tela) - Longe da estrada
        leftPos = (width * 0.82) + (random.nextDouble() * (width * 0.18));
      }

      // Rotação aleatória
      double rotation = (random.nextDouble() - 0.5) * 0.5;

      items.add(Positioned(
        top: topPos,
        left: leftPos,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: 0.7, 
            child: Text(
              asset,
              style: TextStyle(
                fontSize: size,
                decoration: TextDecoration.none,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  )
                ]
              ),
            ),
          ),
        ),
      ));
    }
    return Stack(children: items);
  }

  
  Widget _buildNodeWidget(Map<String, dynamic> node) {
    final bool isLocked = node['isLocked'] ?? false;
    final double scale = node['scale'] ?? 1.0;
    final Color color = node['color'];
    final double progress = node['progress'];

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Deslocamento de fase para não flutuarem todos juntos (baseado no ID)
        final offsetPhase = node['id'].hashCode % 10;
        final dy = 6 * math.sin((_floatController.value * 2 * math.pi) + offsetPhase);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: GestureDetector(
        onTap: node['onTap'],
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 70 * scale, width: 70 * scale,
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey[300] : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: (isLocked ? Colors.grey : color).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                ),
                if (!isLocked)
                  CircularPercentIndicator(
                    radius: 38.0 * scale,
                    lineWidth: 5.0,
                    percent: progress,
                    backgroundColor: Colors.grey[200]!,
                    progressColor: color,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                  ),
                Icon(
                  node['icon'], 
                  color: isLocked ? Colors.grey[500] : color, 
                  size: (isLocked ? 28 : 30) * scale
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0,2))],
                border: Border.all(color: isLocked ? Colors.grey[300]! : color.withOpacity(0.2), width: 1)
              ),
              child: Column(
                children: [
                  Text(node['label'], style: TextStyle(fontWeight: FontWeight.bold, color: isLocked ? Colors.grey : Colors.black87, fontSize: 11)),
                  if (!isLocked)
                    Text(node['sub'], style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- UI PRINCIPAL (STACK MAPA + HUD) ---
  @override
  Widget build(BuildContext context) {
    final levelInfo = _calculateLevelInfo();
    final biomeColors = levelInfo['biomeColors'] as List<Color>;
    final nodes = _generateNodes(); // Gera os dados atuais

    return Scaffold(
      backgroundColor: biomeColors[0],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: arcaPurple))
        : Stack(
            children: [
              // CAMADA 1: MAPA ZIG-ZAG DINÂMICO
              LayoutBuilder(
                builder: (context, constraints) {
                  // Define altura baseada na quantidade de nós (Espaço fixo entre eles)
                  const double nodeSpacing = 160.0;
                  final double totalHeight = (nodes.length * nodeSpacing) + 300; // + Header e Footer padding

                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: totalHeight,
                      child: Stack(
                        children: [
                          // 0. CAMADA DE FUNDO (Cores do Bioma)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                  colors: biomeColors,
                                )
                              ),
                            ),
                          ),

                          // 0.5. DECORAÇÕES (Cactos, Nuvens, etc)
                          Positioned.fill(
                            child: _buildBiomeDecorations(levelInfo['level'], constraints.maxWidth, totalHeight)
                          ),

                          // 1. ESTRADA CUSTOMIZADA (Cor dinâmica)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DynamicZigZagPainter(
                                nodes: nodes, 
                                spacing: nodeSpacing,
                                screenWidth: constraints.maxWidth,
                                pathColor: _getPathColor(levelInfo['level']), // <--- COR NOVA
                              ),
                            ),
                          ),

                          // 2. Renderização dos Nós (Baseada na lista)
                          ...List.generate(nodes.length, (index) {
                            final node = nodes[index];
                            // Cálculo da posição Y (De baixo para cima)
                            // Index 0 é a base. Adicionamos padding inferior.
                            final double bottomPos = 120.0 + (index * nodeSpacing);
                            
                            // Cálculo da posição X (Alinhamento relativo ao centro)
                            final double centerX = constraints.maxWidth / 2;
                            // Amplitude do ZigZag = 100px para cada lado
                            final double leftPos = centerX + ((node['alignment'] as double) * 200) - 35; // -35 para centralizar o ícone de 70px

                            return Positioned(
                              bottom: bottomPos,
                              left: leftPos,
                              child: _buildNodeWidget(node), // Usa o método refatorado abaixo
                            );
                          }),
                          
                          // Elementos Decorativos (Nuvens/Sol) podem ser adicionados aqui com Positioned relativos se quiser
                        ],
                      ),
                    ),
                  );
                }
              ),

              // CAMADA 2: HEADER FIXO (Mantido)
              Positioned(
                top: 0, left: 0, right: 0,
                child: _buildGamifiedHeader(levelInfo),
              ),
            ],
          ),
      
      // Botão Flutuante (Mantido)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAchievementsModal(),
        backgroundColor: arcaPurple,
        icon: const Icon(Icons.emoji_events, color: arcaYellow),
        label: const Text("Sala do Tesouro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
  
  // --- HEADER FIXO (Correção do Overflow) ---
  Widget _buildGamifiedHeader(Map<String, dynamic> info) {
    return Container(
      // [FIX] Altura ajustada
      height: 170, 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar de Nível com Sombra Manual
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: arcaOrange.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]
                ),
                child: CircularPercentIndicator(
                  radius: 34.0,
                  lineWidth: 6.0,
                  percent: info['percent'],
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${info['level']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: arcaPurple)),
                      const Text("NÍVEL", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  progressColor: arcaOrange,
                  backgroundColor: Colors.grey[200]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                ),
              ),
              const SizedBox(width: 16),
              
              // Texto e Barra (Flexible para não estourar)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sua Jornada", 
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info['rankName'], 
                      style: const TextStyle(color: arcaBlack, fontSize: 22, fontWeight: FontWeight.w900),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8.0,
                        percent: info['percent'],
                        backgroundColor: Colors.grey[200]!,
                        progressColor: arcaPurple,
                        barRadius: const Radius.circular(4),
                        animation: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Faltam ${info['nextGoal'] - info['total']} leituras para subir", 
                      style: TextStyle(color: arcaPurple.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL: HUB DE LEITURA (Mantido da V5.2) ---
  void _openReadingHub({int initialTab = 0}) {
    _modalTabController.index = initialTab;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.5))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                children: [
                  const Text("Desafios de Leitura", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: arcaBlack, letterSpacing: -0.5)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.black54, size: 20)
                    )
                  )
                ],
              ),
            ),
            TabBar(
              controller: _modalTabController,
              labelColor: arcaPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: arcaPurple,
              indicatorWeight: 4,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              tabs: const [
                Tab(text: "Em Andamento"),
                Tab(text: "Descobrir"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _modalTabController,
                children: [
                  _buildMyJourneysTab(), // Widgets antigos
                  _buildDiscoverTab(),   // Widgets antigos
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DO HUB (Copiados da V5.2) ---

  Widget _buildMyJourneysTab() {
    if (_myActivePlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Nenhuma jornada ativa", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            TextButton(
              onPressed: () => _modalTabController.animateTo(1),
              child: const Text("COMEÇAR UMA AGORA", style: TextStyle(color: arcaOrange, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _myActivePlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildActiveJourneyCard(_myActivePlans[index]),
    );
  }

  Widget _buildActiveJourneyCard(Map<String, dynamic> activePlan) {
    final plan = activePlan['reading_plans'];
    final int currentDay = activePlan['current_day'];
    final int totalDays = plan['duration_days'];
    final double progress = (currentDay - 1) / totalDays;
    final String imageUrl = plan['cover_image_url'] ?? '';

    return Container(
      height: 140, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            child: SizedBox(
              width: 110,
              height: double.infinity,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, placeholder: (c, u) => Container(color: Colors.grey[100]), errorWidget: (c, u, e) => Container(color: arcaPurple.withOpacity(0.1)))
                  : Container(color: arcaPurple.withOpacity(0.1)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(plan['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      InkWell(
                        onTap: () => _markDayComplete(activePlan['id'], currentDay),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                          child: const Row(
                            children: [
                             Icon(Icons.check, color: Colors.grey, size: 14),
                             SizedBox(width: 4),
                             Text("Marcar", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))
                            ],
                          )
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text("Dia $currentDay", style: const TextStyle(color: arcaPurple, fontWeight: FontWeight.bold)),
                      Text(" de $totalDays", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 8.0,
                    percent: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: Colors.grey[100]!,
                    progressColor: arcaOrange,
                    barRadius: const Radius.circular(4),
                    animation: true,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _readDay(activePlan),
                    child: const Row(
                      children: [
                        Text("CONTINUAR LEITURA", style: TextStyle(color: arcaPurple, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                        Icon(Icons.arrow_forward_rounded, color: arcaPurple, size: 16)
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40, top: 20), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_featuredPlans.isNotEmpty) _buildHeroSection(_featuredPlans.first),
          const SizedBox(height: 32),
          _buildSectionTitle("Desafios de Tempo"),
          _buildHorizontalList(_allPlans.where((p) => [365, 180, 90].contains(p['duration_days'])).toList()),
          const SizedBox(height: 32),
          _buildSectionTitle("Emocional & Espiritual"),
          _buildHorizontalList(_allPlans.where((p) => ![365, 180, 90].contains(p['duration_days'])).toList()),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> plan) {
    return InkWell(
      onTap: () => _showPlanDetails(plan),
      child: Container(
        height: 240, 
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: CachedNetworkImageProvider(plan['cover_image_url'] ?? ''), fit: BoxFit.cover),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: arcaOrange, borderRadius: BorderRadius.circular(8)),
                child: const Text("EM DESTAQUE 🔥", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 12),
              Text(plan['title'], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 8),
               Text("${plan['duration_days']} Dias de Jornada", style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> plans) {
    return SizedBox(
      height: 210, 
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return InkWell(
            onTap: () => _showPlanDetails(plan),
            child: SizedBox(
              width: 140, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(imageUrl: plan['cover_image_url'] ?? '', fit: BoxFit.cover, placeholder: (c, u) => Container(color: Colors.grey[100]), errorWidget: (c, u, e) => Container(color: arcaPurple.withOpacity(0.1))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(plan['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text("${plan['duration_days']} Dias", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: arcaBlack)),
    );
  }

  void _showPlanDetails(Map<String, dynamic> plan) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.5))),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(imageUrl: plan['cover_image_url'] ?? '', fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.grey[200])),
                ),
              ),
              const SizedBox(height: 24),
              Text(plan['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: arcaBlack, height: 1.1), textAlign: TextAlign.center),
              const SizedBox(height: 10),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: arcaPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("${plan['duration_days']} DIAS", style: const TextStyle(color: arcaPurple, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
              ),
              const SizedBox(height: 24),
              Text(plan['description'] ?? "Sem descrição.", style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey[700]), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: arcaOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                    shadowColor: arcaOrange.withOpacity(0.5)
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _subscribeToPlan(plan['id']);
                  },
                  child: const Text("COMEÇAR ESTA JORNADA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAchievementsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(30),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 60, color: arcaOrange),
            SizedBox(height: 20),
            Text("Galeria de Conquistas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Em breve suas medalhas estarão aqui!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
    );
  }

  // --- HELPERS (Subscribe/Complete/Read/Notify) ---
  Future<void> _subscribeToPlan(int planId) async {
    Navigator.pop(context); 
    final exists = _myActivePlans.any((p) => p['plan_id'] == planId);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Você já está fazendo este plano!")));
      _openReadingHub(initialTab: 0); 
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: arcaPurple)));
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      await supabase.from('user_active_plans').insert({'user_id': user.id, 'plan_id': planId, 'current_day': 1, 'start_date': DateTime.now().toIso8601String()});
      await supabase.from('user_stats').upsert({'user_id': user.id}, onConflict: 'user_id');
      await _loadData(); 
      if (mounted) {
        Navigator.pop(context); 
        _showNotificationTimePicker(); 
        _openReadingHub(initialTab: 0);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _markDayComplete(int activePlanId, int dayNumber) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Atualiza o plano de leitura no banco
      await supabase.from('user_active_plans').update({
        'current_day': dayNumber + 1,
        'last_read_at': DateTime.now().toIso8601String()
      }).eq('id', activePlanId);

      // 2. [CORREÇÃO] Chama a função correta de Streak e XP
      // (Substituindo a antiga 'increment_streak' que não existe mais)
      final response = await supabase.rpc('handle_user_activity', params: {
        'p_activity_type': 'PLANO_LEITURA'
      });

      // 3. Atualiza UI com os dados reais retornados do banco
      if (mounted) {
        setState(() {
          // Atualiza progresso do plano visualmente
          final index = _myActivePlans.indexWhere((p) => p['id'] == activePlanId);
          if (index != -1) {
            _myActivePlans[index]['current_day'] = dayNumber + 1;
          }
          
          // Atualiza Streak e XP com a resposta do RPC
          if (response != null) {
            _streak = response['streak'] ?? _streak + 1;
            // Se o usuário ganhou XP, subimos o contador visualmente
            _totalDevotionalsRead += 1; 
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Leitura concluída! 🔥 Continue firme no propósito!"), 
            backgroundColor: arcaNeonGreen,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
      
      // Recarrega em background para garantir sincronia total
      _loadData(); 

    } catch (e) {
      debugPrint("Erro ao completar: $e");
      _loadData(); // Reverte em caso de erro
    }
  }

  Future<void> _readDay(Map<String, dynamic> activePlan) async {
    Navigator.pop(context); 
    final int currentDay = activePlan['current_day'];
    final int planId = activePlan['plan_id'];
    final resp = await supabase.from('plan_days').select().eq('plan_id', planId).eq('day_number', currentDay).maybeSingle();
    if (resp != null && mounted) {
      context.findAncestorStateOfType<MainScreenState>()?.jumpToBible(resp['start_book_abbrev'], resp['start_chapter'], 1, activePlan['id'], currentDay);
    }
  }

  void _showNotificationTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0), builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: arcaPurple)), child: child!));
    if (picked != null) await NotificationService().scheduleDailyReminder(picked);
  }
}

// --- PAINTER (Estrada Sinuosa Ajustada para 1200px) ---
class DynamicZigZagPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final double spacing;
  final double screenWidth;
  final Color pathColor; // <--- NOVO PARAMETRO

  // Atualize o construtor
  DynamicZigZagPainter({
    required this.nodes, 
    required this.spacing, 
    required this.screenWidth,
    this.pathColor = Colors.white, // Valor default
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ESTILO DA ESTRADA
    final paint = Paint()
      ..color = pathColor.withOpacity(0.8) // Usa a cor do bioma (Terra/Ouro)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round;
      
    // Se for o CÉU (Ouro), adicionamos um brilho extra (Shadow)
    if (pathColor == const Color(0xFFFFD700)) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 10);
    }

    // Borda da estrada (Contraste)
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 70 // Ligeiramente maior para fazer a borda
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Helper para calcular coordenadas X e Y baseadas no índice e alinhamento
    // Nota: O Y cresce para baixo no Canvas, mas nossa lista (Index 0) está na base visualmente.
    // Então Index 0 = Y alto (perto de size.height).
    
    Offset getPoint(int index) {
      final double bottomPos = 120.0 + (index * spacing);
      final double y = size.height - bottomPos - 35; // 35 = metade do ícone (ajuste fino)
      
      final double alignment = nodes[index]['alignment'];
      final double centerX = screenWidth / 2;
      final double x = centerX + (alignment * 200);
      
      return Offset(x, y);
    }

    if (nodes.isEmpty) return;

    // Move para o primeiro ponto
    path.moveTo(getPoint(0).dx, getPoint(0).dy + 80); // Começa um pouco abaixo do primeiro nó
    path.lineTo(getPoint(0).dx, getPoint(0).dy);

    for (int i = 0; i < nodes.length - 1; i++) {
      final p1 = getPoint(i);
      final p2 = getPoint(i + 1);

      // Curva de Bézier suave entre os pontos
      final controlX = (p1.dx + p2.dx) / 2;
      final controlY = (p1.dy + p2.dy) / 2;

      path.quadraticBezierTo(p1.dx, controlY, controlX, controlY);
      path.quadraticBezierTo(p2.dx, controlY, p2.dx, p2.dy);
    }
    
    // Desenha uma linha final subindo para o "céu" após o último nó
    final lastIdx = nodes.length - 1;
    path.lineTo(getPoint(lastIdx).dx, getPoint(lastIdx).dy - 100);

    // Desenha borda primeiro, depois a estrada colorida
    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}