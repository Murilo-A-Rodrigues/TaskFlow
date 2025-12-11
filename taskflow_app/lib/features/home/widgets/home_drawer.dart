import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage/preferences_service.dart';
import '../../../services/user/user_profile_service.dart';
import '../../../services/integrations/photo_service.dart';
import '../../../features/auth/application/auth_service.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/theme_controller.dart';

/// Drawer da tela inicial com perfil do usuário e opções de navegação
/// Permite editar nome, gerenciar foto e acessar configurações
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<UserProfileService>();
    final userName = profileService.userName ?? 'Usuário';
    final userPhotoPath = profileService.userPhotoPath;

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
                      child: UserAvatar(
                        radius: 28,
                        onTap: () => _showPhotoOptions(context),
                        showBorder: true,
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
                      userPhotoPath != null
                          ? 'Toque para alterar foto'
                          : 'Toque para adicionar foto',
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
          // Toggle de Tema
          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              final isDark = themeController.isDarkMode;
              final isSystem = themeController.isSystemMode;

              return SwitchListTile.adaptive(
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Tema escuro'),
                subtitle: Text(
                  isSystem
                      ? 'Seguindo o sistema'
                      : (isDark ? 'Ativado' : 'Desativado'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                value: isDark,
                onChanged: (value) {
                  if (value) {
                    themeController.setThemeMode(ThemeMode.dark);
                  } else {
                    themeController.setThemeMode(ThemeMode.light);
                  }
                },
                // Adiciona um botão de reset para o modo sistema
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
              );
            },
          ),
          // Botão para voltar ao modo sistema
          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              if (themeController.isSystemMode) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextButton.icon(
                  onPressed: () {
                    themeController.setThemeMode(ThemeMode.system);
                  },
                  icon: const Icon(Icons.settings_suggest, size: 16),
                  label: const Text(
                    'Seguir tema do sistema',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              );
            },
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
    final profileService = context.read<UserProfileService>();
    final hasPhoto = profileService.userPhotoPath != null;

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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                title: const Text(
                  'Remover Foto',
                  style: TextStyle(color: Colors.red),
                ),
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

      // Obter serviços necessários ANTES da seleção
      final profileService = Provider.of<UserProfileService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(
        context,
        listen: false,
      );

      // Selecionar e processar imagem
      final photoService = PhotoService();
      final compressedPath = await photoService.pickCompressAndSave(source);

      if (compressedPath == null) {
        print('❌ Nenhuma imagem selecionada');
        return;
      }

      // Salvar foto usando UserProfileService
      await profileService.updatePhoto(
        compressedPath,
        authService.userId!,
        isGuest: authService.isGuest,
      );
      
      print('✅ Foto atualizada com sucesso');

      
      print('✅ Foto atualizada com sucesso');

      // Mostrar mensagem de sucesso
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada e sincronizada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('💥 Erro ao processar foto: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
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
      barrierDismissible: false,
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

              final profileService = context.read<UserProfileService>();
              final authService = context.read<AuthService>();
              
              await profileService.removePhoto(
                authService.userId!,
                isGuest: authService.isGuest,
              );

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
    final photoPath = context.read<UserProfileService>().userPhotoPath;
    if (photoPath == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
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
    final profileService = context.read<UserProfileService>();
    final controller = TextEditingController(text: profileService.userName);

    showDialog(
      context: context,
      barrierDismissible: false,
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
                final authService = context.read<AuthService>();
                await profileService.updateName(
                  newName,
                  authService.userId!,
                  isGuest: authService.isGuest,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome atualizado e sincronizado!'),
                    ),
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
