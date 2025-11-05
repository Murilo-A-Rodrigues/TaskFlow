import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/task_dto.dart';

/// DAO local para cache de tarefas
class TaskLocalDao {
  static const String _cacheKey = 'tasks_cache';
  
  Future<List<TaskDto>> getCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => TaskDto.fromMap(json)).toList();
    } catch (e) {
      print('❌ Erro ao carregar cache: $e');
      return [];
    }
  }
  
  Future<void> saveCachedTasks(List<TaskDto> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tasks.map((task) => task.toMap()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      print('✅ Cache salvo: ${tasks.length} tarefas');
    } catch (e) {
      print('❌ Erro ao salvar cache: $e');
    }
  }
  
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    print('🗑️ Cache limpo');
  }
}