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
  static const String _photoPathKey = 'userPhotoPath';
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
          print('Permissão negada para acessar ${source == ImageSource.camera ? 'câmera' : 'galeria'}');
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
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(path.join(appDir.path, 'user_photos'));
      
      // Cria o diretório se não existir
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      // Remove foto anterior se existir
      final oldPhotoPath = await getPhotoPath();
      if (oldPhotoPath != null && File(oldPhotoPath).existsSync()) {
        await File(oldPhotoPath).delete();
      }

      // Copia a foto comprimida para o diretório permanente
      final fileName = 'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final finalPath = path.join(photoDir.path, fileName);
      await File(compressedImagePath).copy(finalPath);

      // Salva o caminho no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPathKey, finalPath);

      // Remove o arquivo temporário
      await File(compressedImagePath).delete();

      return finalPath;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar foto: $e');
      }
      return null;
    }
  }

  /// Recupera o caminho da foto do usuário
  Future<String?> getPhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString(_photoPathKey);
      
      // Verifica se o arquivo existe
      if (photoPath != null && File(photoPath).existsSync()) {
        return photoPath;
      }
      
      // Se não existe, remove a referência
      if (photoPath != null) {
        await prefs.remove(_photoPathKey);
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
      await prefs.remove(_photoPathKey);
      
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
    final imagePath = await pickImage(source);
    if (imagePath == null) return null;

    final compressedPath = await compressImage(imagePath);
    if (compressedPath == null) return null;

    final savedPath = await savePhoto(compressedPath);
    return savedPath;
  }
}
