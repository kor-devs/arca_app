import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/search_verse.dart';
import '../main.dart';

/// Mostra um diálogo de busca reutilizável que desce do topo.
/// Retorna um Map com chaves 'abbrev', 'chapter', 'verse' quando o usuário seleciona
/// um resultado, ou null se cancelar.
Future<Map<String, dynamic>?> showSearchDialog(BuildContext context, {String? initialQuery}) async {
  final TextEditingController controller = TextEditingController(text: initialQuery ?? '');
  final Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 60)));
  List<SearchVerse> results = [];
  bool isLoading = false;
  String status = "Digite um termo ou referência";

  return showGeneralDialog<Map<String, dynamic>?>(
    context: context,
    barrierLabel: 'Busca',
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) {
      return StatefulBuilder(
        builder: (ctx2, setState) {
          Future<void> performSearch(String term) async {
            if (term.trim().isEmpty) return;
            setState(() {
              isLoading = true;
              status = "Buscando...";
              results = [];
            });

            try {
              final url = "$apiUrl/search";
              final resp = await dio.post(url,
                  data: {'term': term},
                  options: Options(headers: {'Content-Type': 'application/json; charset=utf-8'}));

              if (resp.statusCode == 200) {
                final data = resp.data;
                final versesJson = data['verses'] as List<dynamic>;
                setState(() {
                  results = versesJson.map((j) => SearchVerse.fromJson(j as Map<String, dynamic>)).toList();
                  status = "${data['occurrence'] ?? results.length} resultados";
                });
              } else {
                setState(() {
                  status = "Erro na busca (${resp.statusCode})";
                });
              }
            } catch (e) {
              setState(() {
                status = "Erro: $e";
              });
            } finally {
              setState(() {
                isLoading = false;
              });
            }
          }

          // The visible dialog content
          final dialog = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: "Palavra (ex: 'Deus') ou Referência (ex: 'Genesis 1:1')",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (v) => performSearch(v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx2).pop(null);
                            },
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isLoading) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(status, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ] else if (results.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(status, style: const TextStyle(fontStyle: FontStyle.italic)),
                        )
                      ] else ...[
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final v = results[index];
                              return ListTile(
                                title: Text("${v.bookName} ${v.chapter}:${v.number}"),
                                subtitle: Text(v.text),
                                onTap: () {
                                  Navigator.of(ctx2).pop({
                                    'abbrev': v.bookAbbrev,
                                    'chapter': v.chapter,
                                    'verse': v.number,
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => performSearch(controller.text), child: const Text('Buscar')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          return SafeArea(child: dialog);
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from top -> down
      final offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
