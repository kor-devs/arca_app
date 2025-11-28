// lib/screens/tabs/edit_profile_screen.dart (V1.17.7 - Com "Pedir Remoção")
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../main.dart'; // Para acessar 'supabase'
import '../../constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  XFile? _pickedImage;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();
  
  // --- ETAPA 14: Controlador para o Pop-up ---
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] ?? '';
    _avatarUrl = user?.userMetadata?['avatar_url'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose(); // (Limpa o novo controlador)
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Usuário não encontrado");

      String? newAvatarUrl = _avatarUrl;

      // Se o usuário escolheu uma nova imagem
      if (_pickedImage != null) {
        final imageExtension = _pickedImage!.path.split('.').last.toLowerCase();
        final String imagePath = '${user.id}/avatar.$imageExtension';

        // [CORREÇÃO WEB/MOBILE]
        // Lemos os bytes do arquivo (funciona em Web e Mobile)
        final bytes = await _pickedImage!.readAsBytes();

        // Usamos uploadBinary em vez de upload (que exige File)
        await supabase.storage.from('avatars').uploadBinary(
          imagePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        // Pega a URL base
        final String baseUrl = supabase.storage.from('avatars').getPublicUrl(imagePath);

        // Adiciona timestamp para quebrar o cache
        newAvatarUrl = "$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      }

      final newName = _nameController.text.trim();

      // Atualiza os metadados
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': newName,
            'avatar_url': newAvatarUrl,
          }
        )
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o perfil: $e')),
      );
    }
    
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildAvatar() {
    if (_pickedImage != null) {
      // [CORREÇÃO DE PREVIEW]
      // Se for Web, usamos NetworkImage (o path é um blob url). 
      // Se for Mobile, usamos FileImage (o path é caminho de disco).
      ImageProvider imageProvider;
      if (kIsWeb) {
        imageProvider = NetworkImage(_pickedImage!.path);
      } else {
        imageProvider = FileImage(File(_pickedImage!.path));
      }

      return CircleAvatar(
        radius: 60,
        backgroundColor: arcaPurple.withAlpha(100),
        backgroundImage: imageProvider,
      );
    }
    
    // Mostra avatar atual (URL do Supabase)
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: arcaPurple.withAlpha(100),
        backgroundImage: NetworkImage(_avatarUrl!),
      );
    }
    
    // Avatar padrão (Ícone)
    return CircleAvatar(
      radius: 60,
      backgroundColor: arcaPurple.withAlpha(100),
      child: const Icon(Icons.person, size: 60, color: arcaWhite),
    );
  }

  // --- ETAPA 14: Lógica do Pop-up (UX/Agilidade) ---
  void _showDeleteAccountDialog() {
    // Limpa o campo de "motivo" toda vez que abre
    _reasonController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remover sua Conta?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Esta ação é permanente.\n\nTodos os seus dados (favoritos, etc.) serão removidos pelo nosso administrador em até 48 horas.\n\nSe desejar, deixe um feedback (opcional):'),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: "Motivo (opcional)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            // Botão de Confirmação (Perigoso)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Cor de Perigo (UX)
              ),
              child: const Text('Sim, pedir remoção'),
              onPressed: () {
                _requestAccountDeletion(_reasonController.text.trim());
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- ETAPA 14: Lógica do Backend (Custo Zero) ---
  Future<void> _requestAccountDeletion(String reason) async {
    setState(() { _isLoading = true; });

    try {
      await supabase.from('account_deletion_requests').insert({
        'user_id': supabase.auth.currentUser!.id,
        'reason': reason.isEmpty ? null : reason,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido de remoção enviado. Deslogando...'),
          duration: Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      await supabase.auth.signOut();

      // --- A CORREÇÃO (Bug do Logout) ---
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      // --- FIM DA CORREÇÃO ---

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar pedido: $e')),
      );
      // --- A CORREÇÃO (Bug do Loading) ---
      setState(() { _isLoading = false; });
      // --- FIM DA CORREÇÃO ---
    }
  }
  // --- FIM ETAPA 14 ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: arcaPurple, // Define a cor de fundo como roxo
        foregroundColor: arcaWhite,  // Define a cor de ícones e textos como branco
        // Para garantir que a barra de status do sistema siga o esquema (opcional, mas recomendado)
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light, // Ícones pretos para o fundo roxo (iOS)
          statusBarBrightness: Brightness.light,     // Ícones brancos para o fundo roxo (Android)
        ),
        title: const Text("Editar Perfil"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _buildAvatar(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.camera_alt, size: 22, color: arcaPurple),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nome Completo",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu nome.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: arcaPurple,
                      foregroundColor: arcaWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Salvar Alterações"),
                  ),
                
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),

                // --- ETAPA 14: O Botão de "Pedir Remoção" (UI) ---
                TextButton(
                  onPressed: _showDeleteAccountDialog,
                  child: const Text(
                    "Pedir remoção da conta",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
                // --- FIM ETAPA 14 ---
              ],
            ),
          ),
        ),
      ),
    );
  }
}