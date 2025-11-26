// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Para acessar 'supabase'
import 'splash_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const MainScreen(); // (A Home com NavBar)
          }
        }
        
        return const LoginScreen(); // (A Tela de Login)
      },
    );
  }
}