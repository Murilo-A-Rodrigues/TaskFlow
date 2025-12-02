import 'package:flutter/foundation.dart';
import '../../../app/domain/entities/reminder.dart';
import '../../../app/infrastructure/mappers/reminder_mapper.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../local/reminders_local_dao.dart';
import '../remote/reminders_remote_api.dart';

/// Implementação concreta do repositório de Reminders
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
class RemindersRepositoryImpl implements RemindersRepository {
  final RemindersRemoteApi remoteApi;
  final RemindersLocalDaoSharedPrefs localDao;

  RemindersRepositoryImpl({
    required this.remoteApi,
    required this.localDao,
  });

  @override
  Future<List<Reminder>> loadFromCache() async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.loadFromCache: carregando do cache local');
      }

      // Lê DTOs do cache
      final dtos = await localDao.listAll();

      // Converte DTOs para Entities
      final entities = dtos.map((dto) => ReminderMapper.toEntity(dto)).toList();

      if (kDebugMode) {
        print('RemindersRepositoryImpl.loadFromCache: ${entities.length} lembretes carregados');
      }

      return entities;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.loadFromCache ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  @override
  Future<int> syncFromServer() async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.syncFromServer: iniciando sincronização');
      }

      // 1. PUSH: Envia cache local para servidor (best-effort)
      int pushed = 0;
      try {
        final localDtos = await localDao.listAll();
        if (localDtos.isNotEmpty) {
          pushed = await remoteApi.upsertReminders(localDtos);
          if (kDebugMode) {
            print('RemindersRepositoryImpl.syncFromServer: '
                'pushed $pushed de ${localDtos.length} items to remote');
          }
        }
      } catch (e) {
        // Falha no push não impede o pull
        if (kDebugMode) {
          print('RemindersRepositoryImpl.syncFromServer: push failed (non-blocking): $e');
        }
      }

      // 2. PULL: Busca mudanças do servidor
      final lastSync = await localDao.getLastSync();
      if (kDebugMode) {
        print('RemindersRepositoryImpl.syncFromServer: last sync = $lastSync');
      }

      // Busca mudanças desde lastSync (ou tudo se for primeira vez)
      final page = await remoteApi.fetchReminders(
        since: lastSync,
        limit: 500,
      );

      if (kDebugMode) {
        print('RemindersRepositoryImpl.syncFromServer: '
            'recebidos ${page.items.length} items from remote');
      }

      // 3. Aplica mudanças no cache local
      if (page.items.isNotEmpty) {
        await localDao.upsertAll(page.items);

        // 4. Atualiza marcador de última sincronização
        // Usa o maior created_at dos itens recebidos
        DateTime? maxCreatedAt;
        try {
          for (var dto in page.items) {
            final createdAt = DateTime.parse(dto.created_at);
            if (maxCreatedAt == null || createdAt.isAfter(maxCreatedAt)) {
              maxCreatedAt = createdAt;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('RemindersRepositoryImpl.syncFromServer: '
                'erro ao parsear created_at, usando DateTime.now()');
          }
        }

        final newLastSync = maxCreatedAt ?? DateTime.now().toUtc();
        await localDao.setLastSync(newLastSync);

        if (kDebugMode) {
          print('RemindersRepositoryImpl.syncFromServer: '
              'aplicados ${page.items.length} registros, novo lastSync = $newLastSync');
        }
      }

      return page.items.length;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.syncFromServer ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return 0;
    }
  }

  @override
  Future<List<Reminder>> listAll() async {
    // Delega para loadFromCache
    return loadFromCache();
  }

  @override
  Future<List<Reminder>> listActive() async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.listActive: filtrando lembretes ativos');
      }

      // Lê DTOs ativos do cache
      final dtos = await localDao.listActive();

      // Converte para Entities
      final entities = dtos.map((dto) => ReminderMapper.toEntity(dto)).toList();

      if (kDebugMode) {
        print('RemindersRepositoryImpl.listActive: ${entities.length} lembretes ativos');
      }

      return entities;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.listActive ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  @override
  Future<List<Reminder>> listByTaskId(String taskId) async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.listByTaskId: taskId=$taskId');
      }

      // Lê DTOs filtrados por taskId
      final dtos = await localDao.listByTaskId(taskId);

      // Converte para Entities
      final entities = dtos.map((dto) => ReminderMapper.toEntity(dto)).toList();

      if (kDebugMode) {
        print('RemindersRepositoryImpl.listByTaskId: ${entities.length} lembretes encontrados');
      }

      return entities;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.listByTaskId ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  @override
  Future<Reminder?> getById(String id) async {
    try {
      final dto = await localDao.getById(id);
      if (dto == null) return null;
      
      return ReminderMapper.toEntity(dto);
    } catch (e) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.getById ERROR: $e');
      }
      return null;
    }
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.createReminder: taskId=${reminder.taskId}');
      }

      // Converte Entity para DTO
      final dto = ReminderMapper.toDto(reminder);

      // Salva no cache local (optimistic update)
      await localDao.upsert(dto);

      // Tenta enviar para servidor (best-effort)
      try {
        await remoteApi.upsertReminders([dto]);
      } catch (e) {
        if (kDebugMode) {
          print('RemindersRepositoryImpl.createReminder: '
              'falha ao enviar para servidor (ficará no cache): $e');
        }
        // Não falha a operação; será sincronizado depois
      }

      return reminder;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.createReminder ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<Reminder> updateReminder(Reminder reminder) async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.updateReminder: id=${reminder.id}');
      }

      // Converte Entity para DTO (mantém created_at original)
      final dto = ReminderMapper.toDto(reminder);

      // Atualiza cache local
      await localDao.upsert(dto);

      // Tenta enviar para servidor (best-effort)
      try {
        await remoteApi.upsertReminders([dto]);
      } catch (e) {
        if (kDebugMode) {
          print('RemindersRepositoryImpl.updateReminder: '
              'falha ao enviar para servidor (ficará no cache): $e');
        }
      }

      return reminder;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.updateReminder ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.deleteReminder: id=$id');
      }

      // Remove do cache local
      await localDao.delete(id);

      // Nota: Para implementar deleção no servidor, considere:
      // - Soft delete (is_active = false)
      // - Hard delete via API específica
      // - Sincronização de deleções em lote
      
      if (kDebugMode) {
        print('RemindersRepositoryImpl.deleteReminder: removido do cache local');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.deleteReminder ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> clearAllReminders() async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.clearAllReminders: limpando cache completo');
      }

      await localDao.clear();

      if (kDebugMode) {
        print('RemindersRepositoryImpl.clearAllReminders: cache limpo');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.clearAllReminders ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<int> forceSyncAll() async {
    try {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.forceSyncAll: forçando sincronização completa');
      }

      // Busca todos os lembretes do servidor (ignora lastSync)
      final page = await remoteApi.fetchReminders(
        limit: 1000, // Limite maior para full sync
      );

      if (kDebugMode) {
        print('RemindersRepositoryImpl.forceSyncAll: '
            'recebidos ${page.items.length} items from remote');
      }

      // Limpa cache local
      await localDao.clear();

      // Aplica todos os registros do servidor
      if (page.items.isNotEmpty) {
        await localDao.upsertAll(page.items);

        // Atualiza lastSync com timestamp atual
        await localDao.setLastSync(DateTime.now().toUtc());
      }

      if (kDebugMode) {
        print('RemindersRepositoryImpl.forceSyncAll: '
            'sincronizados ${page.items.length} lembretes');
      }

      return page.items.length;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('RemindersRepositoryImpl.forceSyncAll ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return 0;
    }
  }
}

/*
// Exemplo de uso:

final repository = RemindersRepositoryImpl(
  remoteApi: SupabaseRemindersRemoteDatasource(),
  localDao: RemindersLocalDaoSharedPrefs(),
);

// 1. Carregamento inicial (offline-first)
final cached = await repository.loadFromCache();
setState(() => reminders = cached);

// 2. Sincronização em background
repository.syncFromServer().then((count) {
  print('Sincronizados $count lembretes');
  // Recarrega para refletir mudanças
  repository.listAll().then((updated) {
    if (mounted) setState(() => reminders = updated);
  });
});

// 3. Criar novo lembrete
final newReminder = Reminder(
  id: Uuid().v4(),
  taskId: 'task_123',
  reminderDate: DateTime.now().add(Duration(days: 1)),
  type: ReminderType.once,
  isActive: true,
  createdAt: DateTime.now(),
  customMessage: 'Lembrete importante',
);
await repository.createReminder(newReminder);

// 4. Listar lembretes ativos
final active = await repository.listActive();
print('${active.length} lembretes ativos');

// 5. Listar lembretes de uma tarefa
final taskReminders = await repository.listByTaskId('task_123');
print('Tarefa tem ${taskReminders.length} lembretes');

// 6. Atualizar lembrete
final updated = reminder.copyWith(isActive: false);
await repository.updateReminder(updated);

// 7. Remover lembrete
await repository.deleteReminder('rem_456');

// 8. Forçar sincronização completa (caso necessário)
final synced = await repository.forceSyncAll();
print('Full sync: $synced lembretes');

// 9. Limpar cache (logout/reset)
await repository.clearAllReminders();
*/
