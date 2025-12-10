import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por gerenciar fotos do usuário
/// Inclui: seleção, compressão, armazenamento e remoção de EXIF/GPS
class PhotoService {
  static const int _maxSizeKB = 200;
  static const int _imageQuality = 85;

  final ImagePicker _picker = ImagePicker();

  /// Solicita permissão de câmera ou galeria
  Future<bool> requestPermission(ImageSource source) async {
    Permission permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    // No Android 13+, use Permission.photos ao invés de Permission.storage
    if (Platform.isAndroid && source == ImageSource.gallery) {
      permission = Permission.photos;
    }

    PermissionStatus status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  /// Seleciona uma imagem da câmera ou galeria
  /// Retorna o caminho do arquivo original ou null se cancelado
  Future<String?> pickImage(ImageSource source) async {
    try {
      // Solicitar permissão
      bool hasPermission = await requestPermission(source);
      if (!hasPermission) {
        if (kDebugMode) {
          print(
            'Permissão negada para acessar ${source == ImageSource.camera ? 'câmera' : 'galeria'}',
          );
        }
        return null;
      }

      // Selecionar imagem
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image == null) return null;
      return image.path;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao selecionar imagem: $e');
      }
      return null;
    }
  }

  /// Comprime a imagem e remove metadados EXIF/GPS
  /// Retorna o caminho do arquivo comprimido
  Future<String?> compressImage(String imagePath) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Comprime a imagem removendo metadados EXIF
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: _imageQuality,
        minWidth: 512,
        minHeight: 512,
        format: CompressFormat.jpeg,
        keepExif: false, // Remove EXIF/GPS
      );

      if (result == null) return null;

      // Verifica o tamanho
      final file = File(result.path);
      final sizeKB = await file.length() / 1024;

      if (kDebugMode) {
        print('Imagem comprimida: ${sizeKB.toStringAsFixed(2)} KB');
      }

      // Se ainda estiver muito grande, comprime mais
      if (sizeKB > _maxSizeKB) {
        final newQuality = (_imageQuality * (_maxSizeKB / sizeKB)).round();
        final secondPass = await FlutterImageCompress.compressAndGetFile(
          result.path,
          targetPath,
          quality: newQuality.clamp(50, 100),
          format: CompressFormat.jpeg,
          keepExif: false,
        );
        return secondPass?.path;
      }

      return result.path;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao comprimir imagem: $e');
      }
      return null;
    }
  }

  /// Salva a foto no diretório permanente do app
  /// Retorna o caminho final da foto salva
  Future<String?> savePhoto(String compressedImagePath) async {
    try {
      if (kDebugMode)
        print('📁 PhotoService - Iniciando savePhoto: $compressedImagePath');

      // Verifica se o arquivo temporário existe
      final tempFile = File(compressedImagePath);
      if (!await tempFile.exists()) {
        if (kDebugMode)
          print(
            '❌ PhotoService - Arquivo temporário não existe: $compressedImagePath',
          );
        return null;
      }

      // Estratégia robusta: usar cache directory que sempre tem permissão de escrita
      final appDir = await getApplicationDocumentsDirectory();
      if (kDebugMode) print('📂 PhotoService - App directory: ${appDir.path}');

      Directory photoDir;
      try {
        photoDir = Directory(path.join(appDir.path, 'user_photos'));
        if (kDebugMode)
          print('📂 PhotoService - Tentando usar Documents: ${photoDir.path}');

        // Testa se consegue escrever no diretório documents
        if (!await photoDir.exists()) {
          await photoDir.create(recursive: true);
        }
      } catch (e) {
        // Fallback: usar cache directory se documents falhar
        if (kDebugMode)
          print('⚠️ PhotoService - Falha no Documents, usando Cache: $e');
        final cacheDir = await getTemporaryDirectory();
        photoDir = Directory(path.join(cacheDir.path, 'user_photos'));
        if (!await photoDir.exists()) {
          await photoDir.create(recursive: true);
        }
      }

      // Remove foto anterior se existir
      try {
        final oldPhotoPath = await getPhotoPath();
        if (oldPhotoPath != null && File(oldPhotoPath).existsSync()) {
          if (kDebugMode)
            print('🗑️ PhotoService - Removendo foto anterior: $oldPhotoPath');
          await File(oldPhotoPath).delete();
        }
      } catch (e) {
        if (kDebugMode)
          print(
            '⚠️ PhotoService - Erro ao remover foto anterior (continuando): $e',
          );
      }

      // Copia a foto comprimida para o diretório permanente
      final fileName =
          'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final finalPath = path.join(photoDir.path, fileName);
      if (kDebugMode) print('📋 PhotoService - Copiando para: $finalPath');

      // Usa readAsBytes + writeAsBytes para maior compatibilidade
      final bytes = await tempFile.readAsBytes();
      final finalFile = File(finalPath);
      await finalFile.writeAsBytes(bytes);

      if (kDebugMode)
        print(
          '✅ PhotoService - Arquivo salvo com sucesso (${bytes.length} bytes)',
        );

      // Remove o arquivo temporário
      try {
        if (kDebugMode)
          print('🗑️ PhotoService - Removendo arquivo temporário');
        await tempFile.delete();
      } catch (e) {
        if (kDebugMode)
          print('⚠️ PhotoService - Erro ao remover temp (não crítico): $e');
      }

      // Verifica se o arquivo final existe
      if (await finalFile.exists()) {
        final finalSize = await finalFile.length();
        if (kDebugMode)
          print(
            '🎉 PhotoService - savePhoto concluído: $finalPath (${finalSize} bytes)',
          );
        return finalPath;
      } else {
        if (kDebugMode) print('❌ PhotoService - Arquivo final não foi criado');
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 PhotoService - Erro crítico ao salvar foto: $e');
        print('📋 Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Recupera o caminho da foto do usuário através do PreferencesService
  Future<String?> getPhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Usa a mesma chave que o PreferencesService
      final photoPath = prefs.getString('user_photo_path');

      if (kDebugMode) print('📖 PhotoService - getPhotoPath lendo: $photoPath');

      // Verifica se o arquivo existe
      if (photoPath != null && File(photoPath).existsSync()) {
        return photoPath;
      }

      // Se não existe, remove a referência
      if (photoPath != null) {
        await prefs.remove('user_photo_path');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao recuperar caminho da foto: $e');
      }
      return null;
    }
  }

  /// Remove a foto do usuário
  Future<bool> deletePhoto() async {
    try {
      final photoPath = await getPhotoPath();
      if (photoPath != null && File(photoPath).existsSync()) {
        await File(photoPath).delete();
      }

      final prefs = await SharedPreferences.getInstance();
      // Usa a mesma chave que o PreferencesService
      await prefs.remove('user_photo_path');

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao deletar foto: $e');
      }
      return false;
    }
  }

  /// Fluxo completo: selecionar, comprimir e salvar
  Future<String?> pickCompressAndSave(ImageSource source) async {
    if (kDebugMode) print('🔄 PhotoService - Iniciando fluxo completo');

    final imagePath = await pickImage(source);
    if (imagePath == null) {
      if (kDebugMode) print('❌ PhotoService - pickImage retornou null');
      return null;
    }
    if (kDebugMode) print('✅ PhotoService - Imagem selecionada: $imagePath');

    final compressedPath = await compressImage(imagePath);
    if (compressedPath == null) {
      if (kDebugMode) print('❌ PhotoService - compressImage retornou null');
      return null;
    }
    if (kDebugMode)
      print('✅ PhotoService - Imagem comprimida: $compressedPath');

    final savedPath = await savePhoto(compressedPath);
    if (savedPath == null) {
      if (kDebugMode) print('❌ PhotoService - savePhoto retornou null');
      return null;
    }
    if (kDebugMode) print('✅ PhotoService - Imagem salva: $savedPath');

    return savedPath;
  }
}
