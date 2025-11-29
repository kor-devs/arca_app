// lib/screens/tabs/bible_reader_screen.dart (V3.1 - Completo com Share e Menu UX)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // Importante para o Compartilhar
import 'package:arca_app/screens/search_screen.dart';
import 'package:flutter/services.dart';
import '../main_screen.dart';

import '../../main.dart';
import '../../models/chapter_response.dart'; 
import '../../constants.dart';

import '../reading_flow/book_picker_modal.dart';
import 'notes_screen.dart' show VerseNote; 

import '../../models/book_info.dart';
import '../../services/bible_service.dart';

@immutable
class BibleReaderScreen extends StatefulWidget {
  final String? initialBook;
  final int? initialChapter;
  final int? initialVerseIndex;

  const BibleReaderScreen({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.initialVerseIndex,
  });

  @override
  BibleReaderScreenState createState() => BibleReaderScreenState();
}

class BibleReaderScreenState extends State<BibleReaderScreen> {
  bool _isLoading = true;
  ChapterResponse? _currentResponse;
  String? _currentBookAbbrev;
  String? _currentBookName;
  int? _currentChapter;
  
  // Controle de Versões
  String _currentVersion = 'nvi'; 
  final Map<String, String> _availableVersions = {
    'nvi': 'Nova Versão Internacional',
    'acf': 'Almeida Corrigida Fiel',
    'aa': 'Almeida Atualizada',
  };

  Map<int, VerseNote> _notesMap = {};
  int? _highlightedVerseIndex; 

  bool _isLoadingFavorites = true;
  final Set<int> _favoriteVerseNumbers = {};
  final Color _favoriteHighlightColor = arcaNeonGreen;

  bool _showChapterButtons = true;
  Timer? _chapterButtonsTimer;
  double _horizontalDragAccum = 0.0;
  bool _chapterNavLocked = false;

  // Controllers
  TextEditingController? _noteController;
  TextEditingController? _noteTitleController;
  TextEditingController? _noteTagsController;
  Timer? _modalDebounceTimer;
  int? _modalServerDraftId;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final BibleService _bibleService = BibleService();

  static final List<Map<String, dynamic>> _bibleStructure = [
    {'abbrev': 'gn', 'chapters': 50}, {'abbrev': 'ex', 'chapters': 40},
    {'abbrev': 'lv', 'chapters': 27}, {'abbrev': 'nm', 'chapters': 36},
    {'abbrev': 'dt', 'chapters': 34}, {'abbrev': 'js', 'chapters': 24},
    {'abbrev': 'jz', 'chapters': 21}, {'abbrev': 'rt', 'chapters': 4},
    {'abbrev': '1sm', 'chapters': 31}, {'abbrev': '2sm', 'chapters': 24},
    {'abbrev': '1rs', 'chapters': 22}, {'abbrev': '2rs', 'chapters': 25},
    {'abbrev': '1cr', 'chapters': 29}, {'abbrev': '2cr', 'chapters': 36},
    {'abbrev': 'ed', 'chapters': 10}, {'abbrev': 'ne', 'chapters': 13},
    {'abbrev': 'et', 'chapters': 10}, {'abbrev': 'job', 'chapters': 42},
    {'abbrev': 'sl', 'chapters': 150}, {'abbrev': 'pv', 'chapters': 31},
    {'abbrev': 'ec', 'chapters': 12}, {'abbrev': 'ct', 'chapters': 8},
    {'abbrev': 'is', 'chapters': 66}, {'abbrev': 'jr', 'chapters': 52},
    {'abbrev': 'lm', 'chapters': 5}, {'abbrev': 'ez', 'chapters': 48},
    {'abbrev': 'dn', 'chapters': 12}, {'abbrev': 'os', 'chapters': 14},
    {'abbrev': 'jl', 'chapters': 3}, {'abbrev': 'am', 'chapters': 9},
    {'abbrev': 'ob', 'chapters': 1}, {'abbrev': 'jn', 'chapters': 4},
    {'abbrev': 'mq', 'chapters': 7}, {'abbrev': 'na', 'chapters': 3},
    {'abbrev': 'hc', 'chapters': 3}, {'abbrev': 'sf', 'chapters': 3},
    {'abbrev': 'ag', 'chapters': 2}, {'abbrev': 'zc', 'chapters': 14},
    {'abbrev': 'ml', 'chapters': 4}, {'abbrev': 'mt', 'chapters': 28},
    {'abbrev': 'mc', 'chapters': 16}, {'abbrev': 'lc', 'chapters': 24},
    {'abbrev': 'jo', 'chapters': 21}, {'abbrev': 'atos', 'chapters': 28},
    {'abbrev': 'rm', 'chapters': 16}, {'abbrev': '1co', 'chapters': 16},
    {'abbrev': '2co', 'chapters': 13}, {'abbrev': 'gl', 'chapters': 6},
    {'abbrev': 'ef', 'chapters': 6}, {'abbrev': 'fp', 'chapters': 4},
    {'abbrev': 'cl', 'chapters': 4}, {'abbrev': '1ts', 'chapters': 5},
    {'abbrev': '2ts', 'chapters': 3}, {'abbrev': '1tm', 'chapters': 6},
    {'abbrev': '2tm', 'chapters': 4}, {'abbrev': 'tt', 'chapters': 3},
    {'abbrev': 'fm', 'chapters': 1}, {'abbrev': 'hb', 'chapters': 13},
    {'abbrev': 'tg', 'chapters': 5}, {'abbrev': '1pe', 'chapters': 5},
    {'abbrev': '2pe', 'chapters': 3}, {'abbrev': '1jo', 'chapters': 5},
    {'abbrev': '2jo', 'chapters': 1}, {'abbrev': '3jo', 'chapters': 1},
    {'abbrev': 'jd', 'chapters': 1}, {'abbrev': 'ap', 'chapters': 22}
  ];

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentVersion = prefs.getString('bible_version') ?? 'nvi';
    });

    if (widget.initialBook != null && widget.initialChapter != null) {
      loadChapter(widget.initialBook!, widget.initialChapter!, widget.initialVerseIndex);
    } else {
      _loadLastRead();
    }
  }

  @override
  void dispose() {
    _chapterButtonsTimer?.cancel();
    super.dispose();
  }

  void _onUserScrollDetected() {
    if (!mounted) return;
    setState(() {
      _showChapterButtons = false;
    });
    _chapterButtonsTimer?.cancel();
    _chapterButtonsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showChapterButtons = true;
      });
    });
  }

  Future<void> _prevChapter() async {
    if (_chapterNavLocked) return;
    _chapterNavLocked = true;
    Timer(const Duration(milliseconds: 500), () { _chapterNavLocked = false; });
    
    if (_currentBookAbbrev == null || _currentChapter == null) return;

    if (_currentChapter! > 1) {
      await loadChapter(_currentBookAbbrev!, _currentChapter! - 1);
    } else {
      final currentIndex = _bibleStructure.indexWhere((b) => b['abbrev'] == _currentBookAbbrev);
      if (currentIndex > 0) {
        final prevBookData = _bibleStructure[currentIndex - 1];
        final prevBookAbbrev = prevBookData['abbrev'] as String;
        final prevBookLastChapter = prevBookData['chapters'] as int;
        await loadChapter(prevBookAbbrev, prevBookLastChapter);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você está no início da Bíblia')));
        }
      }
    }
  }

  Future<void> _nextChapter() async {
    if (_chapterNavLocked) return;
    _chapterNavLocked = true;
    Timer(const Duration(milliseconds: 500), () { _chapterNavLocked = false; });
    
    if (_currentBookAbbrev == null || _currentChapter == null) return;

    final currentBookData = _bibleStructure.firstWhere(
      (b) => b['abbrev'] == _currentBookAbbrev, 
      orElse: () => {'chapters': 999}
    );
    final maxChapters = currentBookData['chapters'] as int;

    if (_currentChapter! < maxChapters) {
      await loadChapter(_currentBookAbbrev!, _currentChapter! + 1);
    } else {
      final currentIndex = _bibleStructure.indexWhere((b) => b['abbrev'] == _currentBookAbbrev);
      if (currentIndex != -1 && currentIndex < _bibleStructure.length - 1) {
        final nextBookAbbrev = _bibleStructure[currentIndex + 1]['abbrev'] as String;
        await loadChapter(nextBookAbbrev, 1);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você finalizou a leitura da Bíblia!')));
        }
      }
    }
  }

  Future<void> loadChapter(String abbrev, int chapter, [int? initialVerseNumber]) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final url = "$apiUrl/$_currentVersion/$abbrev/$chapter";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        if (!mounted) return;
        final data = ChapterResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        setState(() {
          _currentResponse = data;
          _currentBookAbbrev = data.bookAbbrev;
          _currentBookName = data.bookName;
          _currentChapter = data.chapterNumber;
          _isLoading = false;
        });
        
        _loadFavoritesForThisChapter();
        _saveLastRead(abbrev, chapter);
        _loadChapterExtras(abbrev, chapter); 

        if (initialVerseNumber != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_itemScrollController.isAttached && _currentResponse != null) {
              final items = _currentResponse!.items;
              int targetIndex = items.indexWhere((it) {
                if (it is VerseItem) return it.number == initialVerseNumber;
                return false;
              });

              if (targetIndex == -1) {
                final legacyIndex = initialVerseNumber - 1;
                if (legacyIndex >= 0 && legacyIndex < items.length) {
                  targetIndex = legacyIndex;
                }
              }

              if (targetIndex != -1) {
                _itemScrollController.jumpTo(index: targetIndex);
                setState(() {
                  _highlightedVerseIndex = targetIndex;
                });
                Timer(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _highlightedVerseIndex = null;
                    });
                  }
                });
              }
            }
          });
        }
      } else {
        throw Exception("Falha ao carregar capítulo (${response.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar capítulo: $e')),
      );
    }
  }
  
  void refreshContent() {
    if (_currentBookAbbrev != null && _currentChapter != null) {
      _loadChapterExtras(_currentBookAbbrev!, _currentChapter!);
      _loadFavoritesForThisChapter();
    }
  }

  Future<void> _loadChapterExtras(String abbrev, int chapter) async {
    if (!mounted) return;
    try {
      final notes = await _fetchNotes(abbrev, chapter);
      if (!mounted) return;
      setState(() {
        _notesMap = notes;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("Erro ao carregar extras: $e");
    }
  }

  Future<Map<int, VerseNote>> _fetchNotes(String abbrev, int chapter) async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('verse_notes')
        .select('*')
        .eq('user_id', userId)
        .eq('book_name', _currentBookName!)
        .eq('chapter', chapter);

    if (response.isEmpty) {
      return {};
    }
    final List<dynamic> data = response;
    return {
      for (var item in data)
        item['verse_number'] as int: VerseNote.fromMap(item, {}) 
    };
  }

  Future<void> _loadFavoritesForThisChapter() async {
    if (_currentBookName == null || _currentChapter == null) return;
    try {
      final response = await supabase
          .from('favorite_verses')
          .select('verse_number')
          .eq('profile_id', supabase.auth.currentUser!.id)
          .eq('book_name', _currentBookName!)
          .eq('chapter', _currentChapter!);

      final newFavorites = <int>{};

      if (response.isNotEmpty) {
        final fetched = response.map<int>((item) => item['verse_number'] as int).toSet();
        newFavorites.addAll(fetched);
      }

      if (mounted) {
        setState(() {
          _favoriteVerseNumbers.clear();
          _favoriteVerseNumbers.addAll(newFavorites);
          _isLoadingFavorites = false;
        });
      }
      
    } catch (e) {
      debugPrint("Erro ao carregar favoritos: $e");
      if (mounted) {
        setState(() { _isLoadingFavorites = false; });
      }
    }
  }

  Future<void> _toggleFavorite(VerseItem verse) async {
    if (_currentBookName == null || _currentChapter == null) return;
    final verseNumber = verse.number;
    final isFavorite = _favoriteVerseNumbers.contains(verseNumber);
    try {
      if (isFavorite) {
        setState(() {
          _favoriteVerseNumbers.remove(verseNumber);
        });
        await supabase
            .from('favorite_verses')
            .delete()
            .eq('profile_id', supabase.auth.currentUser!.id)
            .eq('book_name', _currentBookName!)
            .eq('chapter', _currentChapter!)
            .eq('verse_number', verseNumber);
      } else {
        setState(() {
          _favoriteVerseNumbers.add(verseNumber);
        });
        await supabase.from('favorite_verses').insert({
          'profile_id': supabase.auth.currentUser!.id,
          'book_name': _currentBookName!,
          'chapter': _currentChapter!,
          'verse_number': verseNumber,
          'verse_text': verse.text,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar favorito: $e')),
        );
      }
    }
  }

  // --- [NOVO] FUNÇÃO DE COMPARTILHAR ---
  void _shareVerse(VerseItem verse) {
    if (_currentBookName == null || _currentChapter == null) return;
    
    // Formato: "Texto" - Livro Cap:Verso (Versão) \n Link
    final String textToShare = """
"${verse.text}"

${_currentBookName} ${_currentChapter}:${verse.number} (${_currentVersion.toUpperCase()})

Continue a leitura na Arca: https://arca.kordevs.com
""";
    
    Share.share(textToShare);
  }

  // --- [NOVO] MENU DE CONTEXTO DO VERSÍCULO (UX PATTERN) ---
  void _showVerseOptions(VerseItem verse) {
    final bool isFavorite = _favoriteVerseNumbers.contains(verse.number);
    final bool hasNote = _notesMap.containsKey(verse.number);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header do Menu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4, 
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
                    ),
                    Text(
                      "$_currentBookName $_currentChapter:${verse.number}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: arcaPurple),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Opção 1: Anotar
              ListTile(
                leading: Icon(hasNote ? Icons.edit_note : Icons.note_add_outlined, color: arcaPurple),
                title: Text(hasNote ? "Editar Anotação" : "Criar Anotação"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddNoteModal(verse);
                },
              ),

              // Opção 2: Favoritar
              ListTile(
                leading: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border, color: isFavorite ? arcaOrange : arcaPurple),
                title: Text(isFavorite ? "Remover dos Favoritos" : "Favoritar"),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleFavorite(verse);
                },
              ),

              // Opção 3: Comparar
              ListTile(
                leading: const Icon(Icons.compare_arrows, color: arcaPurple),
                title: const Text("Comparar Versões"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCompareModal(verse);
                },
              ),

              // Opção 4: Compartilhar [NOVO]
              ListTile(
                leading: const Icon(Icons.share_outlined, color: arcaPurple),
                title: const Text("Compartilhar"),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareVerse(verse);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCompareModal(VerseItem verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "$_currentBookName $_currentChapter:${verse.number}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: _availableVersions.entries.map((entry) {
                      return FutureBuilder(
                        future: http.get(Uri.parse("$apiUrl/${entry.key}/$_currentBookAbbrev/$_currentChapter")),
                        builder: (context, snapshot) {
                          String text = "Carregando...";
                          if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                            try {
                              final data = ChapterResponse.fromJson(jsonDecode(utf8.decode(snapshot.data!.bodyBytes)));
                              final v = data.items
                                  .whereType<VerseItem>()
                                  .firstWhere(
                                    (v) => v.number == verse.number, 
                                    orElse: () => VerseItem(number: 0, text: "Não encontrado")
                                  );
                              text = v.text;
                            } catch (e) {
                              text = "Erro ao processar texto.";
                            }
                          } else if (snapshot.hasError) {
                            text = "Erro ao carregar.";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: entry.key == _currentVersion ? arcaOrange.withOpacity(0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: entry.key == _currentVersion ? arcaOrange : Colors.transparent),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key.toUpperCase(), style: TextStyle(color: entry.key == _currentVersion ? arcaOrange : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(entry.value, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVersionPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Escolha a Versão", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: arcaPurple)),
              const SizedBox(height: 16),
              ..._availableVersions.entries.map((entry) {
                final isSelected = entry.key == _currentVersion;
                return ListTile(
                  title: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(entry.value),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: arcaOrange) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!isSelected) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('bible_version', entry.key);
                      
                      setState(() { _currentVersion = entry.key; });
                      if (_currentBookAbbrev != null && _currentChapter != null) {
                        loadChapter(_currentBookAbbrev!, _currentChapter!);
                      }
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddNoteModal(VerseItem verse) async {
    // ... (MANTENHA A LÓGICA DE NOTAS IDÊNTICA AO QUE VOCÊ JÁ TINHA) ...
    // ... APENAS REMOVA O BOTÃO "COMPARAR" DE DENTRO DESTE MODAL ...
    // ... POIS AGORA ELE ESTÁ NO MENU PRINCIPAL _showVerseOptions ...
    if (_currentBookName == null || _currentChapter == null) return;

    final int safeChapter = _currentChapter!;
    final String safeBookName = _currentBookName!;
    final String safeBookAbbrev = _currentBookAbbrev ?? safeBookName;

    _noteController ??= TextEditingController();
    _noteTitleController ??= TextEditingController();
    _noteTagsController ??= TextEditingController();

    _noteController!.clear();
    _noteTitleController!.clear();
    _noteTagsController!.clear();

    final String verseRef = "$safeBookName $safeChapter:${verse.number}";
    final existingNote = _notesMap[verse.number];

    final draftKey = 'draft_note_${supabase.auth.currentUser!.id}_${safeBookAbbrev}_${safeChapter}_${verse.number}';
    final draftTitleKey = 'draft_title_${supabase.auth.currentUser!.id}_${safeBookAbbrev}_${safeChapter}_${verse.number}';
    final draftTagsKey = 'draft_tags_${supabase.auth.currentUser!.id}_${safeBookAbbrev}_${safeChapter}_${verse.number}';

    if (existingNote != null) {
      _noteController!.text = existingNote.noteText;
      if (existingNote.title != null) _noteTitleController!.text = existingNote.title!;
      if (existingNote.tags.isNotEmpty) _noteTagsController!.text = existingNote.tags.join(', ');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final draft = prefs.getString(draftKey);
      final dtitle = prefs.getString(draftTitleKey);
      final dtags = prefs.getString(draftTagsKey);
      
      if (draft != null && draft.isNotEmpty) _noteController!.text = draft;
      if (dtitle != null && dtitle.isNotEmpty) _noteTitleController!.text = dtitle;
      if (dtags != null && dtags.isNotEmpty) _noteTagsController!.text = dtags;
    }

    final controller = _noteController!;
    final titleController = _noteTitleController!;
    final tagsController = _noteTagsController!;

    _modalDebounceTimer?.cancel();
    _modalServerDraftId = existingNote?.id;

    void startDebounceSave() {
      _modalDebounceTimer?.cancel();
      _modalDebounceTimer = Timer(const Duration(seconds: 2), () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(draftKey, controller.text);
        await prefs.setString(draftTitleKey, titleController.text);
        await prefs.setString(draftTagsKey, tagsController.text);

        final draftText = controller.text.trim();
        final titleText = titleController.text.trim();
        final tagsList = tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        try {
          if (draftText.isNotEmpty) {
            if (_modalServerDraftId == null) {
              final insertResp = await supabase.from('verse_notes').insert({
                'user_id': supabase.auth.currentUser!.id,
                'book_name': safeBookName,
                'chapter': safeChapter,
                'verse_number': verse.number,
                'verse_text': verse.text,
                'note_text': draftText,
                'verse_ref': verseRef,
                'title': titleText,
                'tags': tagsList,
                'is_draft': true,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }).select().single();

              _modalServerDraftId = insertResp['id'] as int?;
            } else {
              await supabase.from('verse_notes').update({
                'note_text': draftText,
                'title': titleText,
                'tags': tagsList,
                'is_draft': true,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }).eq('id', _modalServerDraftId!);
            }
          }
        } catch (e) {
           // ignore
        }
      });
    }

    controller.addListener(startDebounceSave);
    titleController.addListener(startDebounceSave);
    tagsController.addListener(startDebounceSave);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(verseRef, style: Theme.of(ctx2).textTheme.titleMedium)),
                        if (_modalServerDraftId != null || (existingNote != null && existingNote.isDraft == true))
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Chip(label: Text('Rascunho')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(verse.text, style: Theme.of(ctx2).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Título (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(labelText: 'Palavra chave (separadas por vírgula)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      minLines: 6,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(labelText: 'Sua anotação', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (existingNote != null || _modalServerDraftId != null)
                          TextButton(
                            onPressed: () async {
                              final idToDelete = existingNote?.id ?? _modalServerDraftId;
                              final confirm = await showDialog<bool>(
                                context: ctx2,
                                builder: (dctx) => AlertDialog(
                                  title: const Text('Confirmar'),
                                  content: const Text('Apagar esta anotação?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Não')),
                                    TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Sim')),
                                  ],
                                ),
                              );

                              if (confirm == true && idToDelete != null) {
                                try {
                                  await supabase.from('verse_notes').delete().eq('id', idToDelete);
                                  setState(() { _notesMap.remove(verse.number); });
                                  final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                                  mainScreenState?.refreshContent(); 
                                  Navigator.of(ctx2).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removido')));
                                } catch (e) {
                                  Navigator.of(ctx2).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                                }
                              }
                            },
                            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
                          ),
                        const SizedBox(width: 8),
                        
                        TextButton(
                          onPressed: () => Navigator.of(ctx2).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        
                        ElevatedButton(
                          onPressed: () async {
                            final noteText = controller.text.trim();
                            if (noteText.isEmpty) return;

                            try {
                              final tagsList = tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                              final idToUpdate = existingNote?.id ?? _modalServerDraftId;

                              if (idToUpdate != null) {
                                await supabase.from('verse_notes').update({
                                  'note_text': noteText,
                                  'title': titleController.text.trim(),
                                  'tags': tagsList,
                                  'is_draft': false,
                                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                                }).eq('id', idToUpdate);
                              } else {
                                await supabase.from('verse_notes').insert({
                                  'user_id': supabase.auth.currentUser!.id,
                                  'book_name': safeBookName,
                                  'chapter': safeChapter,
                                  'verse_number': verse.number,
                                  'verse_text': verse.text,
                                  'note_text': noteText,
                                  'verse_ref': verseRef,
                                  'title': titleController.text.trim(),
                                  'tags': tagsList,
                                  'is_draft': false,
                                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                                });
                              }

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove(draftKey);
                              await prefs.remove(draftTitleKey);
                              await prefs.remove(draftTagsKey);

                              final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                              mainScreenState?.refreshContent();

                              _loadChapterExtras(safeBookAbbrev, safeChapter);

                              Navigator.of(ctx2).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Anotação salva com sucesso')),
                              );
                            } catch (e) {
                              Navigator.of(ctx2).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao salvar: $e')),
                              );
                            }
                          },
                          child: const Text('Salvar'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.removeListener(startDebounceSave);
    titleController.removeListener(startDebounceSave);
    tagsController.removeListener(startDebounceSave);
    _modalDebounceTimer?.cancel();
  }

  Future<void> _saveLastRead(String abbrev, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadBook', abbrev);
    await prefs.setInt('lastReadChapter', chapter);
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final abbrev = prefs.getString('lastReadBook') ?? 'gn';
    final chapter = prefs.getInt('lastReadChapter') ?? 1;
    await loadChapter(abbrev, chapter); 
  }

  void _showBookPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BookPickerModal(),
    );
    if (result != null && result.containsKey('abbrev') && result.containsKey('chapter')) {
      loadChapter(result['abbrev']!, result['chapter']!);
    }
  }

  Widget _buildAppBarTitle() {
    String title = _currentBookName ?? "Bíblia";
    String chapter = _currentChapter?.toString() ?? "";
    return GestureDetector(
      onTap: _showBookPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$title $chapter'),
          const Icon(Icons.arrow_drop_down, color: arcaWhite),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search, color: arcaWhite),
      onPressed: () async {
        final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
        if (!mounted) return;
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const SearchScreen(returnResult: true),
        );
        if (result != null && mainScreenState != null) {
          final String abbrev = result['abbrev'];
          final int chapter = result['chapter'];
          final int verse = result['verse'];
          mainScreenState.jumpToBible(abbrev, chapter, verse);
        }
      },
    );
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
        title: _buildAppBarTitle(),
        actions: [
          TextButton(
            onPressed: _showVersionPicker,
            child: Text(
              _currentVersion.toUpperCase(),
              style: const TextStyle(color: arcaWhite, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSearchButton()
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: arcaPurple))
          : _isLoadingFavorites
            ? const Center(child: CircularProgressIndicator(color: arcaPurple))
            : Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (details) {
                      _horizontalDragAccum = 0.0;
                    },
                    onHorizontalDragUpdate: (details) {
                      _horizontalDragAccum += details.delta.dx;
                    },
                    onHorizontalDragEnd: (details) {
                      if (_horizontalDragAccum.abs() > 120) {
                        if (_horizontalDragAccum < 0) {
                          _nextChapter();
                        } else {
                          _prevChapter();
                        }
                      }
                      _horizontalDragAccum = 0.0;
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 64.0),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                            _onUserScrollDetected();
                          } else if (notification is UserScrollNotification) {
                            _onUserScrollDetected();
                          }
                          return false;
                        },
                        child: ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemCount: _currentResponse?.items.length ?? 0,
                          itemBuilder: (context, index) {
                            final item = _currentResponse!.items[index];
                            if (item is TitleItem) {
                               return Container(
                                 padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                                 child: Text(item.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: arcaOrange), textAlign: TextAlign.center)
                               );
                            }
                            if (item is VerseItem) {
                               final verse = item;
                               final hasNote = _notesMap.containsKey(verse.number);
                               final bool isFavorite = _favoriteVerseNumbers.contains(verse.number);
                               final bool isHighlighted = (index == _highlightedVerseIndex);
                               
                               return AnimatedContainer(
                                 duration: const Duration(milliseconds: 200),
                                 color: isHighlighted ? arcaOrange.withAlpha(128) : (isFavorite ? _favoriteHighlightColor.withAlpha(100) : Colors.transparent),
                                 child: GestureDetector(
                                   // [MODIFICADO] AGORA ABRE O MENU DE OPÇÕES (UX)
                                   onTap: () => _showVerseOptions(verse),
                                   onLongPress: () => _toggleFavorite(verse),
                                   child: Container(
                                     decoration: BoxDecoration(
                                        color: hasNote && !isHighlighted ? arcaPurple.withAlpha(20) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                     ),
                                     padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                     child: RichText(text: TextSpan(
                                        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18),
                                        children: [
                                           TextSpan(text: "${verse.number} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                           TextSpan(text: verse.text),
                                           if (hasNote) const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.speaker_notes, size: 16, color: arcaPurple)))
                                        ]
                                     )),
                                   ),
                                 ),
                               );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      offset: _showChapterButtons ? Offset.zero : const Offset(0, 1.2),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showChapterButtons ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !_showChapterButtons,
                          child: SizedBox(
                            height: 96,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 80.0,
                                    decoration: BoxDecoration(
                                      color: arcaWhite,
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -3))],
                                    ),
                                  ),
                                ),
                                Positioned(left: 12, bottom: 18, child: GestureDetector(onTap: _prevChapter, child: const SizedBox(width: 56, height: 56, child: Center(child: Icon(Icons.chevron_left, size: 28, color: arcaOrange))))),
                                Positioned(right: 12, bottom: 18, child: GestureDetector(onTap: _nextChapter, child: const SizedBox(width: 56, height: 56, child: Center(child: Icon(Icons.chevron_right, size: 28, color: arcaOrange))))),
                                Positioned(bottom: 16, child: ElevatedButton(onPressed: _showStudyModal, style: ElevatedButton.styleFrom(backgroundColor: arcaOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Saiba mais', style: TextStyle(color: Colors.white)))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
  
  void _showStudyModal() {
    if (_currentBookAbbrev == null) return;
    final String abbrev = _currentBookAbbrev!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8, 
          maxChildSize: 0.9,     
          minChildSize: 0.5,     
          builder: (BuildContext context, ScrollController scrollController) {
            return FutureBuilder<BookInfo>(
              future: _bibleService.fetchBookInfo(abbrev),
              builder: (context, snapshot) {
                Widget content;
                String title = _currentBookName ?? "Estudo";
                if (snapshot.connectionState == ConnectionState.waiting) {
                  content = const Center(child: CircularProgressIndicator(color: arcaPurple));
                } else if (snapshot.hasError || !snapshot.hasData) {
                  content = const Center(child: Text("Erro ao carregar dados de estudo."));
                } else {
                  final info = snapshot.data!;
                  title = info.bookName; 
                  content = _StudyInfoSheet(info: info, scrollController: scrollController);
                }
                return Container(
                  decoration: const BoxDecoration(color: arcaWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                  child: Column(
                    children: [
                      Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10.0), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 10),
                      Expanded(child: content),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StudyInfoSheet extends StatelessWidget {
  final BookInfo info;
  final ScrollController scrollController;
  const _StudyInfoSheet({required this.info, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), 
      children: [
        _buildStudySection(context, "Resumo", Text(info.summary ?? "N/A", style: Theme.of(context).textTheme.bodyLarge)),
        _buildStudySection(context, "Ficha Técnica", Container(padding: const EdgeInsets.all(12.0), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Column(children: [_buildInfoRow(context, "Autor:", info.author ?? "Desconhecido"), _buildInfoRow(context, "Data:", info.dateWritten ?? "Desconhecida"), _buildInfoRow(context, "Língua:", info.originalLanguage ?? "N/A")]))),
        if (info.mainThemes.isNotEmpty) _buildStudySection(context, "Temas Principais", Wrap(spacing: 8.0, runSpacing: 4.0, children: info.mainThemes.map((tema) => Chip(label: Text(tema), backgroundColor: arcaPurple.withAlpha(26), labelStyle: const TextStyle(color: arcaPurple), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: arcaPurple.withAlpha(77))))).toList())),
        _buildStudySection(context, "Contexto Histórico", Text(info.historicalContext ?? "N/A", style: Theme.of(context).textTheme.bodyLarge)),
        _buildStudySection(context, "Curiosidades", Text(info.trivia ?? "N/A", style: Theme.of(context).textTheme.bodyLarge)),
        if (info.crossReferences.isNotEmpty) _buildStudySection(context, "Referências Relacionadas", Column(children: info.crossReferences.map((ref) => Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(leading: const Icon(Icons.link_rounded, color: arcaPurple), title: Text.rich(TextSpan(style: Theme.of(context).textTheme.bodyMedium, children: [TextSpan(text: "${ref.book.toUpperCase()}: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ref.desc)])), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navegando para ${ref.book}... (não implementado)")))))).toList())),
        const SizedBox(height: 40), 
      ],
    );
  }

  Widget _buildStudySection(BuildContext context, String title, Widget content) {
    return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.8)), const SizedBox(height: 10), content]));
  }
  
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text.rich(TextSpan(style: Theme.of(context).textTheme.bodyLarge, children: [TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), TextSpan(text: value, style: const TextStyle(color: Colors.black54))])));
  }
}