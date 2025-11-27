// lib/screens/tabs/profile_screen.dart (V2.1 - Fix Navegação)
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../constants.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'notes_screen.dart';
import '../main_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  void _inviteFriends(BuildContext context) {
    const String appUrl = "https://play.google.com/store/apps/details?id=com.example.arca_app"; 
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

  // [CORREÇÃO AQUI]
  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Renomeamos 'context' para 'ctx' para não esconder o 'context' da ProfileScreen
        builder: (ctx) => FavoritesScreen(
          onJumpToBible: (abbrev, chapter, verse) {
            // Usa 'ctx' para fechar a tela de Favoritos
            Navigator.pop(ctx); 
            
            // Usa 'context' (da ProfileScreen) para encontrar a MainScreen
            final mainScreen = context.findAncestorStateOfType<MainScreenState>();
            
            if (mainScreen != null) {
               mainScreen.jumpToBible(abbrev, chapter, verse);
            } else {
               debugPrint("ERRO: MainScreenState não encontrado via ProfileScreen context.");
            }
          },
        ),
      ),
    );
  }

  // [CORREÇÃO AQUI TAMBÉM]
  void _navigateToNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Renomeamos para 'ctx' aqui também
        builder: (ctx) => NotesScreen(
          onJumpToBible: (abbrev, chapter, verse) {
            Navigator.pop(ctx); 
            
            // Usa 'context' original
            final mainScreen = context.findAncestorStateOfType<MainScreenState>();
            mainScreen?.jumpToBible(abbrev, chapter, verse);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String userName = user?.userMetadata?['full_name'] ?? "Usuário";
    final String userEmail = user?.email ?? "Carregando...";
    final String? avatarUrl = user?.userMetadata?['avatar_url'];
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: arcaPurple, 
        foregroundColor: arcaWhite,  
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light, 
          statusBarBrightness: Brightness.light,     
        ),
        title: const Text("Opções & Perfil"),
      ),
      body: ListView(
        children: [
          // --- HEADER DO USUÁRIO ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: arcaPurple,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                      ? NetworkImage(avatarUrl) 
                      : null,
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? null 
                    : Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "A",
                        style: const TextStyle(color: arcaWhite, fontSize: 30),
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text("PESSOAL", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
          ),

          ListTile(
            leading: const Icon(Icons.bookmark, color: arcaOrange),
            title: const Text("Meus Favoritos"),
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: _navigateToFavorites, 
          ),

          ListTile(
            leading: const Icon(Icons.edit_note, color: arcaOrange),
            title: const Text("Minhas Notas"),
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: _navigateToNotes, 
          ),
          
          const Divider(),

          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text("GERAL", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
          ),

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
            title: const Text("Sair"),
            onTap: () {
              _signOut(context);
            },
          ),
        ],
      ),
    );
  }
}