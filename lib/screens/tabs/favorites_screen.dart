// lib/screens/tabs/favorites_screen.dart (V1.31 - Notas Removidas)
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../constants.dart';
import '../main_screen.dart';

// (Modelo V1.31 (Custo Zero) - (Corretamente)
// NÃO tem mais 'notes')
class FavoriteVerse {
  final int id;
  final String reference;
  final String text;
  final String bookName;
  final String bookAbbrev;
  final int chapter;
  final int verseNumber;
  
  FavoriteVerse({
    required this.id, 
    required this.reference, 
    required this.text,
    required this.bookName,
    required this.bookAbbrev,
    required this.chapter,
    required this.verseNumber,
  });

  factory FavoriteVerse.fromMap(Map<String, dynamic> map, Map<String, String> translationMap) {
    String bookName = map['book_name'];
    int chapter = map['chapter'];
    int verseNum = map['verse_number'];
    String? abbrev = translationMap[bookName.toLowerCase().trim()];
    return FavoriteVerse(
      id: map['id'],
      reference: "$bookName $chapter:$verseNum",
      text: map['verse_text'],
      bookName: bookName,
      bookAbbrev: abbrev ?? bookName,
      chapter: chapter,
      verseNumber: verseNum,
      // (Campo 'notes' (V1.24) (corretamente) REMOVIDO)
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  final Function(String, int, int) onJumpToBible;
  const FavoritesScreen({super.key, required this.onJumpToBible});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteVerse> _favoritesList = [];
  late Future<List<FavoriteVerse>> _favoritesFuture;

  // (O 'translationMap' (V1.30)
  // (corretamente) 100% MANTIDO)
  static final Map<String, String> _bookTranslationMap = {
    'genesis': 'gn', 'gênesis': 'gn',
    'exodo': 'ex', 'êxodo': 'ex',
    'levitico': 'lv', 'levítico': 'lv',
    'numeros': 'nm', 'números': 'nm',
    'deuteronomio': 'dt', 'deuteronômio': 'dt',
    'josue': 'js', 'josué': 'js',
    'juizes': 'jz', 'juízes': 'jz',
    'rute': 'rt',
    '1 samuel': '1sm', '1 sm': '1sm', '1ª samuel': '1sm', '1° samuel': '1sm',
    '2 samuel': '2sm', '2 sm': '2sm', '2ª samuel': '2sm', '2° samuel': '2sm',
    '1 reis': '1rs', '1rs': '1rs', '1ª reis': '1rs',
    '2 reis': '2rs', '2rs': '2rs', '2ª reis': '2rs',
    '1 cronicas': '1cr', '1 crônicas': '1cr', '1cr': '1cr', '1ª crônicas': '1cr', '1° cronicas': '1cr',
    '2 cronicas': '2cr', '2 crônicas': '2cr', '2cr': '2cr', '2ª crônicas': '2cr', '2° cronicas': '2cr',
    'esdras': 'ed',
    'neemias': 'ne',
    'ester': 'et',
    'jó': 'job', 'job': 'job',
    'salmos': 'sl', 'sl': 'sl',
    'proverbios': 'pv', 'provérbios': 'pv', 'pv': 'pv',
    'eclesiastes': 'ec',
    'cantares': 'ct', 'cânticos': 'ct', 'ct': 'ct',
    'isaias': 'is', 'isaías': 'is',
    'jeremias': 'jr',
    'lamentacoes': 'lm', 'lamentações': 'lm',
    'ezequiel': 'ez',
    'daniel': 'dn',
    'oseias': 'os', 'oséias': 'os',
    'joel': 'jl',
    'amos': 'am', 'amós': 'am',
    'obadias': 'ob',
    'jonas': 'jn',
    'miqueias': 'mq', 'miquéias': 'mq',
    'naum': 'na',
    'habacuque': 'hc',
    'sofonias': 'sf',
    'ageu': 'ag',
    'zacarias': 'zc',
    'malaquias': 'ml',
    'mateus': 'mt',
    'marcos': 'mc',
    'lucas': 'lc',
    'joao': 'jo', 'joão': 'jo',
    'atos': 'atos',
    'romanos': 'rm',
    '1 corintios': '1co', '1 coríntios': '1co', '1co': '1co', '1ª coríntios': '1co', '1° corintios': '1co',
    '2 corintios': '2co', '2 coríntios': '2co', '2co': '2co', '2ª coríntios': '2co', '2° corintios': '2co',
    'galatas': 'gl', 'gálatas': 'gl',
    'efesios': 'ef', 'efésios': 'ef',
    'filipenses': 'fp',
    'colossenses': 'cl',
    '1 tessalonicenses': '1ts', '1ts': '1ts', '1ª tessalonicenses': '1ts', '1° tessalonicenses': '1ts',
    '2 tessalonicenses': '2ts', '2ts': '2ts', '2ª tessalonicenses': '2ts', '2° tessalonicenses': '2ts',
    '1 timoteo': '1tm', '1 timóteo': '1tm', '1tm': '1tm', '1ª timóteo': '1tm', '1° timoteo': '1tm',
    '2 timoteo': '2tm', '2 timóteo': '2tm', '2tm': '2tm', '2ª timóteo': '2tm', '2° timoteo': '2tm',
    'tito': 'tt',
    'filemom': 'fm',
    'hebreus': 'hb',
    'tiago': 'tg',
    '1 pedro': '1pe', '1pe': '1pe', '1ª pedro': '1pe', '1° pedro': '1pe',
    '2 pedro': '2pe', '2pe': '2pe', '2ª pedro': '2pe', '2° pedro': '2pe',
    '1 joao': '1jo', '1 joão': '1jo', '1jo': '1jo', '1ª joão': '1jo', '1° joao': '1jo',
    '2 joao': '2jo', '2 joão': '2jo', '2jo': '2jo', '2ª joão': '2jo', '2° joao': '2jo',
    '3 joao': '3jo', '3 joão': '3jo', '3jo': '3jo', '3ª joão': '3jo', '3° joao': '3jo',
    'judas': 'jd',
    'apocalipse': 'ap',
  };


  bool _didInitialLoad = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialLoad) {
      _favoritesFuture = _fetchFavorites();
      _didInitialLoad = true;
    }
  }

  Future<List<FavoriteVerse>> _fetchFavorites() async {
    // (Lógica V1.30 (Custo Zero))
    try {
      final response = await supabase
          .from('favorite_verses') //
          .select()
          .eq('profile_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      final List<FavoriteVerse> favorites = response
          .map((item) => FavoriteVerse.fromMap(item, _bookTranslationMap))
          .toList();
      setState(() {
         _favoritesList = favorites;
      });
      return favorites;
    } catch (e) {
      throw Exception('Erro ao buscar favoritos: $e');
    }
  }

  Future<void> _navigateToReading(FavoriteVerse verse) async {
    // (Lógica V1.30 (Custo Zero))
    widget.onJumpToBible(
      verse.bookAbbrev, 
      verse.chapter, 
      verse.verseNumber
    );
  }
  
  Future<void> _deleteFavorite(int verseId, int index) async {

    final mainScreen = context.findAncestorStateOfType<MainScreenState>();

    try {
      setState(() {
        _favoritesList.removeAt(index);
      });

      await supabase
          .from('favorite_verses') //
          .delete()
          .eq('id', verseId);

      mainScreen?.refreshBibleTab();

    } catch (e) {
      refreshFavorites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover favorito: $e')),
      );
    }
  }

  void refreshFavorites() {
    // (Lógica V1.30 (Custo Zero))
    setState(() {
      _favoritesFuture = _fetchFavorites();
    });
  }
  
  void _shareFavorite(FavoriteVerse verse) {
    final String message = "\"${verse.text}\" - ${verse.reference}\n\nEnviado via Arca App (link da loja)";
    Share.share(message);
  }
  
  // (As funções '_saveNote' (V1.24)
  // e '_showNotesDialog' (V1.24)
  // (corretamente) REMOVIDAS (V1.31))

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: arcaPurple, // Define a cor de fundo como roxo
        foregroundColor: arcaWhite,  // Define a cor de ícones e textos como branco
        // Para garantir que a barra de status do sistema siga o esquema (opcional, mas recomendado)
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light, // Ícones pretos para o fundo roxo (iOS)
          statusBarBrightness: Brightness.light,     // Ícones brancos para o fundo roxo (Android)
        ),
        title: const Text("Favoritos"), // (Título V1.31 (Custo Zero) Simplificado)
        actions: const [
          
        ],
      ),
      body: FutureBuilder<List<FavoriteVerse>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          // (Lógica V1.30 (Custo Zero))
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Você ainda não marcou nenhum versículo.\n\n(Aba 'Bíblia' -> Clique longo para salvar)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          final favorites = _favoritesList;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final verse = favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        _navigateToReading(verse);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              verse.reference,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              verse.text,
                              style: const TextStyle(fontSize: 16),
                            ),
                            // (O 'Container' de Notas (V1.24)
                            // (corretamente) REMOVIDO (V1.31))
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Row(
                      // (A Barra de Ações (V1.31) (Custo Zero)
                      // (corretamente) REMOVE o botão 'Notas')
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.send_outlined, color: Colors.black54, size: 22),
                          tooltip: "Compartilhar",
                          onPressed: () {
                            _shareFavorite(verse);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                          tooltip: "Remover dos Favoritos",
                          onPressed: () {
                            _deleteFavorite(verse.id, index);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "favorites_refresh_btn",
        onPressed: () {
          setState(() {
            _favoritesFuture = _fetchFavorites();
          });
        },
        backgroundColor: arcaOrange,
        child: const Icon(Icons.refresh, color: arcaWhite),
      ),
    );
  }
}