import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../dtos/task_dto.dart';
import '../mappers/task_mapper.dart';

/// TaskRepositoryImpl - Implementa padrão offline-first com arquitetura DTO/Entity
/// 
/// Esta versão segue o padrão do documento "Modelo DTO e Mapeamento":
/// - Cache armazena DTOs (formato de rede eficiente)
/// - UI recebe Entities (formato interno limpo e validado)
/// - Mapper traduz entre os dois formatos
/// - Sincronização incremental baseada em updated_at
class TaskRepositoryImpl implements TaskRepository {
  static const String _cacheKey = 'taskflow_cache_v2';
  static const String _lastSyncKey = 'taskflow_last_sync_v2';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Obtém todas as tarefas seguindo padrão cache-first
  /// 
  /// Fluxo:
  /// 1. Carrega DTOs do cache local (rápido)
  /// 2. Converte DTOs para Entities (UI consome)
  /// 3. Sincroniza em background (incremental)
  /// 4. Atualiza cache com novos DTOs
  /// 5. Retorna Entities atualizadas
  @override
  Future<List<Task>> getAllTasks({bool forceSync = false}) async {
    try {
      print('📋 Carregando tarefas (cache-first)...');
      
      // 1. Cache-first: carrega DTOs do cache local
      final cachedDtos = await _loadDtosFromCache();
      print('📦 Cache local: ${cachedDtos.length} tarefas');
      
      // 2. Sincronização incremental em background
      if (forceSync || await _shouldSync()) {
        print('🔄 Iniciando sincronização...');
        await _syncIncrementally();
      }
      
      // 3. Recarrega cache após sync e converte para Entities
      final updatedDtos = await _loadDtosFromCache();
      final entities = TaskMapper.toEntityList(updatedDtos);
      
      print('✅ Retornando ${entities.length} tarefas como Entities');
      return entities;
      
    } catch (e) {
      print('❌ Erro no getAllTasks: $e');
      
      // Fallback: retorna cache mesmo com erro
      final cachedDtos = await _loadDtosFromCache();
      return TaskMapper.toEntityList(cachedDtos);
    }
  }
  
  /// Cria nova tarefa com optimistic update
  @override
  Future<Task> createTask(Task entity) async {
    try {
      print('🆕 Criando tarefa: ${entity.title}');
      
      // 1. Converte Entity para DTO
      final dto = TaskMapper.toDto(entity);
      
      // 2. Optimistic update - adiciona ao cache imediatamente
      await _addDtoToCache(dto);
      print('✅ Tarefa adicionada ao cache local');
      
      // 3. Tenta enviar para Supabase (não crítico)
      try {
        final taskMap = TaskMapper.toMap(entity);
        final response = await _supabase
            .from('tasks')
            .insert(taskMap)
            .select()
            .single();
        
        // 4. Atualiza cache com resposta do servidor
        final serverDto = TaskDto.fromMap(response);
        await _updateDtoInCache(serverDto);
        
        print('✅ Tarefa sincronizada com servidor');
        return TaskMapper.toEntity(serverDto);
      } catch (syncError) {
        print('⚠️ Falha na sincronização (funcionando offline): $syncError');
        // Retorna a versão do cache local
        return TaskMapper.toEntity(dto);
      }
      
    } catch (e) {
      print('❌ Erro crítico ao criar tarefa: $e');
      throw Exception('Falha ao criar tarefa: $e');
    }
  }
  
  /// Atualiza tarefa existente
  @override
  Future<Task> updateTask(Task entity) async {
    try {
      print('✏️ Atualizando tarefa: ${entity.title}');
      
      // 1. Cria DTO com timestamp atualizado
      final updatedEntity = TaskMapper.withUpdatedTimestamp(entity);
      final dto = TaskMapper.toDto(updatedEntity);
      
      // 2. Optimistic update no cache
      await _updateDtoInCache(dto);
      print('✅ Tarefa atualizada no cache local');
      
      // 3. Tenta enviar para Supabase (não crítico)
      try {
        final taskMap = TaskMapper.toMap(updatedEntity);
        final response = await _supabase
            .from('tasks')
            .update(taskMap)
            .eq('id', entity.id)
            .select()
            .single();
        
        // 4. Confirma no cache com resposta do servidor
        final serverDto = TaskDto.fromMap(response);
        await _updateDtoInCache(serverDto);
        
        print('✅ Tarefa sincronizada com servidor');
        return TaskMapper.toEntity(serverDto);
      } catch (syncError) {
        print('⚠️ Falha na sincronização (funcionando offline): $syncError');
        // Retorna a versão do cache local
        return TaskMapper.toEntity(dto);
      }
      
    } catch (e) {
      print('❌ Erro crítico ao atualizar tarefa: $e');
      throw Exception('Falha ao atualizar tarefa: $e');
    }
  }
  
  /// Remove tarefa
  @override
  Future<bool> deleteTask(String taskId) async {
    try {
      print('🗑️ Removendo tarefa: $taskId');
      
      // 1. Remove do cache imediatamente
      await _removeDtoFromCache(taskId);
      
      // 2. Remove do Supabase
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId);
      
      print('✅ Tarefa removida');
      return true;
      
    } catch (e) {
      print('❌ Erro ao remover tarefa: $e');
      return false;
    }
  }
  
  /// Força sincronização completa
  @override
  Future<void> forceSyncAll() async {
    try {
      print('🔄 Sincronização completa forçada...');
      
      final response = await _supabase
          .from('tasks')
          .select()
          .order('updated_at', ascending: false);
      
      if (response.isNotEmpty) {
        final dtos = response
            .map((map) => TaskDto.fromMap(map))
            .toList();
        
        await _saveDtosToCache(dtos);
        await _updateLastSync();
        
        print('✅ Cache atualizado com ${dtos.length} tarefas do servidor');
      }
      
    } catch (e) {
      print('❌ Erro na sincronização completa: $e');
      rethrow;
    }
  }
  
  /// Remove todas as tarefas (cache + servidor)
  @override
  Future<void> clearAllTasks() async {
    try {
      print('🧹 Limpando todas as tarefas...');
      
      // 1. Remove do Supabase
      await _supabase.from('tasks').delete().neq('id', '');
      
      // 2. Limpa cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastSyncKey);
      
      print('✅ Todas as tarefas removidas');
      
    } catch (e) {
      print('❌ Erro ao limpar tarefas: $e');
      rethrow;
    }
  }
  
  // ==================== MÉTODOS PRIVADOS (Cache com DTOs) ====================
  
  /// Carrega DTOs do cache local
  Future<List<TaskDto>> _loadDtosFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      
      if (cachedJson == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(cachedJson);
      return jsonList
          .map((json) => TaskDto.fromMap(json))
          .toList();
      
    } catch (e) {
      print('❌ Erro ao carregar DTOs do cache: $e');
      return [];
    }
  }
  
  /// Salva DTOs no cache local
  Future<void> _saveDtosToCache(List<TaskDto> dtos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = dtos.map((dto) => dto.toMap()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      
    } catch (e) {
      print('❌ Erro ao salvar DTOs no cache: $e');
    }
  }
  
  /// Adiciona DTO ao cache
  Future<void> _addDtoToCache(TaskDto dto) async {
    final dtos = await _loadDtosFromCache();
    dtos.add(dto);
    await _saveDtosToCache(dtos);
  }
  
  /// Atualiza DTO no cache
  Future<void> _updateDtoInCache(TaskDto dto) async {
    final dtos = await _loadDtosFromCache();
    final index = dtos.indexWhere((d) => d.id == dto.id);
    
    if (index != -1) {
      dtos[index] = dto;
    } else {
      dtos.add(dto);
    }
    
    await _saveDtosToCache(dtos);
  }
  
  /// Remove DTO do cache
  Future<void> _removeDtoFromCache(String taskId) async {
    final dtos = await _loadDtosFromCache();
    dtos.removeWhere((dto) => dto.id == taskId);
    await _saveDtosToCache(dtos);
  }
  
  /// Verifica se deve sincronizar
  Future<bool> _shouldSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      
      if (lastSyncString == null) return true;
      
      final lastSync = DateTime.parse(lastSyncString);
      final now = DateTime.now();
      
      // Sincroniza a cada 5 minutos
      return now.difference(lastSync).inMinutes >= 5;
      
    } catch (e) {
      return true;
    }
  }
  
  /// Sincronização incremental baseada em updated_at
  Future<void> _syncIncrementally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      
      if (lastSyncString == null) {
        // Primeira sincronização - busca tudo
        print('🔄 Primeira sincronização');
        await forceSyncAll();
        return;
      }
      
      // Sincronização incremental
      print('🔄 Sync incremental desde: $lastSyncString');
      
      final response = await _supabase
          .from('tasks')
          .select()
          .gt('updated_at', lastSyncString)
          .order('updated_at', ascending: false);
      
      if (response.isNotEmpty) {
        final newDtos = response
            .map((map) => TaskDto.fromMap(map))
            .toList();
        
        // Atualiza cache com novos dados
        final existingDtos = await _loadDtosFromCache();
        
        for (final newDto in newDtos) {
          final index = existingDtos.indexWhere((dto) => dto.id == newDto.id);
          if (index != -1) {
            existingDtos[index] = newDto;
          } else {
            existingDtos.add(newDto);
          }
        }
        
        await _saveDtosToCache(existingDtos);
        print('🔄 ${newDtos.length} tarefas sincronizadas');
      }
      
      await _updateLastSync();
      
    } catch (e) {
      print('❌ Erro na sincronização incremental: $e');
    }
  }
  
  /// Atualiza timestamp da última sincronização
  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Erro ao atualizar timestamp de sync: $e');
    }
  }
  
  /// Busca tarefa por ID
  @override
  Future<Task?> getTaskById(String taskId) async {
    try {
      // Busca no cache primeiro
      final cachedTasks = await _loadDtosFromCache();
      for (final dto in cachedTasks) {
        if (dto.id == taskId) {
          return TaskMapper.toEntity(dto);
        }
      }
      
      // Se não encontrou no cache, busca no servidor
      final response = await Supabase.instance.client
          .from('tasks')
          .select()
          .eq('id', taskId)
          .maybeSingle();
      
      if (response != null) {
        final dto = TaskDto.fromMap(response);
        return TaskMapper.toEntity(dto);
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao buscar tarefa por ID: $e');
      return null;
    }
  }



}