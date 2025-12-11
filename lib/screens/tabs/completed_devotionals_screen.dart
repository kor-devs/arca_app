// lib/screens/tabs/completed_devotionals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../constants.dart';
import '../reading_flow/devotional_screen.dart';
import '../main_screen.dart';

class CompletedDevotionalsScreen extends StatefulWidget {
  const CompletedDevotionalsScreen({super.key});

  @override
  State<CompletedDevotionalsScreen> createState() => _CompletedDevotionalsScreenState();
}

class _CompletedDevotionalsScreenState extends State<CompletedDevotionalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _fetchCompleted();
  }

  Future<void> _fetchCompleted() async {
    setState(() { _isLoading = true; });
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Busca na tabela de relacionamento e faz join com os detalhes do devocional
      final response = await supabase
          .from('user_devotionals')
          .select('completed_at, devotionals(id, title, verse_reference)')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false);

      if (mounted) {
        setState(() {
          _list = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: arcaPurple,
        foregroundColor: arcaWhite,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light, 
          statusBarBrightness: Brightness.light,     
        ),
        title: const Text("Minhas Devocionais"),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: arcaPurple))
        : _list.isEmpty
          ? const Center(child: Text("Você ainda não completou nenhuma devocional.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _list.length,
              itemBuilder: (context, index) {
                final item = _list[index];
                // Como fizemos join, os dados do devocional estão dentro da chave 'devotionals'
                final devData = item['devotionals'] as Map<String, dynamic>; 
                final date = _formatDate(item['completed_at']);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0), // Laranja claro
                      child: Icon(Icons.check, color: arcaOrange),
                    ),
                    title: Text(
                      devData['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: arcaPurple),
                    ),
                    subtitle: Text("${devData['verse_reference']} • Lido em $date"),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      // Abre o devocional específico
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => DevotionalScreen(
                            devotionalId: devData['id'], // Passa o ID específico
                            onJumpToBible: (abbrev, chapter, verse) {
                              Navigator.pop(ctx);
                              final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                              mainScreen?.jumpToBible(abbrev, chapter, verse);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}