import 'dart:convert';

/// ReminderDto - Data Transfer Object que espelha a tabela reminders do Supabase
/// 
/// Esta classe representa os dados como eles são transferidos de e para
/// o Supabase/rede. Os nomes dos campos seguem snake_case (igual ao banco)
/// e os tipos são primitivos para facilitar serialização.
/// Segue o padrão DTO do documento "Modelo DTO e Mapeamento".
class ReminderDto {
  final String id;
  final String task_id;           // snake_case igual ao banco
  final String reminder_date;     // ISO8601 String para o fio
  final String type;              // 'once', 'daily', 'weekly', 'monthly'
  final bool is_active;           // snake_case igual ao banco
  final String created_at;        // ISO8601 String
  final String? custom_message;   // Mensagem personalizada opcional

  ReminderDto({
    required this.id,
    required this.task_id,
    required this.reminder_date,
    required this.type,
    required this.is_active,
    required this.created_at,
    this.custom_message,
  });

  /// Factory para criar ReminderDto a partir de Map (vindo do Supabase)
  factory ReminderDto.fromMap(Map<String, dynamic> map) {
    return ReminderDto(
      id: map['id'] as String,
      task_id: map['task_id'] as String,
      reminder_date: map['reminder_date'] as String,
      type: map['type'] as String,
      is_active: map['is_active'] as bool? ?? true,
      created_at: map['created_at'] as String,
      custom_message: map['custom_message'] as String?,
    );
  }

  /// Converte ReminderDto para Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': task_id,
      'reminder_date': reminder_date,
      'type': type,
      'is_active': is_active,
      'created_at': created_at,
      'custom_message': custom_message,
    };
  }

  /// Factory para criar ReminderDto a partir de JSON string
  factory ReminderDto.fromJson(String jsonString) {
    final Map<String, dynamic> json = 
        Map<String, dynamic>.from(jsonDecode(jsonString));
    return ReminderDto.fromMap(json);
  }

  /// Converte ReminderDto para JSON string (para cache local)
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Cria uma cópia com valores opcionalmente modificados
  ReminderDto copyWith({
    String? id,
    String? task_id,
    String? reminder_date,
    String? type,
    bool? is_active,
    String? created_at,
    String? custom_message,
  }) {
    return ReminderDto(
      id: id ?? this.id,
      task_id: task_id ?? this.task_id,
      reminder_date: reminder_date ?? this.reminder_date,
      type: type ?? this.type,
      is_active: is_active ?? this.is_active,
      created_at: created_at ?? this.created_at,
      custom_message: custom_message ?? this.custom_message,
    );
  }

  @override
  String toString() {
    return 'ReminderDto(id: $id, task_id: $task_id, type: $type, '
        'reminder_date: $reminder_date, is_active: $is_active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderDto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/*
// Exemplo de uso:

// Criar DTO a partir de dados do Supabase
final map = {
  'id': 'rem_123',
  'task_id': 'task_456',
  'reminder_date': '2024-12-15T10:00:00Z',
  'type': 'once',
  'is_active': true,
  'created_at': '2024-12-01T08:00:00Z',
  'custom_message': 'Lembrete importante!',
};
final dto = ReminderDto.fromMap(map);

// Converter para JSON para cache
final json = dto.toJson();
print(json);

// Recuperar de JSON
final recovered = ReminderDto.fromJson(json);
print(recovered.task_id); // task_456

// Atualizar campos
final updated = dto.copyWith(is_active: false);
print(updated.is_active); // false

// Converter para Map para enviar ao Supabase
final mapToSend = updated.toMap();
print(mapToSend['is_active']); // false
*/
