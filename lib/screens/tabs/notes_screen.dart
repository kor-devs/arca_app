// lib/screens/tabs/notes_screen.dart (V1.31 - A Nova Aba)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../constants.dart';

// (Modelo de Custo Zero (V1.31) para a
// nova tabela 'verse_notes' (Ação 2))
class VerseNote {
  final int id;
  final String reference;
  final String verseText;
  String noteText;
  final String? title;
  final List<String> tags;
  final bool isDraft;
  final String? updatedAt;
  final String bookAbbrev;
  final int chapter;
  final int verseNumber;
  
  VerseNote({
    required this.id,
    required this.reference,
    required this.verseText,
    required this.noteText,
    this.title,
    this.tags = const [],
    this.isDraft = false,
    this.updatedAt,
    required this.bookAbbrev,
    required this.chapter,
    required this.verseNumber,
  });

  factory VerseNote.fromMap(Map<String, dynamic> map, Map<String, String> translationMap) {
    String bookName = map['book_name'];
    int chapter = map['chapter'];
    int verseNum = map['verse_number'];
    String? abbrev = translationMap[bookName.toLowerCase().trim()];

    return VerseNote(
      id: map['id'],
      reference: map['verse_ref'],
      verseText: map['verse_text'],
      noteText: map['note_text'] ?? '',
      title: map['title'],
      tags: (map['tags'] is List) ? List<String>.from(map['tags']) : [],
      isDraft: map['is_draft'] == true,
      updatedAt: map['updated_at']?.toString(),
      bookAbbrev: abbrev ?? bookName,
      chapter: chapter,
      verseNumber: verseNum,
    );
  }
}


class NotesScreen extends StatefulWidget {
  final Function(String, int, int) onJumpToBible;
  const NotesScreen({super.key, required this.onJumpToBible});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  List<VerseNote> _notesList = [];
  //late Future<List<VerseNote>> _notesFuture = Future.value(_notesList);
  bool _isLoading = false;
  bool _hasLoadedOnce = false;

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
    super.initState();
    if (!_hasLoadedOnce) {
       _fetchNotes();
    }
  }

  Future<void> _fetchNotes() async {
    if (_isLoading) return;
    
    if (mounted) setState(() { _isLoading = true; });

    try {
      final response = await supabase
          .from('verse_notes') // 
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .neq('note_text' , '') // (Ignora notas vazias)
          .order('updated_at', ascending: false); // (Ordena pela mais recente)
          
      final List<VerseNote> notes = (response as List)
          .map((item) => VerseNote.fromMap(item, _bookTranslationMap))
          .toList();

      if (mounted) {
        setState(() {
           _notesList = notes;
           _isLoading = false;
           _hasLoadedOnce = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
      debugPrint('Erro ao buscar anotações: $e');
    }
  }

  // (Ação 'Refresh' (V1.31)
  void refreshNotes() {
    _fetchNotes();
  }
  
  // (Ação 'Pular' (V1.30)
  void _navigateToReading(VerseNote note) {
    widget.onJumpToBible(
      note.bookAbbrev, 
      note.chapter, 
      note.verseNumber // (O Leitor V1.27 espera 'index' 0)
    );
  }
  
  // (Ação 'Deletar' (Custo Zero) (V1.31))
  Future<void> _deleteNote(int noteId, int index) async {
    try {
      setState(() {
        _notesList.removeAt(index);
      });
      await supabase
          .from('verse_notes')
          .delete()
          .eq('id', noteId);
    } catch (e) {
      refreshNotes(); // (Recarrega em caso de erro)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover anotação: $e')),
      );
    }
  }

  // HELPER PARA FORMATAR DATA
  String _formatDateTime(String? isoString) {
    if (isoString == null) return "";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      // Formato: dd/MM/yyyy HH:mm
      return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (e) {
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
        title: const Text("Minhas Anotações"),
      ),
      body: _isLoading && _notesList.isEmpty 
        ? const Center(child: CircularProgressIndicator())
        : _notesList.isEmpty
          ? const Center(
              child: Text(
                "Você ainda não fez nenhuma anotação.\n\n(Aba 'Bíblia' -> Clique simples para anotar)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _notesList.length,
              itemBuilder: (context, index) {
                final note = _notesList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  clipBehavior: Clip.antiAlias, // Garante que o InkWell respeite as bordas arredondadas
                  child: InkWell(
                    onTap: () => _navigateToReading(note),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- CABEÇALHO: Data e Referência ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(note.reference, style: const TextStyle(color: arcaPurple, fontWeight: FontWeight.bold, fontSize: 14)),
                               Text(_formatDateTime(note.updatedAt), style: const TextStyle(color: arcaPurple, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // --- TÍTULO (Se existir) ---
                          if (note.title != null && note.title!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(note.title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            
                          // --- TEXTO DO VERSÍCULO (Citação) ---
                          Container(
                            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                            decoration: const BoxDecoration(border: Border(left: BorderSide(color: arcaPurple, width: 3))),
                            child: Text(
                              "\"${note.verseText}\"", 
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                              maxLines: 3, 
                              overflow: TextOverflow.ellipsis
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // --- CORPO DA NOTA ---
                          Text(note.noteText, style: const TextStyle(fontSize: 15)),
                          
                          const SizedBox(height: 12),
                          
                          // --- TAGS ---
                          if (note.tags.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 0,
                              children: note.tags.map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                backgroundColor: arcaWhite,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: arcaWhite)),
                              )).toList(),
                            ),
                            
                          const Divider(height: 24),
                          
                          // --- AÇÕES ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 20, color: arcaOrange),
                                label: const Text("Excluir", style: TextStyle(color: arcaOrange)),
                                onPressed: () {
                                  _deleteNote(note.id, index);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "notes_refresh_btn",
        onPressed: () {
          refreshNotes();
        },
        backgroundColor: arcaOrange,
        child: const Icon(Icons.refresh, color: arcaWhite),
      ),
    );
  }
}