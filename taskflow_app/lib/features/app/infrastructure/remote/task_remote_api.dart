import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/task_dto.dart';

/// API remota para comunicação com Supabase
class TaskRemoteApi {
  static const String _tableName = 'tasks';
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<List<TaskDto>> getAllTasks() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => TaskDto.fromMap(json))
        .toList();
  }
  
  Future<TaskDto> createTask(TaskDto dto) async {
    final response = await _supabase
        .from(_tableName)
        .insert(dto.toMap())
        .select()
        .single();
    
    return TaskDto.fromMap(response);
  }
  
  Future<TaskDto> updateTask(TaskDto dto) async {
    final response = await _supabase
        .from(_tableName)
        .update(dto.toMap())
        .eq('id', dto.id)
        .select()
        .single();
    
    return TaskDto.fromMap(response);
  }
  
  Future<void> deleteTask(String taskId) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', taskId);
  }
}
