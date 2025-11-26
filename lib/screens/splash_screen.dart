// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

// IMPORTS DAS TELAS DE DESTINO
// (Verifique se os caminhos estão corretos para o seu projeto)
import '../screens/main_screen.dart';
import '../screens/login_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _loadingWords = ["Arca", "Aliança", "Propósito", "Atitude"];
  int _currentWordIndex = 0;
  Timer? _wordTimer;

  @override
  void initState() {
    super.initState();
    _startWordAnimation();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    super.dispose();
  }

  void _startWordAnimation() {
    _wordTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _currentWordIndex = (_currentWordIndex + 1) % _loadingWords.length;
        });
      }
    });
  }

  // --- FUNÇÃO DE NAVEGAÇÃO ---
  Future<void> _checkAuthAndNavigate() async {
    // 1. Garante que a splash fique visível por pelo menos 4 segundos
    // (Tempo suficiente para ler as palavras "Aliança", "Propósito", "Atitude")
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) return;

    // 2. Verifica se já existe usuário logado no Supabase
    final session = Supabase.instance.client.auth.currentSession;

    // 3. Navega para a tela correta
    if (session != null) {
      // Usuário logado -> Vai para a Home (MainScreen)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Ninguém logado -> Vai para o Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: arcaPurple,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  arcaPurple,
                  arcaPurple.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.transparent, 
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/arca_logo_circle.png', // Confirme se é logo.jpg ou arca_logo_circle.png
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover, 
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 50, 
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      _loadingWords[_currentWordIndex],
                      key: ValueKey<String>(_loadingWords[_currentWordIndex]),
                      style: const TextStyle(
                        color: arcaWhite, 
                        fontSize: 24, 
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}