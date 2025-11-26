// lib/screens/tabs/profile_screen.dart (V1.17.3 - Mostra a Foto)
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../main.dart'; // Para acessar 'supabase'
import '../../constants.dart';
import 'edit_profile_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  void _inviteFriends(BuildContext context) {
    const String appUrl = "https://play.google.com/store/apps/details?id=com.example.arca_app"; // (Placeholder)
    const String message = "Olá! Estou usando o app Arca para minha jornada espiritual. Baixe você também!\n\n$appUrl";
    Share.share(message);
  }

  void _signOut(BuildContext context) {
    supabase.auth.signOut();
  }
  
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // (A lógica de 'user' agora vive dentro do 'build')
    final user = supabase.auth.currentUser;
    final String userName = user?.userMetadata?['full_name'] ?? "Usuário";
    final String userEmail = user?.email ?? "Carregando...";
    // --- ETAPA 12: Pega a URL da Foto ---
    final String? avatarUrl = user?.userMetadata?['avatar_url'];
    // --- FIM ETAPA 12 ---
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: arcaPurple, // Define a cor de fundo como roxo
        foregroundColor: arcaWhite,  // Define a cor de ícones e textos como branco
        // Para garantir que a barra de status do sistema siga o esquema (opcional, mas recomendado)
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light, // Ícones pretos para o fundo roxo (iOS)
          statusBarBrightness: Brightness.light,     // Ícones brancos para o fundo roxo (Android)
        ),
        title: const Text("Perfil"),
        actions: const [
          // (Removido ícone de busca conforme solicitado)
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                
                // --- ETAPA 12: Avatar Real (Custo Zero) ---
                CircleAvatar(
                  radius: 35,
                  backgroundColor: arcaPurple,
                  // Se a URL não for nula, usa NetworkImage
                  // Senão, usa a Letra
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                      ? NetworkImage(avatarUrl) 
                      : null,
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? null // Se tem imagem, não mostra a letra
                    : Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "A",
                        style: const TextStyle(color: arcaWhite, fontSize: 30),
                      ),
                ),
                // --- FIM ETAPA 12 ---

                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),

          ListTile(
            leading: const Icon(Icons.share, color: arcaPurple),
            title: const Text("Convidar Amigos"),
            subtitle: const Text("Compartilhe o Arca"),
            onTap: () {
              _inviteFriends(context);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text("Editar Perfil"),
            subtitle: const Text("Mudar nome ou foto"),
            onTap: () {
              _navigateToEditProfile();
            },
          ),
          
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Sair (Logout)"),
            onTap: () {
              _signOut(context);
            },
          ),
        ],
      ),
    );
  }
}