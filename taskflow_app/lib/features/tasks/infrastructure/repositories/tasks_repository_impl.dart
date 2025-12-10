import 'package:flutter/foundation.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../local/tasks_local_dao.dart';
import '../mappers/task_mapper.dart';
import '../remote/tasks_remote_api.dart';

/// Implementação concreta do repositório de Tasks
///
/// Esta classe orquestra o fluxo de dados entre cache local (DAO) e
/// servidor remoto (Supabase). Implementa o padrão offline-first:
/// - Cache local é sempre a fonte da verdade para a UI
/// - Sincronização remota acontece em background
/// - Conversões DTO ↔ Entity são feitas nas fronteiras
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Sempre verifique se o widget está mounted antes de chamar setState
/// - Adicione prints/logs (usando kDebugMode) nos métodos de sync, cache e conversão
/// - Use tratamento defensivo em parsing de datas e conversão de tipos
/// - Consulte os arquivos de debug do projeto para exemplos de logs e soluções
class TasksRepositoryImpl implements TasksRepository {
  final TasksRemoteApi remoteApi;
  final TasksLocalDaoSharedPrefs localDao;

  TasksRepositoryImpl({required this.remoteApi, required this.localDao});

  @override
  Future<List<Task>> loadFromCache() async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.loadFromCache: carregando do cache local');
      }

      // Lê DTOs do cache
      final dtos = await localDao.listAll();

      // Converte DTOs para Entities e filtra deletados (soft delete)
      final entities = dtos
          .where((dto) => !dto.is_deleted) // Filtra deletados
          .map((dto) => TaskMapper.toEntity(dto))
          .toList();

      if (kDebugMode) {
        print(
          'TasksRepositoryImpl.loadFromCache: ${entities.length} tarefas carregadas (excluindo deletadas)',
        );
      }

      return entities;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.loadFromCache ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  @override
  Future<int> syncFromServer() async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.syncFromServer: iniciando sincronização');
      }

      // 1. PUSH: Envia cache local para servidor (best-effort)
      int pushed = 0;
      try {
        final localDtos = await localDao.listAll();
        if (localDtos.isNotEmpty) {
          pushed = await remoteApi.upsertTasks(localDtos);
          if (kDebugMode) {
            print(
              'TasksRepositoryImpl.syncFromServer: '
              'pushed $pushed de ${localDtos.length} items to remote',
            );
          }
        }
      } catch (e) {
        // Falha no push não impede o pull
        if (kDebugMode) {
          print(
            'TasksRepositoryImpl.syncFromServer: push failed (non-blocking): $e',
          );
        }
      }

      // 2. PULL: Busca mudanças do servidor
      final lastSync = await localDao.getLastSync();
      if (kDebugMode) {
        print('TasksRepositoryImpl.syncFromServer: last sync = $lastSync');
      }

      // Busca mudanças desde lastSync (ou tudo se for primeira vez)
      final page = await remoteApi.fetchTasks(since: lastSync, limit: 500);

      if (kDebugMode) {
        print(
          'TasksRepositoryImpl.syncFromServer: '
          'recebidos ${page.items.length} items from remote',
        );
      }

      // 3. Aplica mudanças no cache local
      if (page.items.isNotEmpty) {
        await localDao.upsertAll(page.items);

        // 4. Atualiza marcador de última sincronização
        // Usa o maior updated_at dos itens recebidos
        DateTime? maxUpdatedAt;
        try {
          for (var dto in page.items) {
            final updatedAt = DateTime.parse(dto.updated_at);
            if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
              maxUpdatedAt = updatedAt;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'TasksRepositoryImpl.syncFromServer: '
              'erro ao parsear updated_at, usando DateTime.now()',
            );
          }
        }

        final newLastSync = maxUpdatedAt ?? DateTime.now().toUtc();
        await localDao.setLastSync(newLastSync);

        if (kDebugMode) {
          print(
            'TasksRepositoryImpl.syncFromServer: '
            'aplicados ${page.items.length} registros, novo lastSync = $newLastSync',
          );
        }
      }

      return page.items.length;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.syncFromServer ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return 0;
    }
  }

  @override
  Future<List<Task>> listAll() async {
    // Delega para loadFromCache
    return loadFromCache();
  }

  @override
  Future<List<Task>> listFeatured() async {
    // Carrega todas e filtra as de alta prioridade ou com due date próxima
    final all = await loadFromCache();

    final now = DateTime.now();
    final featured = all.where((task) {
      // Considera featured: alta prioridade OU prazo nos próximos 3 dias
      if (task.priority.value >= 2) return true; // high priority

      if (task.dueDate != null) {
        final daysUntilDue = task.dueDate!.difference(now).inDays;
        if (daysUntilDue >= 0 && daysUntilDue <= 3) return true;
      }

      return false;
    }).toList();

    if (kDebugMode) {
      print(
        'TasksRepositoryImpl.listFeatured: ${featured.length} de ${all.length}',
      );
    }

    return featured;
  }

  @override
  Future<Task?> getById(String id) async {
    try {
      final dto = await localDao.getById(id);
      if (dto == null) return null;

      return TaskMapper.toEntity(dto);
    } catch (e) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.getById ERROR: $e');
      }
      return null;
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.createTask: ${task.title}');
      }

      // Converte Entity para DTO
      final dto = TaskMapper.toDto(task);

      // Salva no cache local (optimistic update)
      await localDao.upsert(dto);

      // Tenta enviar para servidor (best-effort)
      try {
        await remoteApi.upsertTasks([dto]);
      } catch (e) {
        if (kDebugMode) {
          print(
            'TasksRepositoryImpl.createTask: '
            'falha ao enviar para servidor (ficará no cache): $e',
          );
        }
        // Não falha a operação; será sincronizado depois
      }

      return task;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.createTask ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.updateTask: ${task.id}');
      }

      // Atualiza timestamp
      final updated = task.copyWith(updatedAt: DateTime.now());
      final dto = TaskMapper.toDto(updated);

      // Atualiza cache local
      await localDao.upsert(dto);

      // Tenta enviar para servidor (best-effort)
      try {
        await remoteApi.upsertTasks([dto]);
      } catch (e) {
        if (kDebugMode) {
          print(
            'TasksRepositoryImpl.updateTask: '
            'falha ao enviar para servidor (ficará no cache): $e',
          );
        }
      }

      return updated;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.updateTask ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.deleteTask (SOFT DELETE): $taskId');
      }

      // Busca a task atual
      final tasks = await localDao.listAll();
      final taskDto = tasks.firstWhere((t) => t.id == taskId);

      // Marca como deletada (soft delete)
      final deletedTask = taskDto.copyWith(
        is_deleted: true,
        deleted_at: DateTime.now().toIso8601String(),
        updated_at: DateTime.now().toIso8601String(),
      );

      // Atualiza localmente
      await localDao.upsert(deletedTask);

      // Tenta sincronizar com servidor (soft delete)
      try {
        await remoteApi.upsertTasks([deletedTask]);
        if (kDebugMode) {
          print(
            'TasksRepositoryImpl.deleteTask: soft delete sincronizado com servidor',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'TasksRepositoryImpl.deleteTask: erro ao sincronizar com servidor, mantido local: $e',
          );
        }
      }

      if (kDebugMode) {
        print('TasksRepositoryImpl.deleteTask: soft delete aplicado');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.deleteTask ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> clearAllTasks() async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.clearAllTasks: limpando cache');
      }

      await localDao.clear();

      if (kDebugMode) {
        print('TasksRepositoryImpl.clearAllTasks: cache limpo');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.clearAllTasks ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> forceSyncAll() async {
    try {
      if (kDebugMode) {
        print('TasksRepositoryImpl.forceSyncAll: full sync iniciado');
      }

      // Limpa marcador de última sync para forçar full sync
      await localDao.setLastSync(DateTime(1970, 1, 1));

      // Executa sync incremental (que agora vai buscar tudo)
      final synced = await syncFromServer();

      if (kDebugMode) {
        print(
          'TasksRepositoryImpl.forceSyncAll: $synced tarefas sincronizadas',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TasksRepositoryImpl.forceSyncAll ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}

/*
// Exemplo de uso:

final repository = TasksRepositoryImpl(
  remoteApi: SupabaseTasksRemoteDatasource(),
  localDao: TasksLocalDaoSharedPrefs(),
);

// Padrão offline-first recomendado para UI:
void loadTasks() async {
  setState(() => isLoading = true);
  
  // 1. Carrega cache rapidamente para UI responsiva
  final cached = await repository.loadFromCache();
  if (mounted) {
    setState(() {
      tasks = cached;
      isLoading = false;
    });
  }
  
  // 2. Sincroniza em background
  final changed = await repository.syncFromServer();
  
  // 3. Se houver mudanças, recarrega
  if (changed > 0 && mounted) {
    final updated = await repository.loadFromCache();
    setState(() => tasks = updated);
  }
}

// CRUD operations:
final newTask = await repository.createTask(Task(...));
final updated = await repository.updateTask(task.copyWith(title: 'Novo título'));
await repository.deleteTask('task_123');

// Logs esperados (kDebugMode):
// TasksRepositoryImpl.loadFromCache: carregando do cache local
// TasksRepositoryImpl.loadFromCache: 15 tarefas carregadas
// TasksRepositoryImpl.syncFromServer: iniciando sincronização
// TasksRepositoryImpl.syncFromServer: pushed 15 de 15 items to remote
// TasksRepositoryImpl.syncFromServer: last sync = 2024-12-01 10:00:00.000Z
// TasksRepositoryImpl.syncFromServer: recebidos 3 items from remote
// TasksRepositoryImpl.syncFromServer: aplicados 3 registros, novo lastSync = 2024-12-02 10:30:00.000Z

// Checklist de erros comuns:
// ❌ Chamar setState sem verificar if (mounted)
//    ✅ Sempre verifique mounted antes de setState após async
// 
// ❌ Bloquear UI durante sync
//    ✅ Carregue cache primeiro, sync depois em background
// 
// ❌ Não atualizar UI após sync se houver mudanças
//    ✅ Recarregue cache se syncFromServer() retornar > 0
// 
// ❌ Falhar operação local se servidor estiver offline
//    ✅ Sempre persista local primeiro (optimistic update)
// 
// ❌ Não adicionar logs para debug
//    ✅ Use if (kDebugMode) print() nos pontos principais
// 
// ❌ Não tratar erro de parsing de updated_at
//    ✅ Use DateTime.tryParse() com fallback para DateTime.now()
// 
// 📚 Referências úteis:
// - providers_cache_debug_prompt.md: exemplos de logs e debug
// - supabase_init_debug_prompt.md: problemas de inicialização
// - supabase_rls_remediation.md: erros de permissão RLS
*/
