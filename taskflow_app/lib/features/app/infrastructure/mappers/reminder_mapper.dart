import '../../domain/entities/reminder.dart';
import '../dtos/reminder_dto.dart';

/// ReminderMapper - Conversor centralizado entre ReminderDto e Reminder Entity
///
/// Esta classe é responsável por traduzir entre o formato de transporte (DTO)
/// e o formato interno da aplicação (Entity). Centraliza todas as regras de
/// conversão em um único local, facilitando manutenção e testes.
/// Segue o padrão Mapper do documento "Modelo DTO e Mapeamento".
class ReminderMapper {
  /// Converte ReminderDto (formato de rede/banco) para Reminder Entity (formato interno)
  ///
  /// Aplica conversões como:
  /// - String ISO8601 -> DateTime
  /// - snake_case -> camelCase
  /// - String -> ReminderType enum
  /// - Validações defensivas
  static Reminder toEntity(ReminderDto dto) {
    return Reminder(
      id: dto.id,
      taskId: dto.task_id,
      userId: dto.user_id,
      reminderDate: DateTime.parse(dto.reminder_date),
      type: _stringToReminderType(dto.type),
      isActive: dto.is_active,
      createdAt: DateTime.parse(dto.created_at),
      customMessage: dto.custom_message,
    );
  }

  /// Converte Reminder Entity (formato interno) para ReminderDto (formato de rede/banco)
  ///
  /// Aplica conversões inversas como:
  /// - DateTime -> String ISO8601
  /// - camelCase -> snake_case
  /// - ReminderType enum -> String
  static ReminderDto toDto(Reminder entity) {
    return ReminderDto(
      id: entity.id,
      task_id: entity.taskId,
      user_id: entity.userId,
      reminder_date: entity.reminderDate.toIso8601String(),
      type: entity.type.name,
      is_active: entity.isActive,
      created_at: entity.createdAt.toIso8601String(),
      custom_message: entity.customMessage,
    );
  }

  /// Converte lista de ReminderDto para lista de Reminder Entity
  static List<Reminder> toEntityList(List<ReminderDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de Reminder Entity para lista de ReminderDto
  static List<ReminderDto> toDtoList(List<Reminder> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte Map (vindo diretamente do Supabase) para Reminder Entity
  ///
  /// Útil para quando recebemos dados diretamente do Supabase
  /// sem passar pelo ReminderDto primeiro
  static Reminder fromMap(Map<String, dynamic> map) {
    final dto = ReminderDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte Reminder Entity para Map (para enviar ao Supabase)
  ///
  /// Útil para quando queremos enviar dados diretamente ao Supabase
  /// sem criar ReminderDto primeiro
  static Map<String, dynamic> toMap(Reminder entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }

  /// Converte lista de Maps para lista de Reminder Entity
  static List<Reminder> fromMapList(List<Map<String, dynamic>> maps) {
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Converte lista de Reminder Entity para lista de Maps
  static List<Map<String, dynamic>> toMapList(List<Reminder> entities) {
    return entities.map((entity) => toMap(entity)).toList();
  }

  /// Atualiza um ReminderDto existente com dados de uma Reminder Entity
  ///
  /// Ütil para operações de update onde queremos manter alguns
  /// campos do DTO original e atualizar outros com dados da Entity
  static ReminderDto updateDtoFromEntity(
    ReminderDto originalDto,
    Reminder updatedEntity,
  ) {
    return ReminderDto(
      id: updatedEntity.id,
      task_id: updatedEntity.taskId,
      user_id: updatedEntity.userId,
      reminder_date: updatedEntity.reminderDate.toIso8601String(),
      type: updatedEntity.type.name,
      is_active: updatedEntity.isActive,
      created_at: originalDto.created_at, // Mantém created_at original
      custom_message: updatedEntity.customMessage,
    );
  }

  /// Helper privado: converte String para ReminderType enum
  ///
  /// Faz parsing defensivo do tipo de lembrete vindo do backend.
  /// Se o valor não for reconhecido, retorna ReminderType.once como padrão.
  static ReminderType _stringToReminderType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'once':
        return ReminderType.once;
      case 'daily':
        return ReminderType.daily;
      case 'weekly':
        return ReminderType.weekly;
      case 'monthly':
        return ReminderType.monthly;
      default:
        // Fallback seguro para tipo desconhecido
        return ReminderType.once;
    }
  }
}

/*
// Exemplo de uso:

// Entity -> DTO
final entity = Reminder(
  id: 'rem_123',
  taskId: 'task_456',
  reminderDate: DateTime(2024, 12, 15, 10, 0),
  type: ReminderType.daily,
  isActive: true,
  createdAt: DateTime.now(),
  customMessage: 'Revisar tarefa',
);

final dto = ReminderMapper.toDto(entity);
print(dto.type); // 'daily'
print(dto.task_id); // 'task_456' (snake_case)

// DTO -> Entity
final recoveredEntity = ReminderMapper.toEntity(dto);
print(recoveredEntity.taskId); // 'task_456' (camelCase)
print(recoveredEntity.type); // ReminderType.daily

// Map -> Entity (direto do Supabase)
final map = {
  'id': 'rem_789',
  'task_id': 'task_101',
  'reminder_date': '2024-12-20T15:30:00Z',
  'type': 'weekly',
  'is_active': true,
  'created_at': '2024-12-01T08:00:00Z',
};
final entityFromMap = ReminderMapper.fromMap(map);
print(entityFromMap.type); // ReminderType.weekly

// Listas
final dtos = [dto, ReminderMapper.toDto(entityFromMap)];
final entities = ReminderMapper.toEntityList(dtos);
print(entities.length); // 2
*/
