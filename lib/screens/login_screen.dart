// lib/screens/login_screen.dart (V1.17 - Corrigido para Web)
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Importado para kIsWeb

import '../constants.dart';
import '../main.dart'; // Para acessar 'supabase'
import 'register_screen.dart';
import 'main_screen.dart'; // Importado para navegação

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; });

    // --- CORREÇÃO 1: LÓGICA DE REDIRECIONAMENTO WEB ---
    // Define para onde voltar após o login
    // Se for Web: Volta para o site.
    // Se for Mobile: Usa o deep link do app.
    const String? redirectUrl = kIsWeb 

        ? null
        : 'io.supabase.nyfqgwolxnozhmktwykn://login-callback';

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl, // Usa a variável correta
      );
      // (O AuthGate/Splash Screen vai detectar o login na volta)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar com Google: $e')),
      );
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() { _isLoading = true; });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- ADIÇÃO: Navegação manual ---
      // (O AuthGate pode demorar, então navegamos manualmente 
      // para a tela principal após o sucesso)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
      // --- FIM DA ADIÇÃO ---
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao entrar: Email ou senha inválidos.')),
      );
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CORREÇÃO 2: COR DE FUNDO (Evita "rastro" roxo na web) ---
      backgroundColor: arcaPurple,
      // --- FIM DA CORREÇÃO ---
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: arcaPurple,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_arca.jpg',
                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "ARCA",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: arcaWhite, 
                      fontSize: 48, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sua jornada espiritual diária.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: arcaWhite,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: arcaWhite),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    style: const TextStyle(color: arcaWhite),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Por favor, insira um email válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: "Senha",
                      labelStyle: TextStyle(color: arcaWhite),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    style: const TextStyle(color: arcaWhite),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: arcaWhite,))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: arcaWhite.withAlpha(220),
                            foregroundColor: arcaPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text("Entrar"),
                        ),
                        const SizedBox(height: 20),

                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white54)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("OU", style: TextStyle(color: Colors.white54)),
                            ),
                            Expanded(child: Divider(color: Colors.white54)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        ElevatedButton.icon(
                          icon: SvgPicture.asset(
                            'assets/icons/google_logo.svg',
                            height: 26,
                          ),
                          label: const Text("Continue com o Google"),
                          onPressed: _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.black.withAlpha(179),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Não tem conta? Cadastre-se",
                      style: TextStyle(color: arcaWhite),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}