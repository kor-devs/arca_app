// lib/screens/tabs/verse_of_the_day_card.dart (V3.1 - Layout Centralizado)
import 'package:flutter/material.dart';
//import 'dart:math'; 
//import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../models/random_verse.dart';
import '../../constants.dart';
import '../main_screen.dart'; 

class VerseOfTheDayCard extends StatefulWidget {
  final RandomVerse verse;
  final VoidCallback onSharePressed;
  const VerseOfTheDayCard({super.key, required this.verse, required this.onSharePressed});

  @override
  State<VerseOfTheDayCard> createState() => _VerseOfTheDayCardState();
}

class _VerseOfTheDayCardState extends State<VerseOfTheDayCard> {
  bool _isLiked = false;
  bool _isLoadingLike = true;
  int? _likeId; 
  int _likeCount = 0;
  int _shareCount = 0;
  bool _isLoadingStats = true;

  final List<String> _backgroundImages = [
    'assets/images/vof_bg_1.jpg',
    'assets/images/vof_bg_2.jpg',
    'assets/images/vof_bg_3.jpg',
    'assets/images/vof_bg_4.jpg',
    'assets/images/vof_bg_5.jpg',
    'assets/images/vof_bg_6.jpg',
    'assets/images/vof_bg_7.jpg',
    'assets/images/vof_bg_8.jpg',
    'assets/images/vof_bg_9.jpg',
    'assets/images/vof_bg_10.jpg',
    'assets/images/vof_bg_11.jpg',
  ];
  
  late String _currentBackgroundImage;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _fetchVerseStats();
    // Calcula um número único para o dia de hoje
    final int daySeed = DateTime.now().toUtc().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
    // Garante que o índice esteja dentro do tamanho da lista
    final int dailyIndex = daySeed % _backgroundImages.length;
    
    _currentBackgroundImage = _backgroundImages[dailyIndex];
  }

  void _cycleBackground() {
    setState(() {
      int currentIndex = _backgroundImages.indexOf(_currentBackgroundImage);
      int nextIndex = (currentIndex + 1) % _backgroundImages.length;
      _currentBackgroundImage = _backgroundImages[nextIndex];
    });
  }

  String _getTodayDate() {
    return DateTime.now().toUtc().toIso8601String().split('T').first; 
  }

  Future<void> _fetchVerseStats() async {
    if (!mounted) return;
    setState(() { _isLoadingStats = true; });
    try {
      final response = await supabase
          .from('verse_stats')
          .select('like_count, share_count')
          .eq('verse_ref', widget.verse.reference)
          .single();
      if (mounted) {
        setState(() {
          _likeCount = response['like_count'] ?? 0;
          _shareCount = response['share_count'] ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingStats = false; });
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final response = await supabase
          .from('verse_of_the_day_likes')
          .select('id')
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('like_date', _getTodayDate())
          .eq('verse_ref', widget.verse.reference)
          .limit(1); 
      if (!mounted) return; 
      if (response.isNotEmpty) {
        setState(() {
          _isLiked = true;
          _likeId = response[0]['id'];
          _isLoadingLike = false;
        });
      } else {
        setState(() {
          _isLiked = false;
          _isLoadingLike = false;
        });
      }
    } catch (e) {
      setState(() { _isLiked = false; _isLoadingLike = false; });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return; 
    setState(() { _isLoadingLike = true; });
    final userId = supabase.auth.currentUser!.id;
    final String verseRef = widget.verse.reference;
    final bool newIsLikedState = !_isLiked; 
    final int amount = newIsLikedState ? 1 : -1; 

    if (mounted) {
      setState(() {
        _isLiked = newIsLikedState; 
        _likeCount = _likeCount + amount;
      });
    }

    try {
      if (newIsLikedState) { 
        final response = await supabase
            .from('verse_of_the_day_likes')
            .insert({
              'user_id': userId,
              'like_date': DateTime.now().toUtc().toIso8601String().substring(0, 10),
              'verse_ref': verseRef,
              'verse_text': widget.verse.text
            })
            .select('id')
            .single(); 
        _likeId = response['id'];
      } else {
        if (_likeId != null) {
          await supabase.from('verse_of_the_day_likes').delete().eq('id', _likeId!);
        }
        _likeId = null; 
      }
      await supabase.rpc('update_verse_like_count', params: {
        'p_verse_ref': verseRef,
        'p_amount': amount
      });
      if (mounted) setState(() { _isLoadingLike = false; });
    } catch (e) {
       if (mounted) {
         setState(() {
           _isLoadingLike = false; 
           _isLiked = !newIsLikedState;
           _likeCount = _likeCount - amount;
         });
       }
    }
  }

  Future<void> _navigateToReadingFromVerse(RandomVerse verse) async {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    mainScreenState?.jumpToBible(
      verse.bookAbbrev, 
      verse.chapter, 
      verse.number
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 400, 
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. IMAGEM DE FUNDO
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Image.asset(
                _currentBackgroundImage,
                key: ValueKey<String>(_currentBackgroundImage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: arcaPurple);
                },
              ),
            ),

            // 2. CAMADA DE PROTEÇÃO (Overlay mais forte no centro para leitura)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // 3. CONTEÚDO DE TEXTO (Layout Reorganizado)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: InkWell(
                onTap: () {
                  _navigateToReadingFromVerse(widget.verse);
                },
                splashColor: Colors.transparent,
                highlightColor: arcaWhite.withOpacity(0.1),
                child: Column(
                  // 🟢 CORREÇÃO: Alinhamento centralizado
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5), // Espaço do topo
                    
                    // --- TOPO: Badge e Referência ---
                    /*Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: arcaWhite.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Text(
                        "VERSÍCULO DO DIA",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: arcaWhite,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),*/
                    
                    const SizedBox(height: 8),
                    
                    // Referência (Agora no Topo)
                    Text(
                      widget.verse.reference,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: arcaOrange, 
                        shadows: [Shadow(offset: Offset(1, 1), blurRadius: 4.0, color: arcaShadow)]
                      ),
                    ),

                    // --- MEIO: Texto do Versículo (Centralizado verticalmente) ---
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          // Adiciona scroll se o texto for muito longo
                          child: Text(
                            "\"${widget.verse.text}\"",
                            textAlign: TextAlign.center, // Centraliza o texto
                            style: const TextStyle(
                              fontSize: 20, 
                              height: 1.3,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: arcaWhite,
                              shadows: [
                                Shadow(offset: Offset(1, 1), blurRadius: 8.0, color: arcaShadow),
                              ]
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Espaço para não bater nos botões
                    const SizedBox(height: 60), 
                  ],
                ),
              ),
            ),

            // 4. BOTÕES DE AÇÃO (Rodapé - Mantido igual)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _cycleBackground,
                      tooltip: "Mudar tema",
                      style: IconButton.styleFrom(
                        backgroundColor: arcaWhite.withOpacity(0.15),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, color: arcaWhite, size: 20),
                    ),

                    Row(
                      children: [
                        if (!_isLoadingStats)
                          _buildActionButton(
                            icon: Image.asset(
                              'assets/icons/prayer_hands.png',
                              color: _isLiked ? arcaOrange : arcaWhite,
                              width: 22, height: 22,
                            ),
                            label: _likeCount.toString(),
                            onTap: _toggleLike,
                          ),
                        
                        const SizedBox(width: 16),

                        if (!_isLoadingStats)
                          _buildActionButton(
                            icon: const Icon(Icons.share_outlined, color: arcaWhite, size: 22),
                            label: _shareCount.toString(),
                            onTap: widget.onSharePressed,
                          ),
                      ],
                    ),
                  ],
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required Widget icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: arcaWhite, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}