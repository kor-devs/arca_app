// lib/screens/reading_flow/devotional_screen.dart (V1.1 - Com Navegação)
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../main.dart';
import '../../constants.dart';
import '../main_screen.dart'; // <--- Importante para navegação

class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({super.key});

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _devotional;
  
  @override
  void initState() {
    super.initState();
    _fetchDailyDevotional();
  }

  Future<void> _fetchDailyDevotional() async {
    final now = DateTime.now();
    final diff = now.difference(DateTime(now.year, 1, 1, 0, 0));
    final int realDayOfYear = diff.inDays + 1;

    setState(() { _isLoading = true; });

    try {
      // Tenta buscar o dia exato
      var response = await supabase
          .from('devotionals')
          .select()
          .eq('day_of_year', realDayOfYear)
          .maybeSingle();

      // Fallback: Se não achar, busca um dos 7 existentes
      if (response == null) {
        final int fallbackDay = ((realDayOfYear - 1) % 7) + 1;
        response = await supabase
            .from('devotionals')
            .select()
            .eq('day_of_year', fallbackDay)
            .maybeSingle();
      }

      if (mounted) {
        setState(() {
          _devotional = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro crítico ao buscar devocional: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NOVA FUNÇÃO DE NAVEGAÇÃO ---
  void _navigateToVerse() {
    if (_devotional == null) return;

    // 1. Extrai os dados seguros do banco
    final String abbrev = _devotional!['book_abbrev'];
    final int chapter = _devotional!['chapter'];
    final int verseNum = _devotional!['verse_number'];

    // 2. Fecha a tela de Devocional (Pop)
    Navigator.pop(context);

    // 3. Encontra a MainScreen e comanda a navegação
    final mainScreen = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreen != null) {
      // Usa a mesma função que Favoritos e Notas usam
      mainScreen.jumpToBible(abbrev, chapter, verseNum);
    }
  }

  void _shareDevotional() {
    if (_devotional == null) return;
    final text = """
📖 *Devocional - ${_devotional!['title']}*

"${_devotional!['verse_text']}"
_${_devotional!['verse_reference']}_

💡 *Reflexão:*
${_devotional!['reflection_content']}

Entre na Arca para ler mais!
🔗 arca.kordvs.com
""";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: arcaWhite, 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: arcaPurple))
          : _devotional == null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: arcaPurple,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6A1B9A), arcaPurple],
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 30),
                                  const Icon(Icons.wb_sunny, color: arcaOrange, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    _devotional!['title'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)]
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: _shareDevotional,
                        )
                      ],
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Card do Versículo (Agora Clicável)
                            InkWell(
                              onTap: _navigateToVerse, // <--- Ação de clique
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: arcaPurple.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: arcaPurple.withOpacity(0.1)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "\"${_devotional!['verse_text']}\"",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _devotional!['verse_reference'],
                                          style: const TextStyle(
                                            color: arcaPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.0
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Ícone indicando que é clicável
                                        const Icon(Icons.arrow_forward, size: 14, color: arcaPurple),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Ler capítulo completo",
                                      style: TextStyle(fontSize: 10, color: Colors.grey),
                                    )
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 2. Título Teológico
                            const _SectionHeader(icon: Icons.school_outlined, title: "Estudo da Palavra"),
                            const SizedBox(height: 10),
                            Text(
                              _devotional!['theology_content'],
                              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                              textAlign: TextAlign.justify,
                            ),

                            const Divider(height: 50, color: Colors.grey),

                            // 3. Título Reflexão
                            const _SectionHeader(icon: Icons.favorite_border, title: "Para o Coração"),
                            const SizedBox(height: 10),
                            Text(
                              _devotional!['reflection_content'],
                              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                              textAlign: TextAlign.justify,
                            ),

                            const SizedBox(height: 40),

                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text("Li e Meditei hoje"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: arcaPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Amém! Palavra guardada no coração."))
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Devocional de hoje carregando...", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDailyDevotional,
            child: const Text("Tentar Novamente"),
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