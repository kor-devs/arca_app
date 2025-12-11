// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

// IMPORTS DAS TELAS DE DESTINO
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

  Future<void> _checkAuthAndNavigate() async {
    // Mantém a splash por 4 segundos para branding
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: arcaPurple,
      body: Stack(
        children: [
          // Fundo Gradiente
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
          
          // Conteúdo Central
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
                        'assets/images/arca_logo_circle.png', 
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

          // --- [NOVO] RODAPÉ POWERED BY KORDEVS ---
          Positioned(
            bottom: 40, // Subi um pouco para dar respiro
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Powered by",
                  style: TextStyle(
                    color: arcaWhite.withOpacity(0.6),
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "KorDevs",
                  style: TextStyle(
                    color: arcaWhite.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8), // Espaço entre a marca e a versão
                Text(
                  "v1.0.30", // Lembre-se de atualizar aqui quando mudar no pubspec
                  style: TextStyle(
                    color: arcaWhite.withOpacity(0.4), // Bem sutil
                    fontSize: 10,
                    fontFamily: 'Monospace', // Fonte técnica fica legal para versão
                  ),
                ),
              ],
            ),
          ),
          // -----------------------------------------
        ],
      ),
    );
  }
}