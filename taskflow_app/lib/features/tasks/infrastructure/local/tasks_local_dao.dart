import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/task_dto.dart';

/// DAO Local para Tasks usando SharedPreferences
///
/// Este Data Access Object (DAO) gerencia a persistência local de tarefas
/// usando SharedPreferences. Armazena TaskDto em formato JSON para
/// serialização eficiente.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - SharedPreferences é ideal para caches pequenos/médios (< 1000 registros)
/// - Para volumes maiores, considere usar SQLite (sqflite)
/// - Sempre use try/catch ao parsear JSON (dados podem estar corrompidos)
/// - Use kDebugMode para logs que ajudem no diagnóstico de problemas
/// - Verifique sempre se o cache existe antes de tentar ler
class TasksLocalDaoSharedPrefs {
  // Chave para armazenar a lista de tarefas no SharedPreferences
  static const String _cacheKey = 'taskflow_tasks_cache_v1';

  // Chave para armazenar o timestamp da última sincronização
  static const String _lastSyncKey = 'taskflow_tasks_last_sync_v1';

  /// Lista todas as tarefas armazenadas no cache local
  ///
  /// Retorna lista vazia se não houver cache ou em caso de erro.
  ///
  /// Boas práticas:
  /// - Este método é rápido e síncrono internamente (lê de memória)
  /// - Sempre retorna uma lista (nunca null) para facilitar uso na UI
  /// - Em caso de JSON corrompido, limpa o cache e retorna lista vazia
  Future<List<TaskDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final List<TaskDto> tasks = jsonList
          .map((jsonItem) => TaskDto.fromMap(jsonItem as Map<String, dynamic>))
          .toList();

      return tasks;
    } catch (e) {
      // Log do erro para debug
      print('TasksLocalDao.listAll ERROR: $e');

      // Em caso de cache corrompido, limpa para evitar erros futuros
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cacheKey);
      } catch (_) {}

      return [];
    }
  }

  /// Insere ou atualiza múltiplas tarefas no cache (upsert em lote)
  ///
  /// Mescla as tarefas fornecidas com o cache existente, substituindo
  /// tarefas com mesmo ID e adicionando novas.
  ///
  /// Boas práticas:
  /// - Use este método para aplicar mudanças de sincronização
  /// - Mantém tarefas locais que não estão no lote (merge inteligente)
  /// - Atualiza tarefas existentes sem duplicar
  Future<void> upsertAll(List<TaskDto> tasks) async {
    try {
      // Carrega cache existente
      final existing = await listAll();

      // Cria mapa para merge eficiente por ID
      final Map<String, TaskDto> taskMap = {
        for (var task in existing) task.id: task,
      };

      // Adiciona/atualiza tarefas do lote
      for (var task in tasks) {
        taskMap[task.id] = task;
      }

      // Converte de volta para lista e salva
      final updatedList = taskMap.values.toList();
      await _saveAll(updatedList);

      print(
        'TasksLocalDao.upsertAll: ${tasks.length} tasks upserted, total: ${updatedList.length}',
      );
    } catch (e) {
      print('TasksLocalDao.upsertAll ERROR: $e');
      rethrow;
    }
  }

  /// Insere ou atualiza uma única tarefa no cache
  ///
  /// Conveniência para operações de create/update individuais.
  Future<void> upsert(TaskDto task) async {
    await upsertAll([task]);
  }

  /// Remove uma tarefa do cache por ID
  ///
  /// Remove permanentemente a tarefa do cache local.
  ///
  /// Boas práticas:
  /// - Considere implementar soft delete para permitir "desfazer"
  /// - Retorna silenciosamente se a tarefa não existir
  Future<void> delete(String taskId) async {
    try {
      final existing = await listAll();
      final updated = existing.where((task) => task.id != taskId).toList();
      await _saveAll(updated);

      print(
        'TasksLocalDao.delete: removed task $taskId, remaining: ${updated.length}',
      );
    } catch (e) {
      print('TasksLocalDao.delete ERROR: $e');
      rethrow;
    }
  }

  /// Busca uma tarefa específica por ID
  ///
  /// Retorna null se a tarefa não for encontrada.
  Future<TaskDto?> getById(String id) async {
    try {
      final all = await listAll();
      return all.cast<TaskDto?>().firstWhere(
        (task) => task?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      print('TasksLocalDao.getById ERROR: $e');
      return null;
    }
  }

  /// Limpa todo o cache de tarefas
  ///
  /// ⚠️ ATENÇÃO: Esta operação é destrutiva e remove todos os dados locais.
  /// Use apenas para logout, reset ou casos específicos.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('TasksLocalDao.clear: cache cleared');
    } catch (e) {
      print('TasksLocalDao.clear ERROR: $e');
      rethrow;
    }
  }

  /// Obtém o timestamp da última sincronização bem-sucedida
  ///
  /// Retorna null se nunca houve sincronização.
  /// Este valor é usado para sincronização incremental.
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncString = prefs.getString(_lastSyncKey);

      if (syncString == null) {
        return null;
      }

      return DateTime.tryParse(syncString);
    } catch (e) {
      print('TasksLocalDao.getLastSync ERROR: $e');
      return null;
    }
  }

  /// Atualiza o timestamp da última sincronização
  ///
  /// Deve ser chamado após uma sincronização bem-sucedida.
  /// Use o maior updated_at dos registros sincronizados ou DateTime.now().
  Future<void> setLastSync(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
      print('TasksLocalDao.setLastSync: ${timestamp.toIso8601String()}');
    } catch (e) {
      print('TasksLocalDao.setLastSync ERROR: $e');
      rethrow;
    }
  }

  /// Método privado para salvar toda a lista no SharedPreferences
  Future<void> _saveAll(List<TaskDto> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((task) => task.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_cacheKey, jsonString);
  }
}

/*
// Exemplo de uso:

final dao = TasksLocalDaoSharedPrefs();

// Listar todas as tarefas do cache
final tasks = await dao.listAll();
print('Cache tem ${tasks.length} tarefas');

// Adicionar/atualizar tarefas
await dao.upsertAll([
  TaskDto(
    id: 'task_1',
    title: 'Minha tarefa',
    is_completed: false,
    created_at: DateTime.now().toIso8601String(),
    priority: 2,
    updated_at: DateTime.now().toIso8601String(),
  ),
]);

// Buscar tarefa específica
final task = await dao.getById('task_1');
if (task != null) {
  print('Encontrada: ${task.title}');
}

// Remover tarefa
await dao.delete('task_1');

// Gerenciar sincronização
final lastSync = await dao.getLastSync();
if (lastSync == null) {
  print('Primeira sincronização');
} else {
  print('Última sync: $lastSync');
}

await dao.setLastSync(DateTime.now());

// Limpar cache (cuidado!)
await dao.clear();

// Checklist de erros comuns:
// ❌ Não tratar JSON corrompido
//    ✅ Use try/catch em listAll() e retorne [] em erro
// 
// ❌ Duplicar tarefas ao fazer upsert
//    ✅ Use Map<id, task> para merge inteligente
// 
// ❌ Não atualizar lastSync após sincronização
//    ✅ Sempre chame setLastSync() após sync bem-sucedido
// 
// ❌ Não adicionar logs para debug
//    ✅ Use print() nos métodos principais para facilitar diagnóstico
// 
// ❌ Usar SharedPreferences para volumes muito grandes
//    ✅ Se passar de ~1000 registros, migre para SQLite
*/
