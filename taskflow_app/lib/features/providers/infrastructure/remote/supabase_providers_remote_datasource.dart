import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/core/supabase_service.dart';
import '../dtos/provider_dto.dart';
import 'providers_remote_api.dart';

/// Implementação Supabase da API remota de provedores (Prompt 15)
class SupabaseProvidersRemoteDatasource implements ProvidersRemoteApi {
  static const String _tableName = 'providers';
  final SupabaseClient client;

  SupabaseProvidersRemoteDatasource({SupabaseClient? client})
    : client = client ?? SupabaseService.client;

  @override
  Future<RemotePage<ProviderDto>> fetchProviders({
    PageCursor? cursor,
    DateTime? since,
    int limit = 100,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '[SupabaseProvidersRemote] fetchProviders: '
          'since=$since, cursor=$cursor, limit=$limit',
        );
      }

      // Inicia query na tabela providers
      var query = client
          .from(_tableName)
          .select('*')
          .order('updated_at', ascending: false);

      // Aplica paginação por offset
      final offset = cursor?.value as int? ?? 0;
      query = query.range(offset, offset + limit - 1);

      // Executa query
      final response = await query;

      // Aplica filtro de sincronização incremental manualmente
      List<dynamic> filteredResponse = response;
      if (since != null) {
        filteredResponse = response.where((item) {
          final updatedAt = DateTime.parse(item['updated_at']);
          return updatedAt.isAfter(since) || updatedAt.isAtSameMomentAs(since);
        }).toList();

        if (kDebugMode) {
          print(
            '[SupabaseProvidersRemote] Filtrados ${filteredResponse.length} '
            'de ${response.length} items após $since',
          );
        }
      }

      if (kDebugMode) {
        print(
          '[SupabaseProvidersRemote] Recebidos ${filteredResponse.length} registros',
        );
      }

      // Converte resposta para DTOs
      final List<ProviderDto> providers = [];
      for (var row in filteredResponse) {
        try {
          final dto = ProviderDto.fromMap(row);
          providers.add(dto);
        } catch (e) {
          if (kDebugMode) {
            print(
              '[SupabaseProvidersRemote] Erro ao converter registro: $e\nRow: $row',
            );
          }
        }
      }

      // Determina se há mais páginas
      final hasMore = providers.length == limit;
      final nextCursor = hasMore
          ? PageCursor(
              offset: offset + limit,
              limit: limit,
              value: offset + limit,
            )
          : null;

      return RemotePage(data: providers, nextCursor: nextCursor);
    } catch (e, stack) {
      if (kDebugMode) {
        print('[SupabaseProvidersRemote] Erro ao buscar providers: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> upsertProviders(List<ProviderDto> dtos) async {
    try {
      if (dtos.isEmpty) {
        if (kDebugMode) {
          print('[SupabaseProvidersRemote] upsert: lista vazia, pulando');
        }
        return;
      }

      if (kDebugMode) {
        print(
          '[SupabaseProvidersRemote] Enviando ${dtos.length} providers para upsert',
        );
      }

      final rows = dtos.map((dto) => dto.toMap()).toList();

      await client.from(_tableName).upsert(rows, onConflict: 'id');

      if (kDebugMode) {
        print(
          '[SupabaseProvidersRemote] Upsert concluído: ${dtos.length} providers',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[SupabaseProvidersRemote] Erro no upsert: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteProvider(String id) async {
    try {
      if (kDebugMode) {
        print('[SupabaseProvidersRemote] Deletando provider: $id');
      }

      await client.from(_tableName).delete().eq('id', id);

      if (kDebugMode) {
        print('[SupabaseProvidersRemote] Provider deletado: $id');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[SupabaseProvidersRemote] Erro ao deletar: $e');
        print(stack);
      }
      rethrow;
    }
  }
}
