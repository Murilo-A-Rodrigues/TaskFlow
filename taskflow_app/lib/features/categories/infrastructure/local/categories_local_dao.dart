import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/infrastructure/dtos/category_dto.dart';

/// DAO para gerenciar cache local de categorias usando SharedPreferences
///
/// Responsabilidades:
/// - Persistir lista de categorias em cache local
/// - Gerenciar timestamp de última sincronização
/// - Fornecer operações CRUD básicas em cache
abstract class CategoriesLocalDao {
  Future<List<CategoryDto>> listAll();
  Future<void> upsertAll(List<CategoryDto> categories);
  Future<void> upsert(CategoryDto category);
  Future<void> delete(String id);
  Future<CategoryDto?> getById(String id);
  Future<void> clear();
  Future<DateTime?> getLastSync();
  Future<void> setLastSync(DateTime timestamp);
}

/// Implementação do DAO usando SharedPreferences
class CategoriesLocalDaoSharedPrefs implements CategoriesLocalDao {
  final SharedPreferences _prefs;

  // Chave para armazenar a lista de categorias em cache
  static const String _cacheKey = 'taskflow_categories_cache_v1';

  // Chave para armazenar o timestamp da última sincronização
  static const String _lastSyncKey = 'taskflow_categories_last_sync_v1';

  CategoriesLocalDaoSharedPrefs(this._prefs);

  /// Retorna todas as categorias do cache local
  @override
  Future<List<CategoryDto>> listAll() async {
    try {
      final jsonString = _prefs.getString(_cacheKey);
      if (jsonString == null) {
        if (kDebugMode) {
          print('[CategoriesLocalDao] Cache vazio, retornando lista vazia');
        }
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final categories = jsonList
          .map((json) => CategoryDto.fromMap(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print(
          '[CategoriesLocalDao] ${categories.length} categorias carregadas do cache',
        );
      }

      return categories;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao carregar cache: $e');
        print(stack);
      }
      // Em caso de erro de deserialização, limpa o cache corrompido
      await clear();
      return [];
    }
  }

  /// Substitui todo o cache com uma nova lista de categorias
  ///
  /// Este método é tipicamente usado após uma sincronização com o servidor
  @override
  Future<void> upsertAll(List<CategoryDto> categories) async {
    try {
      final jsonList = categories.map((cat) => cat.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(_cacheKey, jsonString);

      if (kDebugMode) {
        print(
          '[CategoriesLocalDao] ${categories.length} categorias salvas no cache',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao salvar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Insere ou atualiza uma categoria específica no cache
  ///
  /// Busca a categoria existente por ID e substitui, ou adiciona se não existir
  @override
  Future<void> upsert(CategoryDto category) async {
    try {
      final categories = await listAll();
      final index = categories.indexWhere((cat) => cat.id == category.id);

      if (index != -1) {
        categories[index] = category;
        if (kDebugMode) {
          print(
            '[CategoriesLocalDao] Categoria ${category.id} atualizada no cache',
          );
        }
      } else {
        categories.add(category);
        if (kDebugMode) {
          print(
            '[CategoriesLocalDao] Categoria ${category.id} adicionada ao cache',
          );
        }
      }

      await upsertAll(categories);
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao fazer upsert: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Remove uma categoria do cache por ID
  @override
  Future<void> delete(String id) async {
    try {
      final categories = await listAll();
      final filtered = categories.where((cat) => cat.id != id).toList();

      if (categories.length != filtered.length) {
        await upsertAll(filtered);
        if (kDebugMode) {
          print('[CategoriesLocalDao] Categoria $id removida do cache');
        }
      } else {
        if (kDebugMode) {
          print('[CategoriesLocalDao] Categoria $id não encontrada no cache');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao deletar categoria: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Busca uma categoria específica por ID
  @override
  Future<CategoryDto?> getById(String id) async {
    try {
      final categories = await listAll();
      final category = categories.where((cat) => cat.id == id).firstOrNull;

      if (kDebugMode) {
        if (category != null) {
          print('[CategoriesLocalDao] Categoria $id encontrada no cache');
        } else {
          print('[CategoriesLocalDao] Categoria $id não encontrada no cache');
        }
      }

      return category;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao buscar categoria: $e');
        print(stack);
      }
      return null;
    }
  }

  /// Limpa todo o cache de categorias
  @override
  Future<void> clear() async {
    try {
      await _prefs.remove(_cacheKey);
      if (kDebugMode) {
        print('[CategoriesLocalDao] Cache limpo');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao limpar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Retorna o timestamp da última sincronização bem-sucedida
  @override
  Future<DateTime?> getLastSync() async {
    try {
      final timestamp = _prefs.getInt(_lastSyncKey);
      if (timestamp == null) {
        if (kDebugMode) {
          print(
            '[CategoriesLocalDao] Nenhuma sincronização anterior registrada',
          );
        }
        return null;
      }

      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (kDebugMode) {
        print('[CategoriesLocalDao] Última sincronização: $dateTime');
      }

      return dateTime;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesLocalDao] Erro ao buscar última sincronização: $e');
        print(stack);
      }
      return null;
    }
  }

  /// Atualiza o timestamp da última sincronização
  @override
  Future<void> setLastSync(DateTime timestamp) async {
    try {
      await _prefs.setInt(_lastSyncKey, timestamp.millisecondsSinceEpoch);
      if (kDebugMode) {
        print(
          '[CategoriesLocalDao] Timestamp de sincronização atualizado: $timestamp',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print(
          '[CategoriesLocalDao] Erro ao salvar timestamp de sincronização: $e',
        );
        print(stack);
      }
      rethrow;
    }
  }
}
