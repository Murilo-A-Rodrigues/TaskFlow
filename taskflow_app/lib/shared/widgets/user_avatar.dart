import 'dart:io';
import 'package:flutter/material.dart';

/// Widget de avatar do usuário com suporte a foto e fallback para iniciais
/// Acessível e com área clicável >= 48dp
class UserAvatar extends StatelessWidget {
  final String? photoPath;
  final String userName;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.photoPath,
    required this.userName,
    this.radius = 40,
    this.onTap,
    this.showBorder = true,
  });

  /// Retorna as iniciais do nome (máximo 2 letras)
  String _getInitials() {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }

    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se há foto válida
    bool hasPhoto = false;
    FileImage? photoImage;

    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        hasPhoto = true;
        photoImage = FileImage(file);
        print('✅ UserAvatar - Foto encontrada: $photoPath');
      } else {
        print('❌ UserAvatar - Arquivo de foto não existe: $photoPath');
      }
    } else {
      print('⚠️ UserAvatar - Caminho de foto é null ou vazio: $photoPath');
    }

    // Widget do avatar
    Widget avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor: hasPhoto
          ? Colors.grey.shade200
          : Theme.of(context).colorScheme.primary,
      backgroundImage: photoImage,
      onBackgroundImageError: hasPhoto
          ? (exception, stackTrace) {
              // Se houver erro ao carregar a imagem, mostra as iniciais
              // Debug: print('Erro ao carregar imagem: $exception');
            }
          : null,
      child: hasPhoto
          ? null
          : Text(
              _getInitials(),
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );

    // Adiciona borda se necessário
    if (showBorder) {
      avatarWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: avatarWidget,
      );
    }

    // Se não há callback de tap, retorna apenas o avatar com semântica
    if (onTap == null) {
      return Semantics(
        label: hasPhoto
            ? 'Foto de perfil de $userName'
            : 'Avatar com iniciais de $userName',
        child: avatarWidget,
      );
    }

    // Área clicável >= 48dp para acessibilidade
    final tapAreaSize = (radius * 2).clamp(48.0, double.infinity);

    return Semantics(
      label: hasPhoto
          ? 'Foto de perfil de $userName. Toque duplo para editar'
          : 'Avatar com iniciais de $userName. Toque duplo para adicionar foto',
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: tapAreaSize,
          height: tapAreaSize,
          alignment: Alignment.center,
          child: avatarWidget,
        ),
      ),
    );
  }
}

/// Preview de imagem em tamanho maior (para dialog)
class PhotoPreview extends StatelessWidget {
  final String imagePath;
  final double size;

  const PhotoPreview({super.key, required this.imagePath, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 3,
        ),
        image: DecorationImage(
          image: FileImage(File(imagePath)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
