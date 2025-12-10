import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/infrastructure/dtos/reminder_dto.dart';

/// DAO Local para Reminders usando SharedPreferences
///
/// Este Data Access Object (DAO) gerencia a persistência local de lembretes
/// usando SharedPreferences. Armazena ReminderDto em formato JSON para
/// serialização eficiente.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - SharedPreferences é ideal para caches pequenos/médios (< 1000 registros)
/// - Para volumes maiores, considere usar SQLite (sqflite)
/// - Sempre use try/catch ao parsear JSON (dados podem estar corrompidos)
/// - Use kDebugMode para logs que ajudem no diagnóstico de problemas
/// - Verifique sempre se o cache existe antes de tentar ler
class RemindersLocalDaoSharedPrefs {
  // Chave para armazenar a lista de lembretes no SharedPreferences
  static const String _cacheKey = 'taskflow_reminders_cache_v1';

  // Chave para armazenar o timestamp da última sincronização
  static const String _lastSyncKey = 'taskflow_reminders_last_sync_v1';

  /// Lista todos os lembretes armazenados no cache local
  ///
  /// Retorna lista vazia se não houver cache ou em caso de erro.
  ///
  /// Boas práticas:
  /// - Este método é rápido e síncrono internamente (lê de memória)
  /// - Sempre retorna uma lista (nunca null) para facilitar uso na UI
  /// - Em caso de JSON corrompido, limpa o cache e retorna lista vazia
  Future<List<ReminderDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final List<ReminderDto> reminders = jsonList
          .map(
            (jsonItem) => ReminderDto.fromMap(jsonItem as Map<String, dynamic>),
          )
          .toList();

      return reminders;
    } catch (e) {
      // Log do erro para debug
      print('RemindersLocalDao.listAll ERROR: $e');

      // Em caso de cache corrompido, limpa para evitar erros futuros
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cacheKey);
      } catch (_) {}

      return [];
    }
  }

  /// Insere ou atualiza múltiplos lembretes no cache (upsert em lote)
  ///
  /// Mescla os lembretes fornecidos com o cache existente, substituindo
  /// lembretes com mesmo ID e adicionando novos.
  ///
  /// Boas práticas:
  /// - Use este método para aplicar mudanças de sincronização
  /// - Mantém lembretes locais que não estão no lote (merge inteligente)
  /// - Atualiza lembretes existentes sem duplicar
  Future<void> upsertAll(List<ReminderDto> reminders) async {
    try {
      // Carrega cache existente
      final existing = await listAll();

      // Cria mapa para merge eficiente por ID
      final Map<String, ReminderDto> reminderMap = {
        for (var reminder in existing) reminder.id: reminder,
      };

      // Adiciona/atualiza lembretes do lote
      for (var reminder in reminders) {
        reminderMap[reminder.id] = reminder;
      }

      // Converte de volta para lista e salva
      final updatedList = reminderMap.values.toList();
      await _saveAll(updatedList);

      print(
        'RemindersLocalDao.upsertAll: ${reminders.length} reminders upserted, total: ${updatedList.length}',
      );
    } catch (e) {
      print('RemindersLocalDao.upsertAll ERROR: $e');
      rethrow;
    }
  }

  /// Insere ou atualiza um único lembrete no cache
  ///
  /// Conveniência para operações de create/update individuais.
  Future<void> upsert(ReminderDto reminder) async {
    await upsertAll([reminder]);
  }

  /// Remove um lembrete do cache por ID
  ///
  /// Remove permanentemente o lembrete do cache local.
  ///
  /// Boas práticas:
  /// - Considere implementar soft delete para permitir "desfazer"
  /// - Retorna silenciosamente se o lembrete não existir
  Future<void> delete(String reminderId) async {
    try {
      final existing = await listAll();
      final updated = existing
          .where((reminder) => reminder.id != reminderId)
          .toList();
      await _saveAll(updated);

      print(
        'RemindersLocalDao.delete: removed reminder $reminderId, remaining: ${updated.length}',
      );
    } catch (e) {
      print('RemindersLocalDao.delete ERROR: $e');
      rethrow;
    }
  }

  /// Busca um lembrete específico por ID
  ///
  /// Retorna null se o lembrete não for encontrado.
  Future<ReminderDto?> getById(String id) async {
    try {
      final all = await listAll();
      return all.cast<ReminderDto?>().firstWhere(
        (reminder) => reminder?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      print('RemindersLocalDao.getById ERROR: $e');
      return null;
    }
  }

  /// Lista lembretes de uma tarefa específica
  ///
  /// Filtra lembretes pelo task_id fornecido.
  Future<List<ReminderDto>> listByTaskId(String taskId) async {
    try {
      final all = await listAll();
      return all.where((reminder) => reminder.task_id == taskId).toList();
    } catch (e) {
      print('RemindersLocalDao.listByTaskId ERROR: $e');
      return [];
    }
  }

  /// Lista apenas lembretes ativos
  ///
  /// Filtra lembretes com is_active = true.
  Future<List<ReminderDto>> listActive() async {
    try {
      final all = await listAll();
      return all.where((reminder) => reminder.is_active).toList();
    } catch (e) {
      print('RemindersLocalDao.listActive ERROR: $e');
      return [];
    }
  }

  /// Limpa todo o cache de lembretes
  ///
  /// ⚠️ ATENÇÃO: Esta operação é destrutiva e remove todos os dados locais.
  /// Use apenas para logout, reset ou casos específicos.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('RemindersLocalDao.clear: cache cleared');
    } catch (e) {
      print('RemindersLocalDao.clear ERROR: $e');
      rethrow;
    }
  }

  /// Obtém o timestamp da última sincronização
  ///
  /// Retorna null se nunca houve sincronização.
  ///
  /// Boas práticas:
  /// - Use para sincronização incremental (fetch since lastSync)
  /// - Armazene em UTC para evitar problemas de timezone
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);

      if (timestamp == null) return null;

      return DateTime.parse(timestamp);
    } catch (e) {
      print('RemindersLocalDao.getLastSync ERROR: $e');
      return null;
    }
  }

  /// Define o timestamp da última sincronização
  ///
  /// Armazena em formato ISO8601 UTC.
  ///
  /// Boas práticas:
  /// - Atualize após cada sincronização bem-sucedida
  /// - Use o maior updated_at dos registros recebidos
  /// - Armazene sempre em UTC
  Future<void> setLastSync(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
      print('RemindersLocalDao.setLastSync: $timestamp');
    } catch (e) {
      print('RemindersLocalDao.setLastSync ERROR: $e');
      rethrow;
    }
  }

  /// Método privado para salvar toda a lista de lembretes
  ///
  /// Serializa a lista completa em JSON e persiste no SharedPreferences.
  Future<void> _saveAll(List<ReminderDto> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_cacheKey, jsonString);
  }
}

/*
// Exemplo de uso:

final dao = RemindersLocalDaoSharedPrefs();

// Listar todos os lembretes
final all = await dao.listAll();
print('Total: ${all.length} lembretes');

// Listar apenas ativos
final active = await dao.listActive();
print('Ativos: ${active.length}');

// Listar lembretes de uma tarefa
final taskReminders = await dao.listByTaskId('task_123');
print('Tarefa tem ${taskReminders.length} lembretes');

// Buscar por ID
final reminder = await dao.getById('rem_456');
if (reminder != null) {
  print('Encontrado: ${reminder.type}');
}

// Inserir/atualizar
await dao.upsert(ReminderDto(...));

// Remover
await dao.delete('rem_789');

// Sincronização
final lastSync = await dao.getLastSync();
print('Última sync: $lastSync');

await dao.setLastSync(DateTime.now().toUtc());

// Limpar tudo (cuidado!)
await dao.clear();
*/
