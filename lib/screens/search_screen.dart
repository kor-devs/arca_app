// lib/screens/search_screen.dart (V1.51 - Mantém V1.37 + Corrige V1.49)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import '../main.dart'; 
import '../constants.dart';
import '../models/search_verse.dart';
import '../models/chapter_response.dart'; 


import 'reading_flow/reading_screen.dart'; 
import 'reading_flow/verse_selection_screen.dart';



class SearchScreen extends StatefulWidget {
  // (Lógica V1.37 (Custo Zero) 100% MANTIDA)
  final String? initialQuery; 
  final bool returnResult; 
  const SearchScreen({super.key, this.initialQuery, this.returnResult = false});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  // (Estados V1.37 (Custo Zero) 100% MANTIDOS)
  final TextEditingController _searchController = TextEditingController();

  String _statusMessage = "Palavra (ex: 'Deus') ou Referência (ex: 'Genesis 1:1')";
  List<SearchVerse> _searchResults = [];
  bool _isLoading = false;
  final Dio _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 300),
    ),);
  // suggestions populated from the DB table `search_suggestions`
  List<String> _suggestions = [];
  bool _loadingSuggestions = false;

  final Map<String, String> _abbrevToBookNameMap = {};

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
    'lamentacoes': 'lm', 'lamentações': 'lm', 'lamentações de jeremias': 'lm',
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
    'atos': 'at', 'atos dos apóstolos': 'at',
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

  @override
  void initState() {
    // (Lógica V1.37 (Custo Zero) 100% MANTIDA)
    super.initState();
    _populateAbbrevToNameMap();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performReferenceSearch(widget.initialQuery!);
      });
    }

    // load suggestions (best-effort)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestions();
    });

    // NOTE: não abrimos o modal automaticamente aqui para evitar duplicação
    // (se quiser que outras telas mostrem o modal, chamem _openSearchModal diretamente)
  }

  // Nota: a versão modal da busca foi removida deste arquivo para evitar
  // comportamentos duplicados. Se quiser reintroduzir um modal global,
  // posso criar um widget/reutilizável `showSearchDialog(context)`.

  String? _translateBookToAbbrev(String bookName) {
    // (Lógica V1.37 (Custo Zero) 100% MANTIDA)
    String cleanName = bookName.toLowerCase().trim();
    return _bookTranslationMap[cleanName];
  }

  void _populateAbbrevToNameMap() {
    for (var entry in _bookTranslationMap.entries) {
      // (Prioriza a primeira chave encontrada, ex: 'gênesis' sobre 'genesis')
      if (!_abbrevToBookNameMap.containsKey(entry.value)) {
        String name = entry.key;
        if (name.isNotEmpty) {
          // (Capitaliza o nome para exibição)
          name = name[0].toUpperCase() + name.substring(1);
        }
        _abbrevToBookNameMap[entry.value] = name;
      }
    }
  }


  // Load suggestions from Supabase `search_suggestions` table
  Future<void> _loadSuggestions() async {
    setState(() {
      _loadingSuggestions = true;
    });
    try {
      final resp = await supabase
          .from('search_suggestions')
          .select('word, search_count')
          .order('search_count', ascending: false)
          .limit(5);

      final List<dynamic> list = resp as List<dynamic>;
      setState(() {
        // keep up to top 5 suggestions
        _suggestions = list.map((e) => (e['word'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
      });
    } catch (e) {
      // ignore errors (suggestions are optional)
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  // Upsert semantics: if exists increment search_count, otherwise insert with count=1
  Future<void> _upsertSuggestionOnResult(String term) async {
    try {
      final existing = await supabase.from('search_suggestions').select('id, search_count').ilike('word', term).limit(1).maybeSingle();
      if (existing != null) {
        final int id = existing['id'] as int;
        final int current = (existing['search_count'] ?? 0) as int;
        await supabase.from('search_suggestions').update({'search_count': current + 1}).eq('id', id);
      } else {
        await supabase.from('search_suggestions').insert({'word': term, 'search_count': 1});
      }
      // refresh suggestions list
      _loadSuggestions();
    } catch (e) {
      // ignore errors silently (best-effort)
    }
  }

  Future<void> _performReferenceSearch(String term) async {
    final refVerseRegex = RegExp(r"^\s*(.*?)\s*(\d+):(\d+)\s*$");
    final refChapterRegex = RegExp(r"^\s*(.*?)\s*(\d+)\s*$");
    String bookInput;
    String abbrevToUse;
    int chapter;
    int? verse;
    if (refVerseRegex.hasMatch(term)) {
        final match = refVerseRegex.firstMatch(term)!;
        bookInput = match.group(1)!;
        chapter = int.parse(match.group(2)!);
        verse = int.parse(match.group(3)!);
        String? translatedAbbrev = _translateBookToAbbrev(bookInput);
        if (translatedAbbrev != null) {
          abbrevToUse = translatedAbbrev;
        } else {
          abbrevToUse = bookInput.toLowerCase().trim();
        }
        _navigateToReading(abbrevToUse, chapter, verse);
    } else if (refChapterRegex.hasMatch(term)) {
        final match = refChapterRegex.firstMatch(term)!;
        bookInput = match.group(1)!;
        chapter = int.parse(match.group(2)!);
        verse = null;
        String? translatedAbbrev = _translateBookToAbbrev(bookInput);
        
        if (translatedAbbrev != null) {
          abbrevToUse = translatedAbbrev;
        } else {
          _performUnifiedSearch(term);
          return;
        }
        
        // --- CORREÇÃO DO FLUXO ---
        if (widget.returnResult) {
          // MODO MODAL (TodayScreen): Usamos await + push
          final selectedVerseNumber = await Navigator.push<int>(
            context,
            MaterialPageRoute(
              builder: (context) => VerseSelectionScreen(
                bookAbbrev: abbrevToUse,
                chapterNumber: chapter,
                returnResult: true, // <--- Repassa a ordem de retorno
              ),
            ),
          );

          // Se voltou com número, fecha o modal devolvendo dados para TodayScreen
          if (selectedVerseNumber != null && mounted) {
            Navigator.of(context).pop({
              'abbrev': abbrevToUse,
              'chapter': chapter,
              'verse': selectedVerseNumber,
            });
          }
        } else {
          // MODO LEGADO: Navegação direta (push sem await)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerseSelectionScreen(
                bookAbbrev: abbrevToUse,
                chapterNumber: chapter,
                returnResult: false,
              ),
            ),
          );
        }
    } else {
      _performUnifiedSearch(term);
    }
  }

  // (lib/screens/search_screen.dart)

  // (NOVA FUNÇÃO - O ORQUESTRADOR)
  // (Esta função substitui a lógica de _performKeywordSearch)
  Future<void> _performUnifiedSearch(String term) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Buscando por '$term', a busca pode demorar um pouco...";
      _searchResults = [];
    });
    await Future.delayed(const Duration(milliseconds: 100)); // (Para o loading aparecer)

    try {
      // (Chama as duas buscas em paralelo)
      final futureApiResults = _searchApiKeywords(term);
      final futureTitleResults = _searchChapterTitles(term);

      // (Aguarda os resultados)
      final apiResults = await futureApiResults;
      final titleResults = await futureTitleResults;

      if (!mounted) return;

      // (Combina os resultados, com Títulos primeiro!)
      final combinedResults = [...titleResults, ...apiResults];

      setState(() {
        _searchResults = combinedResults;
        _isLoading = false;
        if (combinedResults.isEmpty) {
          _statusMessage = "Nenhum resultado encontrado para '$term'.";
        } else {
          // (O status da API (ex: "50 resultados") é 
          // definido dentro de _searchApiKeywords)
          // (Se tivermos títulos, podemos sobrescrever 
          // a msg de status da API)
          if (titleResults.isNotEmpty) {
             _statusMessage = "${titleResults.length} títulos e ${apiResults.length} versículos encontrados.";
          }
        }
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Erro na busca: $e";
        _isLoading = false;
      });
    }
  }

  // (NOVA FUNÇÃO - BUSCA NO SUPABASE)
  Future<List<SearchVerse>> _searchChapterTitles(String term) async {
    try {
      final response = await supabase
          .from('chapter_titles')
          .select('title_text, book_abbrev, chapter, verse_start')
          .ilike('title_text', '%$term%') // (Busca 'ilike' (case-insensitive))
          .limit(15); // (Limita a 15 resultados de títulos)

      if (!mounted) return [];

      List<SearchVerse> titleResults = [];
      for (var item in response) {
        // (Usa o mapa reverso que criamos)
        String bookName = _abbrevToBookNameMap[item['book_abbrev']] ?? item['book_abbrev'].toUpperCase();
        
        // (Adapta o resultado do Título ao modelo 'SearchVerse')
        titleResults.add(SearchVerse(
          bookAbbrev: item['book_abbrev'],
          chapter: item['chapter'],
          number: item['verse_start'],
          text: item['title_text'], // (O subtítulo será o Título encontrado)
          bookName: bookName,
        ));
      }
      return titleResults;
    } catch (e) {
      debugPrint("Erro ao buscar títulos: $e");
      return []; // (Retorna vazio em caso de erro)
    }
  }

  // (FUNÇÃO RENOMEADA E MODIFICADA)
  // (Era: _performKeywordSearch)
  Future<List<SearchVerse>> _searchApiKeywords(String term) async {
    // (NÃO define _isLoading ou _statusMessage aqui, o orquestrador faz isso)
    
    final String normalizedTerm = term;
    try {
      final url = "$apiUrl/search";
      final response = await _dio.post(
        url,
        data: jsonEncode({'term': normalizedTerm}),
        options: Options(
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          receiveTimeout: const Duration(seconds: 300),
          ),
      );

      if (!mounted) return [];

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> versesJson = data['verses'];
        
        final List<SearchVerse> apiResults = versesJson.map((json) => SearchVerse.fromJson(json)).toList();
        
        if (mounted) {
          setState(() {
            // (Define a msg de status específica da API)
            _statusMessage = "${data['occurrence']} resultados encontrados na Bíblia.";
          });
        }
        
        if (versesJson.isNotEmpty) {
          await _upsertSuggestionOnResult(normalizedTerm);
        }
        
        return apiResults; // (RETORNA A LISTA)
      } else {
        throw Exception('Falha na busca (Erro: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return [];
      String errorMsg = e.toString();
      // ... (resto da sua lógica de erro Dio)
      if (e is DioException) {
        if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = "A busca na API demorou demais (Timeout de 300s).";
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg = "Não foi possível conectar ao servidor (Timeout de 60s).";
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = "Erro de conexão API.";
        }
      }
      if (mounted) {
        setState(() {
          _statusMessage = "Erro na busca API: $errorMsg";
        });
      }
      return []; // (RETORNA LISTA VAZIA EM CASO DE ERRO)
    }
  }

  Future<void> _navigateToReading(String abbrev, int chapter, int verse) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Carregando $abbrev $chapter:$verse...";
    });
    try {
      final url = "$apiUrl/chapter/$abbrev/$chapter";
      final response = await http.get(Uri.parse(url)); 
      if (!mounted) return;
      if (response.statusCode != 200) {
         throw Exception("Referência não encontrada (ex: 'gn 1:1')");
      }
      
      // (Usa (corretamente) o Modelo V1.49.1 (Custo Zero))
      final chapterData = ChapterResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      final startIndex = verse - 1; 

      // (Filtra (corretamente) 'items' (V1.49) (Custo Zero)
      // (corretamente) para 'VerseItem' (V1.49) (Custo Zero))
      final List<VerseItem> verses = chapterData.items
          .whereType<VerseItem>() 
          .toList();

      if (startIndex < 0 || startIndex >= verses.length) { // (Usa (corretamente) 'verses.length' (V1.51))
        throw Exception('Versículo não encontrado');
      }

      // (Corretamente) Mantém (V1.50) (Custo Zero)
      // a chamada (V1.50) (Custo Zero)
      // ao Leitor Legado (V1.25) (Custo Zero)
      // (V1.50) (Custo Zero))
      if (widget.returnResult == true) {
        // Return the selection to the caller (modal use-case)
        Navigator.of(context).pop({
          'abbrev': abbrev,
          'chapter': chapter,
          'verse': verse,
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingScreen(
              chapterData: chapterData,
              startIndex: startIndex,
            ),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Erro: $e";
        _isLoading = false;
      });
    }
  }
  // --- FIM DA CORREÇÃO ---

  @override
  Widget build(BuildContext context) {
    // If used as a modal bottom sheet that should return a result,
    // render a compact header-like area with a responsive height.
    double sheetHeight = MediaQuery.of(context).size.height * 0.7; // 60% da tela por padrão
    sheetHeight = sheetHeight.clamp(390.0, 780.0).toDouble(); // nunca abaixo de 220, nem acima de 780

    Widget contentColumn = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Palavra (ex: 'Deus') ou Referência (ex: 'Genesis 1:1')",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _performReferenceSearch(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                iconSize: 28,
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _performReferenceSearch(_searchController.text);
                  }
                },
              ),
            ],
          ),
        ),

        if (_loadingSuggestions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),

        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () {
                    _searchController.text = s;
                    _performUnifiedSearch(s);
                  },
                );
              }).toList(),
            ),
          ),

        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_searchResults.isEmpty && !_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              _statusMessage,
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final verse = _searchResults[index];
                return ListTile(
                  title: Text("${verse.bookName} ${verse.chapter}:${verse.number}"),
                  subtitle: Text(verse.text),
                  onTap: () {
                    _navigateToReading(verse.bookAbbrev, verse.chapter, verse.number);
                  },
                );
              },
            ),
          ),
      ],
    );

    if (widget.returnResult == true) {
      // compact modal appearance: safe area + fixed height similar to header
      return SafeArea(
          
          child: Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: arcaWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header row with back button and title (clickable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                    Expanded(
                      child: Text(
                        'Buscar na Bíblia',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // spacer to balance the back button
                  ],
                ),
              ),
              Expanded(child: contentColumn),
            ],
          ),
        ),
      );
    }

    // default: full screen scaffold (unchanged behavior)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar na Bíblia'),
      ),
      body: contentColumn,
    );
  }
}