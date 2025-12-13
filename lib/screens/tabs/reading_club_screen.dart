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
  final int _totalPlansCompleted = 0;

  // 1. Base: Progresso do Plano Atual
  double _getPlansProgress() {
    if (_myActivePlans.isEmpty) return 0.0;
    final plan = _myActivePlans.first;
    final total = plan['reading_plans']['duration_days'] as int;
    final current = plan['current_day'] as int;
    return (current / total).clamp(0.0, 1.0);
  }

  // 2. Meio: Intimidade (Meta: Streak de 30 dias)
  double _getDevotionalProgress() {
    return (_streak / 7.0).clamp(0.0, 1.0);
  }

  // 3. Esquerda: Semear (Meta: 20 compartilhamentos)
  double _getShareProgress() {
    return (_totalShares / 20.0).clamp(0.0, 1.0);
  }

  // 4. Direita: Evangelista (Meta: 10 convites)
  double _getInviteProgress() {
    return (_totalInvites / 10.0).clamp(0.0, 1.0);
  }

  // --- CONTROLLERS ---
  late AnimationController _floatController;
  late TabController _modalTabController;

  // Níveis de Gamificação (XP necessário para subir)
  final List<int> _levelMilestones = [5, 15, 30, 60, 150, 365];

  @override
  void initState() {
    super.initState();
    _modalTabController = TabController(length: 2, vsync: this);
    
    // Animação de "respiração" (flutuação) dos ícones do mapa
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

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

      // 2. Stats com Proteção (Try/Catch específico para colunas novas)
      try {
        // Tenta buscar tudo. Se 'total_shares' não existir no banco, vai cair no catch.
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
        debugPrint("Aviso: Colunas novas de stats ainda não existem. Usando 0. ($e)");
        // Fallback seguro
        _streak = 0; 
        _totalDevotionalsRead = 0;
      }

    } catch (e) {
      debugPrint("Erro data: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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

  List<Color> _getBiomeColors(int level) {
    // Retorna gradiente de fundo baseado no nível
    if (level <= 2) return [const Color(0xFFFFF8E1), const Color(0xFFFFE0B2)]; // Deserto (Areia)
    if (level <= 4) return [const Color(0xFFF1F8E9), const Color(0xFFC8E6C9)]; // Floresta
    return [const Color(0xFFF3E5F5), const Color(0xFFD1C4E9)]; // Celestial
  }

  
  // --- WIDGET DE NÓ ABSOLUTO (Correção do posicionamento) ---
  Widget _buildAbsoluteNode({
    required double top,
    required double left,
    required IconData icon,
    required String label,
    required String subLabel,
    required double progress, // 0.0 a 1.0 (Define quanto da borda pinta)
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
    String? lockedMessage,
    double scale = 1.0,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final dy = 6 * math.sin(_floatController.value * 2 * math.pi);
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: GestureDetector(
          onTap: isLocked 
            ? () { if (lockedMessage != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lockedMessage), backgroundColor: Colors.grey[800])); } 
            : onTap,
          child: Column(
            children: [
              // Ícone + Borda de Progresso
              Stack(
                alignment: Alignment.center,
                children: [
                  // Fundo Branco
                  Container(
                    height: 70 * scale, width: 70 * scale,
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey[300] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: (isLocked ? Colors.grey : color).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                  ),
                  // Borda de Progresso (Se não bloqueado)
                  if (!isLocked)
                    CircularPercentIndicator(
                      radius: 38.0 * scale,
                      lineWidth: 5.0,
                      percent: progress,
                      backgroundColor: Colors.grey[200]!,
                      progressColor: color, // A cor do nó preenche a borda
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                    ),
                  // O Ícone
                  isLocked 
                    ? Icon(Icons.lock, color: Colors.grey[500], size: 28 * scale)
                    : Icon(icon, color: color, size: 30 * scale),
                ],
              ),
              const SizedBox(height: 10),
              // Placa de Texto
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
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isLocked ? Colors.grey : Colors.black87, fontSize: 11)),
                    if (!isLocked && subLabel.isNotEmpty)
                      Text(subLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- UI PRINCIPAL (STACK MAPA + HUD) ---
  @override
  Widget build(BuildContext context) {
    final levelInfo = _calculateLevelInfo();
    final biomeColors = levelInfo['biomeColors'] as List<Color>;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double mapHeight = 1400; // Altura para caber tudo

    return Scaffold(
      backgroundColor: biomeColors[0],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: arcaPurple))
        : Stack(
            children: [
              // CAMADA 1: MAPA ROLÁVEL
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  height: mapHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: biomeColors,
                    )
                  ),
                  child: Stack(
                    children: [
                      // Estrada
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GamePathPainter(
                            pathColor: Colors.white.withOpacity(0.5),
                            borderColor: Colors.black.withOpacity(0.05)
                          ),
                        ),
                      ),
                      
                      // Base (Deserto/Início)
                      Positioned(top: mapHeight * 0.85, right: 30, child: Icon(Icons.park, color: Colors.green.withOpacity(0.3), size: 50)),
                      Positioned(top: mapHeight * 0.92, left: 40, child: Icon(Icons.grass, color: Colors.green.withOpacity(0.3), size: 30)),
                      
                      // Meio (Floresta)
                      Positioned(top: mapHeight * 0.60, left: 20, child: Icon(Icons.park, color: Colors.green.withOpacity(0.4), size: 60)),
                      Positioned(top: mapHeight * 0.45, right: 50, child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.5), size: 80)),
                      
                      // Topo (Céu)
                      Positioned(top: mapHeight * 0.25, left: 60, child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.6), size: 60)),
                      Positioned(
                        top: mapHeight * 0.05, left: 0, right: 0,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wb_sunny, color: Colors.amber.withOpacity(0.3), size: 100),
                              const SizedBox(height: 10),
                              Text("RUMO AO ETERNO", style: TextStyle(fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold, color: arcaPurple.withOpacity(0.4))),
                            ],
                          ),
                        ),
                      ),

                      // --- OS 5 NÓS ---

                      // 1. BASE: PLANOS BÍBLICOS
                      _buildAbsoluteNode(
                        top: mapHeight * 0.88, left: screenWidth * 0.15,
                        icon: Icons.auto_stories,
                        label: "Planos Bíblicos",
                        subLabel: _myActivePlans.isNotEmpty 
                            ? "Em andamento" 
                            : "$_totalPlansCompleted Concluídos",
                        progress: _getPlansProgress(),
                        color: arcaOrange,
                        onTap: () => _openReadingHub(initialTab: 0),
                      ),

                      // 2. MEIO: INTIMIDADE (Streak)
                      _buildAbsoluteNode(
                        top: mapHeight * 0.70, left: screenWidth * 0.65,
                        icon: Icons.local_fire_department,
                        label: "Intimidade",
                        subLabel: "$_streak / 7 Dias",
                        progress: _getDevotionalProgress(),
                        color: Colors.redAccent,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mantenha o fogo aceso! Meta: 30 dias."))),
                      ),

                      // 3. ESQUERDA: SEMEAR (Compartilhamento)
                      _buildAbsoluteNode(
                        top: mapHeight * 0.50, left: screenWidth * 0.18,
                        icon: Icons.share,
                        label: "Semear",
                        subLabel: "$_totalShares / 20",
                        progress: _getShareProgress(),
                        color: Colors.blue,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compartilhe versículos para completar!"))),
                      ),

                      // 4. DIREITA: EVANGELISTA (Convites)
                      _buildAbsoluteNode(
                        top: mapHeight * 0.30, left: screenWidth * 0.60,
                        icon: Icons.group_add,
                        label: "Evangelista",
                        subLabel: "$_totalInvites / 10",
                        progress: _getInviteProgress(),
                        color: Colors.purpleAccent,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Traga amigos para a Arca!"))),
                      ),

                      // 5. TOPO: CONTEÚDO BÔNUS (Bloqueado)
                      _buildAbsoluteNode(
                        top: mapHeight * 0.10, left: screenWidth * 0.38,
                        icon: Icons.diamond,
                        label: "Conteúdo Bônus",
                        subLabel: "Nível 5",
                        progress: 0.0,
                        color: arcaPurple,
                        scale: 1.3,
                        isLocked: levelInfo['level'] < 5,
                        lockedMessage: "Alcance o Nível 5 (Embaixador) para desbloquear.",
                        onTap: () {},
                      ),

                      SizedBox(height: mapHeight) // Espaço final
                    ],
                  ),
                ),
              ),

              // CAMADA 2: HEADER FIXO (Mantido da versão anterior funcional)
              Positioned(
                top: 0, left: 0, right: 0,
                child: _buildGamifiedHeader(levelInfo),
              ),
            ],
          ),
      
      // BOTÃO FLUTUANTE: SALA DO TESOURO
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
      setState(() {
        final index = _myActivePlans.indexWhere((p) => p['id'] == activePlanId);
        if (index != -1) _myActivePlans[index]['current_day'] = dayNumber + 1;
        _streak += 1; _totalDevotionalsRead += 1; 
      });
      await supabase.from('user_active_plans').update({'current_day': dayNumber + 1, 'last_read_at': DateTime.now().toIso8601String()}).eq('id', activePlanId);
      await supabase.rpc('increment_streak', params: {'user_uuid': user.id});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Leitura concluída! 🔥"), backgroundColor: arcaNeonGreen));
      _loadData(); 
    } catch (e) { _loadData(); }
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
class GamePathPainter extends CustomPainter {
  final Color pathColor;
  final Color borderColor;
  GamePathPainter({required this.pathColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = pathColor..style = PaintingStyle.stroke..strokeWidth = 70..strokeCap = StrokeCap.round;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 80..strokeCap = StrokeCap.round;

    final path = Path();
    // Início (Baixo Esquerda - Nó 1)
    path.moveTo(size.width * 0.20, size.height * 0.95);
    
    // Curva para Nó 2 (Meio Direita)
    path.cubicTo(
      size.width * 0.90, size.height * 0.85, 
      size.width * 0.85, size.height * 0.75, 
      size.width * 0.65, size.height * 0.70 
    );

    // Curva para Nó 3 (Meio Esquerda)
    path.cubicTo(
      size.width * 0.30, size.height * 0.65, 
      size.width * 0.10, size.height * 0.55, 
      size.width * 0.18, size.height * 0.50 
    );

    // Curva para Nó 4 (Cima Direita)
    path.cubicTo(
      size.width * 0.50, size.height * 0.45, 
      size.width * 0.80, size.height * 0.35, 
      size.width * 0.60, size.height * 0.30 
    );

    // Reta Final para Nó 5 (Topo Centro)
    path.cubicTo(
      size.width * 0.40, size.height * 0.25, 
      size.width * 0.38, size.height * 0.15, 
      size.width * 0.38, size.height * 0.10 
    );

    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}