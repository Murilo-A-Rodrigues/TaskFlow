import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/task.dart';
import '../dtos/task_dto.dart';
import '../mappers/task_mapper.dart';

/// Repository seguindo o padrão offline-first do guia FoodSafe
/// Cache local + sincronização incremental baseada em updated_at
class TaskRepository {
  static const String _cacheKey = 'taskflow_cache';
  static const String _lastSyncKey = 'taskflow_last_sync';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Obtém todas as tarefas (cache-first)
  /// Renderização imediata do cache + atualização silenciosa em background
  Future<List<Task>> getAllTasks({bool forceSync = false}) async {
    try {
      // 1. Carrega do cache primeiro (UX rápida)
      final cachedTasks = await _loadFromCache();
      
      // 2. Sincronização incremental em background
      if (forceSync || await _shouldSync()) {
        await _syncIncrementally();
      }
      
      // 3. Retorna o cache atualizado
      return await _loadFromCache();
      
    } catch (e) {
      print('❌ Erro no Repository.getAllTasks: $e');
      // Fallback para o cache em caso de erro
      return await _loadFromCache();
    }
  }
  
  /// Cria nova tarefa (otimistic update)
  Future<Task?> createTask(Task task) async {
    try {
      // 1. Adiciona ao cache imediatamente (UX responsiva)
      await _addToCache(task);
      
      // 2. Envia para o Supabase
      final dto = TaskMapper.toDto(task);
      final response = await _supabase
          .from('tasks')
          .insert(dto.toMap())
          .select()
          .single();
      
      // 3. Atualiza cache com dados do servidor
      final serverTask = _mapFromSupabase(response);
      await _updateInCache(serverTask);
      
      print('✅ Tarefa criada no Supabase: ${serverTask.title}');
      return serverTask;
      
    } catch (e) {
      print('❌ Erro ao criar tarefa: $e');
      // A tarefa permanece no cache local
      return null;
    }
  }
  
  /// Atualiza tarefa existente
  Future<bool> updateTask(Task task) async {
    try {
      // 1. Atualiza cache imediatamente
      await _updateInCache(task);
      
      // 2. Envia para Supabase
      await _supabase
          .from('tasks')
          .update(TaskMapper.toDto(task).toMap())
          .eq('id', task.id);
      
      print('✅ Tarefa atualizada no Supabase: ${task.title}');
      return true;
      
    } catch (e) {
      print('❌ Erro ao atualizar tarefa: $e');
      return false;
    }
  }
  
  /// Remove tarefa
  Future<bool> deleteTask(String taskId) async {
    try {
      // 1. Remove do cache imediatamente
      await _removeFromCache(taskId);
      
      // 2. Remove do Supabase
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId);
      
      print('✅ Tarefa removida do Supabase: $taskId');
      return true;
      
    } catch (e) {
      print('❌ Erro ao remover tarefa: $e');
      return false;
    }
  }
  
  /// Força sincronização completa
  Future<void> forceSyncAll() async {
    await _syncIncrementally(forceFull: true);
  }
  
  // ==========================================
  // 🔄 SINCRONIZAÇÃO INCREMENTAL (PADRÃO DO GUIA)
  // ==========================================
  
  Future<void> _syncIncrementally({bool forceFull = false}) async {
    try {
      // TODO: Implementar sync incremental baseado em lastSync
      

      final response = await _supabase
          .from('tasks')
          .select()
          .order('updated_at', ascending: false);
      
      if (response.isNotEmpty) {
        final serverTasks = response.map(_mapFromSupabase).toList();
        
        if (forceFull) {
          await _replaceCache(serverTasks);
        } else {
          await _mergeWithCache(serverTasks);
        }
        
        await _saveLastSync();
        print('✅ Sincronizado: ${serverTasks.length} tarefas');
      }
      
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    }
  }
  
  Future<bool> _shouldSync() async {
    final lastSync = await _getLastSync();
    if (lastSync == null) return true;
    
    // Sincroniza a cada 5 minutos (configurável)
    const syncInterval = Duration(minutes: 5);
    return DateTime.now().difference(lastSync) > syncInterval;
  }
  
  // ==========================================
  // 💾 GERENCIAMENTO DE CACHE LOCAL
  // ==========================================
  
  Future<List<Task>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) {
          final dto = TaskDto.fromMap(json);
          return TaskMapper.toEntity(dto);
        }).toList();
      }
    } catch (e) {
      print('❌ Erro ao carregar cache: $e');
    }
    
    return [];
  }
  
  Future<void> _saveToCache(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(tasks.map((t) {
        final dto = TaskMapper.toDto(t);
        return dto.toMap();
      }).toList());
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      print('❌ Erro ao salvar cache: $e');
    }
  }
  
  Future<void> _addToCache(Task task) async {
    final tasks = await _loadFromCache();
    tasks.add(task);
    await _saveToCache(tasks);
  }
  
  Future<void> _updateInCache(Task updatedTask) async {
    final tasks = await _loadFromCache();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
    } else {
      tasks.add(updatedTask);
    }
    await _saveToCache(tasks);
  }
  
  Future<void> _removeFromCache(String taskId) async {
    final tasks = await _loadFromCache();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveToCache(tasks);
  }
  
  Future<void> _replaceCache(List<Task> newTasks) async {
    await _saveToCache(newTasks);
  }
  
  Future<void> _mergeWithCache(List<Task> serverTasks) async {
    final cachedTasks = await _loadFromCache();
    final merged = <Task>[];
    
    // Adiciona tarefas do servidor (sempre prioritárias)
    merged.addAll(serverTasks);
    
    // Adiciona tarefas locais que não existem no servidor
    for (final cached in cachedTasks) {
      if (!merged.any((server) => server.id == cached.id)) {
        merged.add(cached);
      }
    }
    
    await _saveToCache(merged);
  }
  
  // ==========================================
  // 🗓️ CONTROLE DE ÚLTIMA SINCRONIZAÇÃO
  // ==========================================
  
  Future<DateTime?> _getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> _saveLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Erro ao salvar lastSync: $e');
    }
  }
  
  // ==========================================
  // 🔄 MAPEAMENTO SUPABASE <-> TASK
  // ==========================================
  
  Task _mapFromSupabase(Map<String, dynamic> data) {
    final dto = TaskDto(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      is_completed: data['is_completed'] ?? false,
      created_at: data['created_at'] ?? DateTime.now().toIso8601String(),
      due_date: data['due_date'],
      priority: data['priority'] ?? 2,
      updated_at: data['updated_at'] ?? DateTime.now().toIso8601String(),
    );
    return TaskMapper.toEntity(dto);
  }

  Future<void> clearAllTasks() async {
    try {
      // Remove do Supabase
      await _supabase.from('tasks').delete().neq('id', '');
      
      // Remove do cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_tasks');
      await prefs.remove('last_sync_timestamp');
      
      print('✅ Todas as tarefas foram removidas do cache e Supabase');
    } catch (e) {
      print('❌ Erro ao limpar tarefas: $e');
      rethrow;
    }
  }
}