// lib/screens/tabs/verse_of_the_day_card.dart (V4.1 - Com Troca de Imagem)
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../models/random_verse.dart';
import '../../constants.dart';
import '../main_screen.dart'; 

class VerseOfTheDayCard extends StatefulWidget {
  final RandomVerse verse;
  final VoidCallback onSharePressed;
  final bool isSharingMode;

  const VerseOfTheDayCard({
    super.key, 
    required this.verse, 
    required this.onSharePressed, 
    this.isSharingMode = false,
  });

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

  // [NOVO] Controle da Imagem de Fundo
  // Se null, usa a do banco (padrão). Se tiver valor, usa a selecionada.
  String? _selectedImageUrl; 

  // Galeria de opções alternativas (Unsplash Curated)
  final List<String> _galleryOptions = [
    // Natureza / Paz
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1000&auto=format&fit=crop',
    // Céu / Espiritual
    'https://images.unsplash.com/photo-1510137600163-2729bc699b0b?q=80&w=1000&auto=format&fit=crop',
    // Bíblia / Estudo
    'https://images.unsplash.com/photo-1491841550275-ad7854e35ca6?q=80&w=1000&auto=format&fit=crop',
    // Montanha / Fé
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000&auto=format&fit=crop',
    // Abstrato / Luz
    'https://images.unsplash.com/photo-1493219686142-5a8641badc78?q=80&w=1000&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _fetchVerseStats();
  }

  // ... (Métodos de Like, Stats e Share mantidos iguais) ...
  String _getTodayDate() { return DateTime.now().toUtc().toIso8601String().split('T').first; }
  Future<void> _fetchVerseStats() async { if (!mounted) return; setState(() { _isLoadingStats = true; }); try { final response = await supabase.from('verse_stats').select('like_count, share_count').eq('verse_ref', widget.verse.reference).maybeSingle(); if (mounted) { setState(() { if (response != null) { _likeCount = response['like_count'] ?? 0; _shareCount = response['share_count'] ?? 0; } _isLoadingStats = false; }); } } catch (e) { if (mounted) setState(() { _isLoadingStats = false; }); } }
  Future<void> _checkIfLiked() async { try { final response = await supabase.from('verse_of_the_day_likes').select('id').eq('user_id', supabase.auth.currentUser!.id).eq('like_date', _getTodayDate()).eq('verse_ref', widget.verse.reference).maybeSingle(); if (!mounted) return; if (response != null) { setState(() { _isLiked = true; _likeId = response['id']; _isLoadingLike = false; }); } else { setState(() { _isLiked = false; _isLoadingLike = false; }); } } catch (e) { setState(() { _isLiked = false; _isLoadingLike = false; }); } }
  Future<void> _toggleLike() async { if (_isLoadingLike) return; setState(() { _isLoadingLike = true; }); final userId = supabase.auth.currentUser!.id; final String verseRef = widget.verse.reference; final bool newIsLikedState = !_isLiked; final int amount = newIsLikedState ? 1 : -1; if (mounted) { setState(() { _isLiked = newIsLikedState; _likeCount = _likeCount + amount; }); } try { if (newIsLikedState) { final response = await supabase.from('verse_of_the_day_likes').insert({ 'user_id': userId, 'like_date': DateTime.now().toUtc().toIso8601String().substring(0, 10), 'verse_ref': verseRef, 'verse_text': widget.verse.text }).select('id').single(); _likeId = response['id']; } else { if (_likeId != null) { await supabase.from('verse_of_the_day_likes').delete().eq('id', _likeId!); } _likeId = null; } await supabase.rpc('update_verse_like_count', params: { 'p_verse_ref': verseRef, 'p_amount': amount }); if (mounted) setState(() { _isLoadingLike = false; }); } catch (e) { if (mounted) { setState(() { _isLoadingLike = false; _isLiked = !newIsLikedState; _likeCount = _likeCount - amount; }); } } }
  Future<void> _navigateToReadingFromVerse(RandomVerse verse) async { final mainScreenState = context.findAncestorStateOfType<MainScreenState>(); mainScreenState?.jumpToBible(verse.bookAbbrev, verse.chapter, verse.number); }

  // [NOVO] Modal para trocar imagem
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 200,
          decoration: const BoxDecoration(
            color: arcaWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Escolha um tema", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Opção Original (Reset)
                    _buildImageOption(
                      imageUrl: widget.verse.imageUrl, 
                      isSelected: _selectedImageUrl == null,
                      onTap: () {
                        setState(() => _selectedImageUrl = null);
                        Navigator.pop(ctx);
                      }
                    ),
                    // Opções da Galeria
                    ..._galleryOptions.map((url) => _buildImageOption(
                      imageUrl: url, 
                      isSelected: _selectedImageUrl == url,
                      onTap: () {
                        setState(() => _selectedImageUrl = url);
                        Navigator.pop(ctx);
                      }
                    )),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({required String imageUrl, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: arcaOrange, width: 3) : null,
          image: DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover),
        ),
        child: isSelected 
          ? const Center(child: Icon(Icons.check_circle, color: arcaOrange, size: 30)) 
          : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define qual imagem usar
    final String displayImage = _selectedImageUrl ?? widget.verse.imageUrl;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
          height: 330, 
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. IMAGEM DE FUNDO (Animada na troca)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: CachedNetworkImage(
                key: ValueKey<String>(displayImage), // Importante para animação
                imageUrl: displayImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(color: const Color(0xFF2D0C3F)),
                errorWidget: (context, url, error) => Container(color: const Color(0xFF2D0C3F)),
              ),
            ),

            // 2. OVERLAY
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
                ),
              ),
            ),

            // 3. CONTEÚDO (referência topo-esquerdo; versículo centralizado)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
              child: InkWell(
                onTap: () { _navigateToReadingFromVerse(widget.verse); },
                splashColor: Colors.transparent,
                highlightColor: arcaWhite.withOpacity(0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Referência em badge arredondado para garantir contraste
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.32), // semi-transparente para contraste sobre imagens claras/escuras
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Text(
                        widget.verse.reference.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: arcaOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Versículo centralizado verticalmente e horizontalmente
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final String text = widget.verse.text;
                                // Compute font size based on text length and available width
                                double baseSize = 20.0;
                                if (text.length > 120) {
                                  baseSize = baseSize - ((text.length - 120) / 20);
                                } else if (text.length < 60) {
                                  baseSize = baseSize + 2.0; // a bit larger for short verses
                                }
                                // Scale a bit with width
                                final double widthScale = (constraints.maxWidth / 360.0) * 1.0;
                                double computed = (baseSize * widthScale).clamp(14.0, 26.0).toDouble();

                                return Text(
                                  '"$text"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: computed,
                                    height: 1.28,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: arcaWhite,
                                    shadows: const [Shadow(offset: Offset(0.5, 0.5), blurRadius: 6.0, color: Colors.black54)],
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // Reserve space for footer so the verse appears visually centered
                    const SizedBox(height: 55),
                  ],
                ),
              ),
            ),

            // 4. RODAPÉ (Botões)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: widget.isSharingMode
                  // --- MODO SHARE ---
                  ? Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, 
                        children: [
                          Image.asset('assets/images/arca_logo_circle.png', width: 30, height: 30),
                          const SizedBox(width: 8),
                          const Text("@entrenaarca", style: TextStyle(color: arcaWhite, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
                        ],
                      ),
                    )
                  // --- MODO NORMAL ---
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // [RESTAURADO] Botão de Trocar Imagem
                          IconButton(
                            onPressed: _showImagePicker,
                            tooltip: "Trocar Fundo",
                            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                            icon: const Icon(Icons.image, color: Colors.white, size: 20),
                          ),

                          // Ações Sociais
                          Row(
                            children: [
                              if (!_isLoadingStats)
                                _buildActionButton(
                                  icon: Image.asset('assets/icons/prayer_hands.png', color: _isLiked ? arcaOrange : arcaWhite, width: 24, height: 24),
                                  label: _likeCount.toString(),
                                  onTap: _toggleLike,
                                ),
                              const SizedBox(width: 16),
                              if (!_isLoadingStats)
                                _buildActionButton(
                                  icon: const Icon(Icons.share_outlined, color: arcaWhite, size: 24),
                                  label: _shareCount.toString(),
                                  onTap: widget.onSharePressed,
                                ),
                            ],
                          ),
                        ],
                      ),
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
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [icon, const SizedBox(width: 6), Text(label, style: const TextStyle(color: arcaWhite, fontWeight: FontWeight.bold, fontSize: 14))],
        ),
      ),
    );
  }
}