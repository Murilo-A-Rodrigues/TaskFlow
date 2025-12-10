import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/user_dto.dart';
import 'user_local_dto.dart';

/// Implementação de UserLocalDto usando SharedPreferences
///
/// Persiste DTOs de usuários em formato JSON no SharedPreferences.
/// Suporta operações de upsert, listagem, busca por id e limpeza.
///
/// Tratamento de erros:
/// - Em caso de dados corrompidos, limpa o cache e retorna valores padrão
/// - Logs de erro são impressos para diagnóstico
class UserLocalDtoSharedPrefs implements UserLocalDto {
  /// Chave de armazenamento no SharedPreferences
  static const String _cacheKey = 'users_cache_v1';

  /// Getter privado para obter instância do SharedPreferences
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> upsertAll(List<UserDto> dtos) async {
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
          print('⚠️ Dados corrompidos no cache de usuários, reiniciando: $e');
        }
      }

      // Upsert: atualiza existentes ou adiciona novos
      for (final dto in dtos) {
        current[dto.id] = dto.toMap();
      }

      // Salva lista atualizada
      final merged = current.values.toList();
      await prefs.setString(_cacheKey, jsonEncode(merged));

      print(
        '✅ Cache de usuários atualizado: ${dtos.length} registro(s), total: ${merged.length}',
      );
    } catch (e) {
      print('❌ Erro ao fazer upsert de usuários: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserDto>> listAll() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cacheKey);

      // Retorna lista vazia se não houver dados
      if (raw == null || raw.isEmpty) {
        return [];
      }

      // Decodifica e converte para DTOs
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      final users = jsonList
          .map(
            (json) => UserDto.fromMap(Map<String, dynamic>.from(json as Map)),
          )
          .toList();

      print('📋 Cache de usuários carregado: ${users.length} registro(s)');
      return users;
    } catch (e) {
      print('❌ Erro ao listar usuários do cache: $e');
      // Em caso de erro, limpa cache corrompido e retorna vazio
      await clear();
      return [];
    }
  }

  @override
  Future<UserDto?> getById(String id) async {
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
          return UserDto.fromMap(m);
        }
      }

      // Não encontrado
      return null;
    } catch (e) {
      print('❌ Erro ao buscar usuário por id ($id): $e');
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_cacheKey);
      print('🗑️ Cache de usuários limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de usuários: $e');
      rethrow;
    }
  }
}
