import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/comment_dto.dart';
import 'comment_local_dto.dart';

/// Implementação de CommentLocalDto usando SharedPreferences
/// 
/// Persiste DTOs de comentários em formato JSON no SharedPreferences.
/// Suporta operações de upsert, listagem, busca por id e limpeza.
/// 
/// Tratamento de erros:
/// - Em caso de dados corrompidos, limpa o cache e retorna valores padrão
/// - Logs de erro são impressos para diagnóstico
class CommentLocalDtoSharedPrefs implements CommentLocalDto {
  /// Chave de armazenamento no SharedPreferences
  static const String _cacheKey = 'comments_cache_v1';

  /// Getter privado para obter instância do SharedPreferences
  Future<SharedPreferences> get _prefs async => 
      SharedPreferences.getInstance();

  @override
  Future<void> upsertAll(List<CommentDto> dtos) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cacheKey);
      
      // Map para indexar por id e facilitar upsert
      final Map<String, Map<String, dynamic>> current = {};
      
      // Carrega dados existentes se houver
      if (raw != null && raw.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
          for (final e in list) {
            final m = Map<String, dynamic>.from(e as Map);
            current[m['id'] as String] = m;
          }
        } catch (e) {
          // Dados corrompidos - ignora e sobrescreve
          print('⚠️ Dados corrompidos no cache de comentários, reiniciando: $e');
        }
      }

      // Upsert: atualiza existentes ou adiciona novos
      for (final dto in dtos) {
        current[dto.id] = dto.toMap();
      }

      // Salva lista atualizada
      final merged = current.values.toList();
      await prefs.setString(_cacheKey, jsonEncode(merged));
      
      print('✅ Cache de comentários atualizado: ${dtos.length} registro(s), total: ${merged.length}');
    } catch (e) {
      print('❌ Erro ao fazer upsert de comentários: $e');
      rethrow;
    }
  }

  @override
  Future<List<CommentDto>> listAll() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cacheKey);
      
      // Retorna lista vazia se não houver dados
      if (raw == null || raw.isEmpty) {
        return [];
      }

      // Decodifica e converte para DTOs
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      final comments = jsonList
          .map((json) => CommentDto.fromMap(Map<String, dynamic>.from(json as Map)))
          .toList();
      
      print('📋 Cache de comentários carregado: ${comments.length} registro(s)');
      return comments;
      
    } catch (e) {
      print('❌ Erro ao listar comentários do cache: $e');
      // Em caso de erro, limpa cache corrompido e retorna vazio
      await clear();
      return [];
    }
  }

  @override
  Future<CommentDto?> getById(String id) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cacheKey);
      
      if (raw == null || raw.isEmpty) {
        return null;
      }

      // Busca o item com o id especificado
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      for (final item in jsonList) {
        final m = Map<String, dynamic>.from(item as Map);
        if (m['id'] == id) {
          return CommentDto.fromMap(m);
        }
      }
      
      // Não encontrado
      return null;
      
    } catch (e) {
      print('❌ Erro ao buscar comentário por id ($id): $e');
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_cacheKey);
      print('🗑️ Cache de comentários limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de comentários: $e');
      rethrow;
    }
  }
}
