import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_service.dart';
import '../storage/preferences_service.dart';

/// Serviço para gerenciar perfil do usuário (nome e foto)
/// Sincroniza com Supabase para persistência entre dispositivos
class UserProfileService extends ChangeNotifier {
  final PreferencesService _prefsService;
  
  String? _userName;
  String? _userPhotoPath;
  bool _isLoading = false;

  UserProfileService(this._prefsService);

  String? get userName => _userName;
  String? get userPhotoPath => _userPhotoPath;
  bool get isLoading => _isLoading;

  /// Inicializa o serviço carregando dados locais e sincronizando
  Future<void> initialize(String userId, {bool isGuest = false}) async {
    if (kDebugMode) print('📱 UserProfileService: Inicializando para userId=$userId');
    
    // Carrega dados locais primeiro
    _userName = _prefsService.userName;
    _userPhotoPath = _prefsService.userPhotoPath;
    notifyListeners();

    // Se for convidado, não sincroniza com servidor
    if (isGuest) {
      if (kDebugMode) print('👤 Modo convidado: usando apenas armazenamento local');
      return;
    }

    // Sincroniza com Supabase
    await _syncFromServer(userId);
  }

  /// Carrega perfil do servidor e atualiza cache local
  Future<void> _syncFromServer(String userId) async {
    try {
      if (kDebugMode) print('🔄 Sincronizando perfil do servidor...');
      
      final response = await SupabaseService.client
          .from('users')
          .select('name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final serverName = response['name'] as String?;
        final serverAvatarUrl = response['avatar_url'] as String?;

        if (kDebugMode) {
          print('📥 Perfil recebido do servidor:');
          print('   Nome: $serverName');
          print('   Avatar URL: $serverAvatarUrl');
        }

        // Atualiza nome se diferente
        if (serverName != null && serverName != _userName) {
          _userName = serverName;
          await _prefsService.setUserName(serverName);
          if (kDebugMode) print('✅ Nome atualizado: $serverName');
        }

        // Baixa foto se houver URL
        if (serverAvatarUrl != null && serverAvatarUrl.isNotEmpty) {
          // Verifica se já tem foto local válida
          final currentPhotoPath = _prefsService.userPhotoPath;
          final needsDownload = currentPhotoPath == null || 
                                currentPhotoPath.isEmpty || 
                                !await File(currentPhotoPath).exists();
          
          if (needsDownload) {
            if (kDebugMode) print('📥 Foto local não encontrada, baixando do servidor...');
            await _downloadAndSaveAvatar(serverAvatarUrl, userId);
          } else {
            if (kDebugMode) print('✅ Foto local já existe: $currentPhotoPath');
            _userPhotoPath = currentPhotoPath;
          }
        } else {
          if (kDebugMode) print('ℹ️ Usuário não possui foto no servidor');
        }

        notifyListeners();
        if (kDebugMode) print('✅ Perfil sincronizado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao sincronizar perfil: $e');
    }
  }

  /// Baixa avatar do servidor e salva localmente
  Future<void> _downloadAndSaveAvatar(String url, String userId) async {
    try {
      if (kDebugMode) print('📥 Baixando avatar de: $url');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        // Usa userId para nome consistente
        final fileName = 'profile_$userId.jpg';
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(response.bodyBytes);
        
        _userPhotoPath = file.path;
        await _prefsService.setUserPhotoPath(file.path);
        
        if (kDebugMode) print('✅ Avatar salvo localmente: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao baixar avatar: $e');
    }
  }

  /// Atualiza o nome do usuário
  Future<void> updateName(String name, String userId, {bool isGuest = false}) async {
    if (name.trim().isEmpty) {
      if (kDebugMode) print('⚠️ Nome vazio, ignorando atualização');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Salva localmente
      _userName = name;
      await _prefsService.setUserName(name);
      
      if (kDebugMode) print('💾 Nome salvo localmente: $name');

      // Se não for convidado, salva no servidor
      if (!isGuest) {
        await SupabaseService.client
            .from('users')
            .update({'name': name, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', userId);
        
        if (kDebugMode) print('☁️ Nome salvo no Supabase');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao atualizar nome: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Atualiza a foto do perfil
  Future<void> updatePhoto(String photoPath, String userId, {bool isGuest = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Salva localmente
      _userPhotoPath = photoPath;
      await _prefsService.setUserPhotoPath(photoPath);
      
      if (kDebugMode) print('💾 Foto salva localmente: $photoPath');

      // Se não for convidado, faz upload para Supabase Storage
      if (!isGuest) {
        if (kDebugMode) print('🔄 Iniciando upload para Supabase...');
        final avatarUrl = await _uploadAvatarToStorage(photoPath, userId);
        if (avatarUrl != null) {
          if (kDebugMode) print('🔄 Salvando URL no banco de dados...');
          await SupabaseService.client
              .from('users')
              .update({
                'avatar_url': avatarUrl,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', userId);
          
          if (kDebugMode) print('☁️ Avatar URL salvo no Supabase: $avatarUrl');
        } else {
          if (kDebugMode) print('⚠️ Upload falhou, mas foto está salva localmente');
        }
      } else {
        if (kDebugMode) print('👤 Modo convidado: foto salva apenas localmente');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao atualizar foto: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Faz upload da foto para o Supabase Storage
  Future<String?> _uploadAvatarToStorage(String photoPath, String userId) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) {
        if (kDebugMode) print('⚠️ Arquivo não existe: $photoPath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final fileName = 'avatar_$userId.jpg';
      
      if (kDebugMode) {
        print('📤 Fazendo upload de avatar:');
        print('   Arquivo: $fileName');
        print('   Tamanho: ${bytes.length} bytes');
        print('   Bucket: avatars');
      }

      // Upload para bucket 'avatars'
      final uploadResponse = await SupabaseService.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(upsert: true));

      if (kDebugMode) print('✅ Upload concluído: $uploadResponse');

      // Retorna URL pública
      final publicUrl = SupabaseService.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      if (kDebugMode) print('✅ URL pública gerada: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erro ao fazer upload de avatar: $e');
        print('📋 Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Remove a foto do perfil
  Future<void> removePhoto(String userId, {bool isGuest = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Remove localmente
      _userPhotoPath = null;
      await _prefsService.setUserPhotoPath(null);
      
      if (kDebugMode) print('🗑️ Foto removida localmente');

      // Se não for convidado, remove do servidor
      if (!isGuest) {
        await SupabaseService.client
            .from('users')
            .update({
              'avatar_url': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
        
        if (kDebugMode) print('☁️ Avatar URL removido do Supabase');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao remover foto: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Limpa todos os dados do perfil (usado no logout)
  Future<void> clearProfile() async {
    _userName = null;
    _userPhotoPath = null;
    await _prefsService.setUserName('');
    await _prefsService.setUserPhotoPath(null);
    notifyListeners();
    if (kDebugMode) print('🧹 Perfil limpo');
  }
}
