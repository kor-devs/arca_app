import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'constants.dart'; 

// --- VARIÁVEIS GLOBAIS ---
final supabase = Supabase.instance.client;
late String apiUrl; // <-- MUDANÇA: Não é 'const', será lida do .env
// --------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Carrega o arquivo
    // (Mantenha o nome que funcionou no log anterior, 
    // provavelmente '.env' ou 'assets/env')
    //await dotenv.load(fileName: "assets/env");
    await dotenv.load(fileName: ".env"); 
    
    // 2. Verifica TODAS as variáveis
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    final backendUrl = dotenv.env['BACKEND_URL']; // <-- MUDANÇA: Carrega o backend
    
    if (url == null || url.isEmpty) throw Exception("SUPABASE_URL vazia");
    if (anonKey == null || anonKey.isEmpty) throw Exception("SUPABASE_ANON_KEY vazia");
    if (backendUrl == null || backendUrl.isEmpty) throw Exception("BACKEND_URL vazia");

    // 3. Define a apiUrl global
    apiUrl = "$backendUrl/api"; // <-- MUDANÇA: Define a API correta

    // 4. Inicializa Supabase
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    
    runApp(const MyApp());
    
  } catch (e, stacktrace) {
    // Tela Vermelha de Diagnóstico
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 60),
                  const SizedBox(height: 20),
                  const Text("ERRO DE INICIALIZAÇÃO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),
                  Text(e.toString(), style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.black26,
                    child: Text(stacktrace.toString(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

// --- CLASSE MyApp (Sem mudanças) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arca - A Bíblia em Suas Mãos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: arcaPurple,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: arcaPurple,
          primary: arcaPurple,
          secondary: arcaOrange,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}