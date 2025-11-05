import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config_service.dart';

/// Serviço para gerenciar conexão com Supabase
class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// Inicializa o Supabase
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!ConfigService.hasValidSupabaseConfig) {
        throw Exception('Configuração do Supabase inválida. Verifique o arquivo .env');
      }

      await Supabase.initialize(
        url: ConfigService.supabaseUrl,
        anonKey: ConfigService.supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;
      
      if (ConfigService.isLoggingEnabled) {
        print('✅ SupabaseService - Inicializado com sucesso');
        print('   URL: ${ConfigService.supabaseUrl}');
      }
    } catch (e) {
      print('❌ SupabaseService - Erro na inicialização: $e');
      rethrow;
    }
  }

  /// Retorna o cliente Supabase
  static SupabaseClient get client {
    if (!_isInitialized || _client == null) {
      throw Exception('SupabaseService não foi inicializado. Chame SupabaseService.initialize() primeiro.');
    }
    return _client!;
  }

  /// Verifica se está inicializado
  static bool get isInitialized => _isInitialized;

  /// Exemplo: Criar uma tabela de tarefas
  static Future<Map<String, dynamic>?> createTask({
    required String title,
    required String description,
    String? category,
    DateTime? dueDate,
  }) async {
    try {
      final response = await client
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'category': category,
            'due_date': dueDate?.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'is_completed': false,
          })
          .select()
          .single();

      if (ConfigService.isLoggingEnabled) {
        print('✅ Task criada: ${response['id']}');
      }

      return response;
    } catch (e) {
      print('❌ Erro ao criar task: $e');
      return null;
    }
  }

  /// Exemplo: Buscar todas as tarefas
  static Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final response = await client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);

      if (ConfigService.isLoggingEnabled) {
        print('✅ ${response.length} tasks encontradas');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao buscar tasks: $e');
      return [];
    }
  }

  /// Exemplo: Atualizar uma tarefa
  static Future<bool> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      await client
          .from('tasks')
          .update(updates)
          .eq('id', id);

      if (ConfigService.isLoggingEnabled) {
        print('✅ Task atualizada: $id');
      }

      return true;
    } catch (e) {
      print('❌ Erro ao atualizar task: $e');
      return false;
    }
  }

  /// Exemplo: Deletar uma tarefa
  static Future<bool> deleteTask(String id) async {
    try {
      await client
          .from('tasks')
          .delete()
          .eq('id', id);

      if (ConfigService.isLoggingEnabled) {
        print('✅ Task deletada: $id');
      }

      return true;
    } catch (e) {
      print('❌ Erro ao deletar task: $e');
      return false;
    }
  }

  /// Upload de arquivos (ex: imagens de avatar)
  static Future<String?> uploadFile({
    required String bucketName,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await client.storage
          .from(bucketName)
          .uploadBinary(path, Uint8List.fromList(fileBytes));

      final publicUrl = client.storage
          .from(bucketName)
          .getPublicUrl(path);

      if (ConfigService.isLoggingEnabled) {
        print('✅ Arquivo uploaded: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      print('❌ Erro no upload: $e');
      return null;
    }
  }

  /// Buscar URL pública de um arquivo
  static String getPublicUrl(String bucketName, String path) {
    return client.storage.from(bucketName).getPublicUrl(path);
  }

  /// Exemplo de autenticação (se necessário)
  static Future<bool> signInAnonymously() async {
    try {
      await client.auth.signInAnonymously();
      
      if (ConfigService.isLoggingEnabled) {
        print('✅ Login anônimo realizado');
      }
      
      return true;
    } catch (e) {
      print('❌ Erro no login anônimo: $e');
      return false;
    }
  }

  /// Verificar se usuário está logado
  static bool get isLoggedIn {
    return client.auth.currentUser != null;
  }

  /// Obter ID do usuário atual
  static String? get currentUserId {
    return client.auth.currentUser?.id;
  }
}