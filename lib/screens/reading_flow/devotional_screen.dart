// lib/screens/reading_flow/devotional_screen.dart (V2.1 - Navegação Corrigida)
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../constants.dart';
import '../../models/devotional_model.dart';

class DevotionalScreen extends StatefulWidget {
  final void Function(String abbrev, int chapter, int verse)? onJumpToBible;
  final int? devotionalId;
  final Devotional? initialData;

  const DevotionalScreen({
    super.key, 
    this.onJumpToBible,
    this.devotionalId, 
    this.initialData,
  });

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  bool _isLoading = true;
  Devotional? _devotional;
  bool _isSaving = false; 
  
  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _devotional = widget.initialData;
      _isLoading = false;
    } else if (widget.devotionalId != null) {
      _fetchSpecificDevotional(widget.devotionalId!);
    } else {
      _fetchDailyDevotional(); 
    }
  }

  Future<void> _fetchSpecificDevotional(int id) async {
    setState(() { _isLoading = true; });
    try {
      final response = await supabase
          .from('devotionals')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (mounted && response != null) {
        setState(() {
          _devotional = Devotional.fromJson(response);
          _isLoading = false;
        });
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDailyDevotional() async {
    final now = DateTime.now();
    final diff = now.difference(DateTime(now.year, 1, 1, 0, 0));
    final int realDayOfYear = diff.inDays + 1;

    setState(() { _isLoading = true; });

    try {
      var response = await supabase
          .from('devotionals')
          .select()
          .eq('day_of_year', realDayOfYear)
          .maybeSingle();

      if (response == null) {
        response = await supabase
            .from('devotionals')
            .select()
            .limit(1)
            .maybeSingle();
      }

      if (mounted && response != null) {
        setState(() {
          _devotional = Devotional.fromJson(response as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    if (_devotional == null || _isSaving) return;
    
    setState(() { _isSaving = true; });
    
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('user_devotionals').upsert({
          'user_id': user.id,
          'devotional_id': _devotional!.id,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id, devotional_id'); 
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Amém! Devocional salvo no seu histórico.", style: TextStyle(color: arcaBlack, fontWeight: FontWeight.bold)),
            backgroundColor: arcaNeonGreen,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao salvar progresso."))
        );
        setState(() { _isSaving = false; });
      }
    }
  }

  void _shareDevotional() {
    if (_devotional == null) return;
    final text = """
📖 *Devocional - ${_devotional!.title}*

"${_devotional!.verseText}"
_${_devotional!.verseReference}_

📚 *O Estudo:*
 ${_devotional!.theologyContent}

💡 *Reflexão:*
${_devotional!.reflectionContent}

Arca, sua companheira na jornada espiritual!
🔗 arca.kordevs.com
""";
    Share.share(text);
  }

  // [CORRIGIDO] Método de Navegação
  void _navigateToBible() {
    if (_devotional == null || widget.onJumpToBible == null) return;
    
    // Fecha a tela de devocional
    Navigator.pop(context);
    
    // Chama o callback passando os dados corretos do Model
    widget.onJumpToBible!(
      _devotional!.bookAbbrev,
      _devotional!.chapter,
      _devotional!.verseNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: arcaPurple)));
    }
    
    if (_devotional == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: arcaPurple),
        body: Center(
          child: ElevatedButton(onPressed: _fetchDailyDevotional, child: const Text("Tentar Novamente")),
        )
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: arcaPurple,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Voltar',
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: _shareDevotional,
                  tooltip: 'Compartilhar',
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _devotional!.theme.toUpperCase(), 
                style: const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)]
                )
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                   CachedNetworkImage(
                     imageUrl: _devotional!.imageUrl,
                     fit: BoxFit.cover,
                     placeholder: (context, url) => Container(color: arcaPurple),
                     errorWidget: (context, url, error) => const Icon(Icons.error),
                   ),
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [
                           Colors.black.withOpacity(0.6), 
                           Colors.transparent,            
                           Colors.transparent,
                           Colors.black.withOpacity(0.8)  
                         ],
                         stops: const [0.0, 0.2, 0.6, 1.0],
                       )
                     ),
                   )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     _devotional!.title, 
                     style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       const Icon(Icons.access_time, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text(_devotional!.duration, style: const TextStyle(color: Colors.grey)),
                       const Spacer(),
                       const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text(_devotional!.author, style: const TextStyle(color: Colors.grey)),
                     ],
                   ),
                   const SizedBox(height: 24),
                   
                   // Versículo em Destaque
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: arcaPurple.withOpacity(0.05),
                       borderRadius: BorderRadius.circular(12),
                       border: Border(left: BorderSide(color: arcaPurple, width: 4))
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           "\"${_devotional!.verseText}\"",
                           style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16, height: 1.4, color: Colors.black87)
                         ),
                         const SizedBox(height: 10),
                         Text(
                           _devotional!.verseReference, 
                           style: const TextStyle(fontWeight: FontWeight.bold, color: arcaPurple)
                         ),
                         const SizedBox(height: 12),
                         
                         // [CORRIGIDO] Botão de Navegação para Bíblia
                         InkWell(
                           onTap: _navigateToBible, // Usa a função corrigida
                           child: const Row(
                             children: [
                               Text("Ler capítulo completo", style: TextStyle(color: arcaOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                               SizedBox(width: 4),
                               Icon(Icons.arrow_forward, size: 14, color: arcaOrange)
                             ],
                           ),
                         )
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 30),
                   
                   const _SectionHeader(icon: Icons.school_outlined, title: "Estudo da Palavra"),
                   const SizedBox(height: 10),
                   Text(
                     _devotional!.theologyContent,
                     style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                     textAlign: TextAlign.justify,
                   ),

                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 24.0),
                     child: Divider(height: 1, color: Colors.grey),
                   ),

                   const _SectionHeader(icon: Icons.favorite_border, title: "Para o Coração"),
                   const SizedBox(height: 10),
                   Text(
                     _devotional!.reflectionContent,
                     style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                     textAlign: TextAlign.justify,
                   ),
                   
                   const SizedBox(height: 40),
                   
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: _markAsRead,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: arcaOrange,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 0,
                       ),
                       child: Text(
                         _isSaving ? "SALVANDO..." : "CONCLUIR LEITURA", 
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                       ),
                     ),
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: arcaOrange, size: 24),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: arcaPurple,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}