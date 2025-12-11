import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/core/supabase_service.dart';
import '../dtos/task_dto.dart';
import 'tasks_remote_api.dart';

/// Implementação Supabase do datasource remoto de Tasks
///
/// Esta classe comunica com a tabela 'tasks' no Supabase para buscar
/// e enviar tarefas. Implementa paginação, sincronização incremental
/// e tratamento robusto de erros.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Garanta que o DTO e o Mapper aceitam múltiplos formatos vindos do backend
///   (ex: id como int/string, datas como DateTime/String)
/// - Sempre adicione prints/logs (usando kDebugMode) nos métodos de fetch/upsert
///   mostrando o conteúdo dos dados recebidos e convertidos
/// - Envolva parsing de datas, conversão de tipos e chamadas externas em try/catch,
///   logando o erro e retornando valores seguros
/// - Não exponha segredos (keys) em prints/logs
/// - Consulte os arquivos de debug do projeto para exemplos de logs e soluções
class SupabaseTasksRemoteDatasource implements TasksRemoteApi {
  final SupabaseClient client;

  /// Construtor com client opcional (fallback para SupabaseService global)
  SupabaseTasksRemoteDatasource({SupabaseClient? client})
    : client = client ?? SupabaseService.client;

  @override
  Future<RemotePage<TaskDto>> fetchTasks({
    DateTime? since,
    PageCursor? cursor,
    int limit = 100,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'SupabaseTasksRemoteDatasource.fetchTasks: '
          'since=$since, cursor=$cursor, limit=$limit',
        );
      }

      // Obtém o user_id do usuário autenticado
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('SupabaseTasksRemoteDatasource.fetchTasks: Usuário não autenticado');
        }
        return const RemotePage<TaskDto>(items: []);
      }

      // Inicia query na tabela tasks filtrando por user_id
      var query = client
          .from('tasks')
          .select('*')
          .eq('user_id', currentUser.id)
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
            'SupabaseTasksRemoteDatasource.fetchTasks: '
            'Filtrados ${filteredResponse.length} de ${response.length} items após $since',
          );
        }
      }

      if (kDebugMode) {
        print(
          'SupabaseTasksRemoteDatasource.fetchTasks: '
          'recebidos ${filteredResponse.length} registros',
        );
      }

      // Converte resposta para DTOs
      final List<TaskDto> tasks = [];
      for (var row in filteredResponse) {
        try {
          final dto = TaskDto.fromMap(row);
          tasks.add(dto);
        } catch (e) {
          // Log de erro de conversão mas continua processando outros registros
          if (kDebugMode) {
            print(
              'SupabaseTasksRemoteDatasource.fetchTasks: '
              'erro ao converter registro: $e\nRow: $row',
            );
          }
        }
      }

      // Determina se há próxima página
      final hasMore = response.length == limit;
      final nextCursor = hasMore ? PageCursor(offset + limit) : null;

      return RemotePage<TaskDto>(items: tasks, next: nextCursor);
    } catch (e, stackTrace) {
      // Log do erro mas retorna página vazia para não quebrar o fluxo
      if (kDebugMode) {
        print('SupabaseTasksRemoteDatasource.fetchTasks ERROR: $e');
        print('Stack trace: $stackTrace');
      }

      return const RemotePage<TaskDto>(items: []);
    }
  }

  @override
  Future<int> upsertTasks(List<TaskDto> tasks) async {
    if (tasks.isEmpty) {
      return 0;
    }

    try {
      if (kDebugMode) {
        print(
          'SupabaseTasksRemoteDatasource.upsertTasks: '
          'sending ${tasks.length} items',
        );
      }

      // Converte DTOs para Maps
      final List<Map<String, dynamic>> maps = tasks
          .map((dto) => dto.toMap())
          .toList();

      // Realiza upsert no Supabase
      final response = await client.from('tasks').upsert(maps).select();

      if (kDebugMode) {
        print(
          'SupabaseTasksRemoteDatasource.upsertTasks: '
          'response length: ${response.length}',
        );
      }

      return response.length;
    } catch (e, stackTrace) {
      // Log do erro detalhado
      if (kDebugMode) {
        print('SupabaseTasksRemoteDatasource.upsertTasks ERROR: $e');
        print('Stack trace: $stackTrace');
        print('Attempted to upsert ${tasks.length} tasks');
      }

      // Retorna 0 indicando que nenhuma tarefa foi processada
      // Não lança exception para não quebrar o fluxo de sync
      return 0;
    }
  }
}

/*
// Exemplo de uso:

final datasource = SupabaseTasksRemoteDatasource();

// Buscar todas as tarefas (primeira página)
final page1 = await datasource.fetchTasks(limit: 100);
print('Página 1: ${page1.items.length} tarefas');

// Buscar próxima página se houver
if (page1.hasMore) {
  final page2 = await datasource.fetchTasks(
    cursor: page1.next,
    limit: 100,
  );
  print('Página 2: ${page2.items.length} tarefas');
}

// Sincronização incremental
final lastSync = DateTime(2024, 12, 1);
final changes = await datasource.fetchTasks(since: lastSync);
print('Mudanças desde $lastSync: ${changes.items.length}');

// Enviar tarefas para o servidor
final localTasks = [
  TaskDto(...),
  TaskDto(...),
];
final sent = await datasource.upsertTasks(localTasks);
print('Enviadas: $sent de ${localTasks.length} tarefas');

// Logs esperados (kDebugMode):
// SupabaseTasksRemoteDatasource.fetchTasks: since=2024-12-01, cursor=null, limit=100
// SupabaseTasksRemoteDatasource.fetchTasks: recebidos 45 registros
// SupabaseTasksRemoteDatasource.upsertTasks: sending 2 items
// SupabaseTasksRemoteDatasource.upsertTasks: response length: 2

// Checklist de erros comuns:
// ❌ Não tratar erro de conversão de DTO individual
//    ✅ Envolva TaskDto.fromMap em try/catch dentro do loop
// 
// ❌ Lançar exception em caso de erro de rede
//    ✅ Retorne RemotePage vazia ou 0 para não quebrar fluxo
// 
// ❌ Não adicionar logs de debug
//    ✅ Use if (kDebugMode) print() nos pontos principais
// 
// ❌ Expor dados sensíveis nos logs
//    ✅ Nunca logue tokens, passwords, dados pessoais completos
// 
// ❌ Não ordenar por updated_at
//    ✅ Sempre ordene para sincronização incremental consistente
// 
// ❌ Enviar lotes muito grandes (>1000)
//    ✅ Divida em chunks de ~500 registros se necessário
// 
// 📚 Referências úteis:
// - supabase_init_debug_prompt.md: problemas de inicialização
// - supabase_rls_remediation.md: erros de permissão RLS
// - providers_cache_debug_prompt.md: exemplos de logs e debug
*/
