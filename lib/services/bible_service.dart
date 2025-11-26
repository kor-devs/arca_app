// lib/services/bible_service.dart
import 'package:arca_app/main.dart'; // (Importa sua instância 'supabase')
import 'package:arca_app/models/book_info.dart';

class BibleService {
  
  // A nova função para buscar os dados de estudo (Custo Zero)
  Future<BookInfo> fetchBookInfo(String abbrev) async {
    try {
      final response = await supabase
          .from('book_info') // (Nossa tabela V3.2)
          .select()
          .eq('book_abbrev', abbrev)
          .single(); // (Traga apenas um)

      // (Nota de Arquiteto: O RLS desabilitado torna esta consulta pública muito rápida)
      return BookInfo.fromJson(response);

    } catch (e) {
      // Se falhar, retorna um objeto vazio para não quebrar a UI
      print("Erro ao buscar dados de estudo: $e");
      return BookInfo(
        bookAbbrev: abbrev,
        bookName: abbrev,
        mainThemes: [],
        crossReferences: [],
        summary: "Não foi possível carregar os dados de estudo. Tente novamente."
      );
    }
  }

  // Método compatível (usado pela UI)
  Future<BookInfo> getBookInfo(String abbrev) async {
    return fetchBookInfo(abbrev);
  }
}