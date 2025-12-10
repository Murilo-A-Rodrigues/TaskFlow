import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/infrastructure/dtos/category_dto.dart';
import 'categories_remote_api.dart';

/// Implementação do datasource remoto usando Supabase
///
/// Responsável por toda comunicação com o backend Supabase para operações
/// de sincronização de categorias
class SupabaseCategoriesRemoteDatasource implements CategoriesRemoteApi {
  final SupabaseClient _client;

  // Nome da tabela no Supabase
  static const String _tableName = 'categories';

  SupabaseCategoriesRemoteDatasource(this._client);

  /// Busca categorias do Supabase com paginação e sincronização incremental
  ///
  /// Suporta:
  /// - Paginação usando offset/limit
  /// - Sincronização incremental usando timestamp 'since'
  /// - Ordenação por updated_at para garantir consistência
  @override
  Future<RemotePage<CategoryDto>> fetchCategories({
    PageCursor? cursor,
    DateTime? since,
  }) async {
    try {
      if (kDebugMode) {
        print('[SupabaseCategoriesRemote] Iniciando fetch de categorias');
        print(
          '[SupabaseCategoriesRemote] Cursor: offset=${cursor?.offset ?? 0}, limit=${cursor?.limit ?? 100}',
        );
        if (since != null) {
          print('[SupabaseCategoriesRemote] Since: $since (sync incremental)');
        }
      }

      // Configuração padrão de paginação
      final offset = cursor?.offset ?? 0;
      final limit = cursor?.limit ?? 100;

      // Inicia a query na tabela de categorias
      var query = _client
          .from(_tableName)
          .select()
          .order('updated_at', ascending: true)
          .range(offset, offset + limit - 1);

      // Executa a query
      final response = await query;

      // Aplica filtro de sincronização incremental manualmente se fornecido
      List<dynamic> filteredResponse = response;
      if (since != null) {
        filteredResponse = response.where((item) {
          final updatedAt = DateTime.parse(item['updated_at']);
          return updatedAt.isAfter(since) || updatedAt.isAtSameMomentAs(since);
        }).toList();

        if (kDebugMode) {
          print(
            '[SupabaseCategoriesRemote] Aplicando filtro: updated_at >= ${since.toIso8601String()}',
          );
          print(
            '[SupabaseCategoriesRemote] Filtrados ${filteredResponse.length} de ${response.length} items',
          );
        }
      }

      if (kDebugMode) {
        print(
          '[SupabaseCategoriesRemote] Resposta recebida: ${filteredResponse.length} categorias',
        );
      }

      // Converte resposta para DTOs
      final categories = filteredResponse
          .map((json) => CategoryDto.fromMap(json as Map<String, dynamic>))
          .toList();

      // Determina se há mais páginas
      // Se retornou o limite completo, provavelmente há mais dados
      final hasMore = categories.length == limit;
      final nextCursor = hasMore
          ? PageCursor(offset: offset + limit, limit: limit)
          : null;

      if (kDebugMode) {
        print(
          '[SupabaseCategoriesRemote] Categorias processadas: ${categories.length}',
        );
        print(
          '[SupabaseCategoriesRemote] Há mais páginas? ${hasMore ? 'Sim' : 'Não'}',
        );
      }

      return RemotePage(data: categories, nextCursor: nextCursor);
    } catch (e, stack) {
      if (kDebugMode) {
        print('[SupabaseCategoriesRemote] Erro ao buscar categorias: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Envia categorias locais para o Supabase (upsert)
  ///
  /// Usa a operação upsert do Supabase que:
  /// - Cria novos registros se não existirem
  /// - Atualiza registros existentes (baseado na primary key 'id')
  /// - Retorna os registros após processamento
  @override
  Future<List<CategoryDto>> upsertCategories(
    List<CategoryDto> categories,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '[SupabaseCategoriesRemote] Iniciando upsert de ${categories.length} categorias',
        );
      }

      if (categories.isEmpty) {
        if (kDebugMode) {
          print(
            '[SupabaseCategoriesRemote] Lista vazia, nenhuma operação necessária',
          );
        }
        return [];
      }

      // Converte DTOs para JSON
      final jsonList = categories.map((cat) => cat.toJson()).toList();

      if (kDebugMode) {
        print('[SupabaseCategoriesRemote] Enviando dados para Supabase...');
      }

      // Executa upsert no Supabase
      final response = await _client.from(_tableName).upsert(jsonList).select();

      if (kDebugMode) {
        print('[SupabaseCategoriesRemote] Upsert concluído com sucesso');
        print(
          '[SupabaseCategoriesRemote] Resposta: ${response.length} categorias retornadas',
        );
      }

      // Converte resposta de volta para DTOs
      final updatedCategories = (response as List)
          .map((json) => CategoryDto.fromMap(json as Map<String, dynamic>))
          .toList();

      return updatedCategories;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[SupabaseCategoriesRemote] Erro ao fazer upsert: $e');
        print(stack);
      }
      rethrow;
    }
  }
}
