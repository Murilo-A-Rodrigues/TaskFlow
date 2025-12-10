import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/provider_dto.dart';

/// DAO local para cache de provedores usando SharedPreferences
class ProvidersLocalDao {
  static const String _cacheKey = 'taskflow_providers_cache_v1';
  static const String _lastSyncKey = 'taskflow_providers_last_sync_v1';

  /// Insere ou atualiza múltiplos provedores no cache.
  Future<void> upsertAll(List<ProviderDto> dtos) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carrega cache existente
      final existing = await listAll();
      final existingMap = {for (var dto in existing) dto.id: dto};

      // Mescla com novos dados
      for (var dto in dtos) {
        existingMap[dto.id] = dto;
      }

      // Salva de volta
      final jsonList = existingMap.values.map((dto) => dto.toMap()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));

      if (kDebugMode) {
        print('[ProvidersLocalDao] upsertAll: ${dtos.length} items salvos');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersLocalDao] Erro ao salvar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Lista todos os provedores do cache.
  Future<List<ProviderDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final dtos = jsonList
          .map((json) => ProviderDto.fromMap(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('[ProvidersLocalDao] listAll: ${dtos.length} items carregados');
      }

      return dtos;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersLocalDao] Erro ao carregar cache: $e');
        print(stack);
      }
      return [];
    }
  }

  /// Busca provedor por ID.
  Future<ProviderDto?> getById(String id) async {
    try {
      final all = await listAll();
      return all.where((dto) => dto.id == id).firstOrNull;
    } catch (e) {
      if (kDebugMode) {
        print('[ProvidersLocalDao] Erro ao buscar por ID: $e');
      }
      return null;
    }
  }

  /// Limpa todo o cache.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastSyncKey);

      if (kDebugMode) {
        print('[ProvidersLocalDao] Cache limpo');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersLocalDao] Erro ao limpar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Obtém timestamp da última sincronização.
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isoString = prefs.getString(_lastSyncKey);

      if (isoString == null) return null;

      return DateTime.parse(isoString);
    } catch (e) {
      if (kDebugMode) {
        print('[ProvidersLocalDao] Erro ao ler lastSync: $e');
      }
      return null;
    }
  }

  /// Atualiza timestamp da última sincronização.
  Future<void> setLastSync(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());

      if (kDebugMode) {
        print('[ProvidersLocalDao] lastSync atualizado: $timestamp');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersLocalDao] Erro ao salvar lastSync: $e');
        print(stack);
      }
      rethrow;
    }
  }
}
