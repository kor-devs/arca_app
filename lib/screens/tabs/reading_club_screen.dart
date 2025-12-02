// lib/screens/tabs/reading_club_screen.dart (V5.2 - Final Fix)
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Usado no LinearPercentIndicator
import 'package:cached_network_image/cached_network_image.dart'; 
import '../../main.dart';
import '../../constants.dart';
import '../main_screen.dart';
import '../../services/notification_service.dart';

class ReadingClubScreen extends StatefulWidget {
  const ReadingClubScreen({super.key});

  @override
  State<ReadingClubScreen> createState() => _ReadingClubScreenState();
}

class _ReadingClubScreenState extends State<ReadingClubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _myActivePlans = []; 
  List<Map<String, dynamic>> _featuredPlans = []; 
  List<Map<String, dynamic>> _allPlans = []; 
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Meus Planos
      final activeResp = await supabase
          .from('user_active_plans')
          .select('*, reading_plans(*)')
          .eq('user_id', user.id)
          .eq('is_completed', false)
          .order('last_read_at', ascending: false);

      _myActivePlans = List<Map<String, dynamic>>.from(activeResp);

      // 2. Vitrine
      final plansResp = await supabase
          .from('reading_plans')
          .select()
          .order('is_featured', ascending: false);
      
      _allPlans = List<Map<String, dynamic>>.from(plansResp);
      _featuredPlans = _allPlans.where((p) => p['is_featured'] == true).toList();

      // 3. Stats
      final statsResp = await supabase.from('user_stats').select('current_streak').eq('user_id', user.id).maybeSingle();
      if (statsResp != null) {
        _streak = statsResp['current_streak'] ?? 0;
      }

    } catch (e) {
      debugPrint("Erro ao carregar: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- AÇÕES ---

  Future<void> _subscribeToPlan(int planId) async {
    final exists = _myActivePlans.any((p) => p['plan_id'] == planId);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Você já está fazendo este plano!")));
      _tabController.animateTo(0); 
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('user_active_plans').insert({
        'user_id': user.id,
        'plan_id': planId,
        'current_day': 1,
        'start_date': DateTime.now().toIso8601String(),
      });

      await supabase.from('user_stats').upsert({'user_id': user.id}, onConflict: 'user_id');

      if (mounted) {
         _showNotificationTimePicker();
      }

      await _loadData();
      _tabController.animateTo(0); 

    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _markDayComplete(int activePlanId, int dayNumber) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('user_active_plans').update({
        'current_day': dayNumber + 1,
        'last_read_at': DateTime.now().toIso8601String()
      }).eq('id', activePlanId);

      await supabase.rpc('increment_streak', params: {'user_uuid': user.id});
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Leitura concluída! 🔥"),
            backgroundColor: arcaNeonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _loadData(); 
    }
  }

  Future<void> _readDay(Map<String, dynamic> activePlan) async {
    final int currentDay = activePlan['current_day'];
    final int planId = activePlan['plan_id'];
    
    final resp = await supabase
        .from('plan_days')
        .select()
        .eq('plan_id', planId)
        .eq('day_number', currentDay)
        .maybeSingle();

    if (resp != null && mounted) {
      final mainScreen = context.findAncestorStateOfType<MainScreenState>();
      mainScreen?.jumpToBible(
        resp['start_book_abbrev'], 
        resp['start_chapter'], 
        1,
        activePlan['id'], 
        currentDay
      );
    }
  }

  void _showNotificationTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: arcaPurple),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await NotificationService().scheduleDailyReminder(picked);
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Jornadas", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 26)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: arcaOrange, size: 20),
                const SizedBox(width: 4),
                Text("$_streak", style: const TextStyle(color: arcaOrange, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: arcaPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: arcaPurple,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: "Em Andamento"),
            Tab(text: "Descobrir"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: arcaPurple))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildMyJourneysTab(),
              _buildDiscoverTab(),
            ],
          ),
    );
  }

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
              onPressed: () => _tabController.animateTo(1),
              child: const Text("COMEÇAR UMA AGORA", style: TextStyle(color: arcaOrange, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _myActivePlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Imagem da Esquerda
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: SizedBox(
              width: 100,
              height: double.infinity,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl, 
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(color: arcaPurple.withValues(alpha: 0.1), child: const Icon(Icons.image, color: Colors.grey)),
                    )
                  : Container(color: arcaPurple.withValues(alpha: 0.1), child: const Icon(Icons.image, color: Colors.grey)),
            ),
          ),
          
          // Conteúdo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(plan['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      
                      // Botão de Check Manual (Funcional)
                      InkWell(
                        onTap: () => _markDayComplete(activePlan['id'], currentDay),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.check_circle_outline, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Dia $currentDay de $totalDays", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  
                  // [CORREÇÃO]: Uso do LinearPercentIndicator do pacote para justificar o import
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 6.0,
                    percent: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: Colors.grey[100]!,
                    progressColor: arcaOrange,
                    barRadius: const Radius.circular(3),
                    animation: true,
                    animationDuration: 800,
                  ),
                  
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _readDay(activePlan),
                    child: const Row(
                      children: [
                        Text("CONTINUAR", style: TextStyle(color: arcaPurple, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                        Icon(Icons.chevron_right, color: arcaPurple, size: 16)
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

  // ABA 2: DESCOBRIR
  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40), // [FIX] Removido padding top/horizontal
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
        height: 280, // Altura aumentada para impacto
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 0), // [FIX] Margem zero (Full Width)
        decoration: BoxDecoration(
          // Removido borderRadius para colar nas bordas se for full width, 
          // ou use BorderRadius.vertical(bottom: Radius.circular(24)) para efeito "Saindo do Header"
          image: DecorationImage(
            image: CachedNetworkImageProvider(plan['cover_image_url'] ?? ''),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Gradiente sobreposto para garantir leitura do texto
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8), // Mais escuro embaixo
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: arcaOrange, borderRadius: BorderRadius.circular(8)),
                child: const Text("MAIS POPULAR 🔥", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
              const SizedBox(height: 12),
              Text(plan['title'], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text("${plan['duration_days']} Dias de Propósito", style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> plans) {
    return SizedBox(
      height: 190, 
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return InkWell(
            onTap: () => _showPlanDetails(plan),
            child: SizedBox(
              width: 130, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                         imageUrl: plan['cover_image_url'] ?? '',
                         fit: BoxFit.cover,
                         placeholder: (context, url) => Container(color: Colors.grey[200]),
                         errorWidget: (context, url, error) => Container(color: arcaPurple.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(plan['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text("${plan['duration_days']} Dias", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
  
  void _showPlanDetails(Map<String, dynamic> plan) {
     showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem Grande no Modal (Opção Visual Rica)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CachedNetworkImage(
                     imageUrl: plan['cover_image_url'] ?? '',
                     fit: BoxFit.cover,
                     errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(plan['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: arcaPurple), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${plan['duration_days']} dias", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Text(plan['description'] ?? "Sem descrição.", style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: arcaOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _subscribeToPlan(plan['id']);
                  },
                  child: const Text("COMEÇAR JORNADA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}