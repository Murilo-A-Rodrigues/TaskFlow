import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage/preferences_service.dart';
import '../../../services/integrations/photo_service.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Drawer da tela inicial com perfil do usuário e opções de navegação
/// Permite editar nome, gerenciar foto e acessar configurações
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final prefsService = context.watch<PreferencesService>();
    final userName = prefsService.userName;
    final userPhotoPath = prefsService.userPhotoPath;
    
    // Debug log para rastrear o caminho da foto
    print('🖼️ HomeDrawer - userPhotoPath: $userPhotoPath');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Avatar com espaçamento adequado
                    Center(
                      child: Consumer<PreferencesService>(
                        builder: (context, prefs, child) {
                          print('🔄 Consumer rebuilding UserAvatar with path: ${prefs.userPhotoPath}');
                          return UserAvatar(
                            photoPath: prefs.userPhotoPath,
                            userName: prefs.userName,
                            radius: 28,
                            onTap: () => _showPhotoOptions(context),
                            showBorder: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nome do usuário
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Texto de instrução
                    Text(
                      userPhotoPath != null ? 'Toque para alterar foto' : 'Toque para adicionar foto',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar Nome'),
            onTap: () => _showEditNameDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Gerenciar Foto'),
            onTap: () => _showPhotoOptions(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            onTap: () {
              Navigator.of(context).pop();
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    final prefsService = context.read<PreferencesService>();
    final hasPhoto = prefsService.userPhotoPath != null;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Gerenciar Foto de Perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Visualizar Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPhotoPreview(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover Foto', style: TextStyle(color: Colors.red)),
                onTap: () => _removePhoto(context),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();
    
    try {
      print('📸 Iniciando seleção de imagem...');
      
      // SOLUÇÃO: Obter a referência do Provider ANTES da seleção de imagem
      print('🚀 PASSO 1: Obtendo PreferencesService ANTES da seleção...');
      final prefsService = Provider.of<PreferencesService>(context, listen: false);
      print('✅ PreferencesService obtido ANTES da seleção');
      
      print('🚀 PASSO 2: Iniciando seleção e processamento...');
      final photoService = PhotoService();
      final compressedPath = await photoService.pickCompressAndSave(source);
      
      print('📦 Caminho da foto processada: $compressedPath');
      
      // Agora usar a referência já obtida, não o contexto
      try {
        print('🚀 PASSO 3: Verificando caminho...');
        if (compressedPath == null) {
          print('❌ Caminho é null, não pode salvar');
          return;
        }
        print('✅ Caminho válido: $compressedPath');
        
        print('🚀 PASSO 4: Salvando caminho (usando referência obtida antes)...');
        await prefsService.setUserPhotoPath(compressedPath);
        print('✅ Caminho salvo no PreferencesService');
        
        print('🚀 PASSO 5: Verificando salvamento...');
        final savedPath = prefsService.userPhotoPath;
        print('🔍 Verificação: caminho recuperado = $savedPath');
        
        if (savedPath == compressedPath) {
          print('🎉 SUCESSO TOTAL! Foto salva e verificada');
        } else {
          print('⚠️ ATENÇÃO: Caminho salvo difere do esperado');
        }
        
      } catch (stepError, stepStack) {
        print('💥 ERRO em um dos passos: $stepError');
        print('📋 Stack trace do passo: $stepStack');
      }
      
      // Mostrar mensagem de sucesso se tudo funcionou
      if (compressedPath != null && context.mounted) {
        print('🎉 Mostrando mensagem de sucesso...');
        
        // Pequeno delay para garantir que o SharedPreferences foi atualizado
        await Future.delayed(const Duration(milliseconds: 100));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        print('✅ Mensagem de sucesso exibida');
      }
      
    } catch (e) {
      print('💥 Erro inesperado ao processar foto: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePhoto(BuildContext context) {
    Navigator.of(context).pop();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Foto'),
        content: const Text('Deseja realmente remover sua foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final prefsService = context.read<PreferencesService>();
              await prefsService.setUserPhotoPath(null);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Foto removida com sucesso!')),
                );
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showPhotoPreview(BuildContext context) {
    final photoPath = context.read<PreferencesService>().userPhotoPath;
    if (photoPath == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(photoPath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final prefsService = context.read<PreferencesService>();
    final controller = TextEditingController(text: prefsService.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome',
            hintText: 'Digite seu nome',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await prefsService.setUserName(newName);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome atualizado com sucesso!')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TaskFlow',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 TaskFlow Team',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Aplicativo de gerenciamento de tarefas para aumentar sua produtividade.',
          ),
        ),
      ],
    );
  }
}