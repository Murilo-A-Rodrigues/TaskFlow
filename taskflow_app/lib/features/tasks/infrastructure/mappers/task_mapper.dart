import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../dtos/task_dto.dart';

/// TaskMapper - Conversor centralizado entre TaskDto e Task Entity
///
/// Esta classe é responsável por traduzir entre o formato de transporte (DTO)
/// e o formato interno da aplicação (Entity). Centraliza todas as regras de
/// conversão em um único local, facilitando manutenção e testes.
/// Segue o padrão Mapper do documento "Modelo DTO e Mapeamento".
class TaskMapper {
  /// Converte TaskDto (formato de rede/banco) para Task Entity (formato interno)
  ///
  /// Aplica conversões como:
  /// - String ISO8601 -> DateTime
  /// - snake_case -> camelCase
  /// - int -> TaskPriority enum
  /// - Validações defensivas
  static Task toEntity(TaskDto dto) {
    return Task(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      isCompleted: dto.is_completed,
      createdAt: DateTime.parse(dto.created_at),
      dueDate: dto.due_date != null ? DateTime.tryParse(dto.due_date!) : null,
      priority: TaskPriorityHelper.fromValue(dto.priority),
      updatedAt: DateTime.parse(dto.updated_at),
      categoryId: dto.category_id,
      userId: dto.user_id,
      isDeleted: dto.is_deleted,
      deletedAt: dto.deleted_at != null
          ? DateTime.tryParse(dto.deleted_at!)
          : null,
    );
  }

  /// Converte Task Entity (formato interno) para TaskDto (formato de rede/banco)
  ///
  /// Aplica conversões inversas como:
  /// - DateTime -> String ISO8601
  /// - camelCase -> snake_case
  /// - TaskPriority enum -> int
  static TaskDto toDto(Task entity) {
    return TaskDto(
      id: entity.id,
      title: entity.title,
      description: entity.description.isNotEmpty ? entity.description : null,
      is_completed: entity.isCompleted,
      created_at: entity.createdAt.toIso8601String(),
      due_date: entity.dueDate?.toIso8601String(),
      priority: entity.priority.value,
      updated_at: entity.updatedAt.toIso8601String(),
      category_id: entity.categoryId,
      user_id: entity.userId,
      is_deleted: entity.isDeleted,
      deleted_at: entity.deletedAt?.toIso8601String(),
    );
  }

  /// Converte lista de TaskDto para lista de Task Entity
  static List<Task> toEntityList(List<TaskDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de Task Entity para lista de TaskDto
  static List<TaskDto> toDtoList(List<Task> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte Map (vindo diretamente do Supabase) para Task Entity
  ///
  /// Útil para quando recebemos dados diretamente do Supabase
  /// sem passar pelo TaskDto primeiro
  static Task fromMap(Map<String, dynamic> map) {
    final dto = TaskDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte Task Entity para Map (para enviar ao Supabase)
  ///
  /// Útil para quando queremos enviar dados diretamente ao Supabase
  /// sem criar TaskDto primeiro
  static Map<String, dynamic> toMap(Task entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }

  /// Converte lista de Maps para lista de Task Entity
  static List<Task> fromMapList(List<Map<String, dynamic>> maps) {
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Converte lista de Task Entity para lista de Maps
  static List<Map<String, dynamic>> toMapList(List<Task> entities) {
    return entities.map((entity) => toMap(entity)).toList();
  }

  /// Atualiza um TaskDto existente com dados de uma Task Entity
  ///
  /// Ütil para operações de update onde queremos manter alguns
  /// campos do DTO original e atualizar outros com dados da Entity
  static TaskDto updateDtoFromEntity(TaskDto originalDto, Task updatedEntity) {
    return TaskDto(
      id: updatedEntity.id,
      title: updatedEntity.title,
      description: updatedEntity.description.isNotEmpty
          ? updatedEntity.description
          : null,
      is_completed: updatedEntity.isCompleted,
      created_at: originalDto.created_at, // Mantém created_at original
      due_date: updatedEntity.dueDate?.toIso8601String(),
      priority: updatedEntity.priority.value,
      updated_at: DateTime.now().toIso8601String(), // Atualiza timestamp
      category_id: updatedEntity.categoryId,
      user_id: updatedEntity.userId,
    );
  }
}
