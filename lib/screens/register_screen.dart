// lib/screens/register_screen.dart (V1.15 - Cadastro Corrigido)
import 'package:flutter/material.dart';
import '../constants.dart';
import '../main.dart'; // Para acessar 'supabase'

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  // --- NOVOS CAMPOS (UX) ---
  final _nameController = TextEditingController(); // (Novo)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // (Novo)
  // --- FIM NOVOS CAMPOS ---
  
  bool _isLoading = false;

  Future<void> _signUp() async {
    // Valida o formulário (Custo Zero)
    if (!_formKey.currentState!.validate()) {
      return; // Se houver erros, não continua
    }
    
    setState(() { _isLoading = true; });
    
    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _nameController.text.trim()},
        
        emailRedirectTo: 'io.supabase.nyfqgwolxnozhmktwykn://login-callback',
      );
      
      if (!mounted) return;
      
      // (No próximo sprint, mostraremos um "Verifique seu email")
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado! Verifique seu e-mail.')),
      );
      
      // (Volta para a tela de Login)
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no cadastro: $e')),
      );
    }

    if (!mounted) return;
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: arcaPurple,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView( // (Permite rolar se o teclado cobrir)
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Crie sua Conta",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: arcaWhite, 
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // --- CAMPO NOME (NOVO) ---
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome Completo",
                      labelStyle: TextStyle(color: arcaWhite),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    style: const TextStyle(color: arcaWhite),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira seu nome.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- CAMPO EMAIL ---
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
                  
                  // --- CAMPO SENHA ---
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: "Senha (mín. 6 caracteres)",
                      labelStyle: TextStyle(color: arcaWhite),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    style: const TextStyle(color: arcaWhite),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- CAMPO CONFIRMAR SENHA (NOVO) ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: "Confirme sua Senha",
                      labelStyle: TextStyle(color: arcaWhite),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    style: const TextStyle(color: arcaWhite),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha.';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: arcaWhite,))
                  else
                    ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: arcaPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // A CORREÇÃO (FontWeight.bold)
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Cadastrar"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}