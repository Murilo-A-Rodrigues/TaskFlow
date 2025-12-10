import '../../domain/entities/user.dart';
import '../dtos/user_dto.dart';

/// UserMapper - Conversor centralizado entre UserDto e User Entity
///
/// Esta classe é responsável por traduzir entre o formato de transporte (DTO)
/// e o formato interno da aplicação (Entity). Centraliza todas as regras de
/// conversão em um único local, facilitando manutenção e testes.
/// Segue o padrão Mapper do documento "Modelo DTO e Mapeamento".
class UserMapper {
  /// Converte UserDto (formato de rede/banco) para User Entity (formato interno)
  ///
  /// Aplica conversões como:
  /// - String ISO8601 -> DateTime
  /// - snake_case -> camelCase
  /// - Validações defensivas
  static User toEntity(UserDto dto) {
    return User(
      id: dto.id,
      name: dto.name,
      email: dto.email,
      phone: dto.phone,
      avatarUrl: dto.avatar_url,
      isActive: dto.is_active,
      createdAt: DateTime.parse(dto.created_at),
      updatedAt: DateTime.parse(dto.updated_at),
      lastLoginAt: dto.last_login_at != null
          ? DateTime.tryParse(dto.last_login_at!)
          : null,
    );
  }

  /// Converte User Entity (formato interno) para UserDto (formato de rede/banco)
  ///
  /// Aplica conversões inversas como:
  /// - DateTime -> String ISO8601
  /// - camelCase -> snake_case
  static UserDto toDto(User entity) {
    return UserDto(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      avatar_url: entity.avatarUrl,
      is_active: entity.isActive,
      created_at: entity.createdAt.toIso8601String(),
      updated_at: entity.updatedAt.toIso8601String(),
      last_login_at: entity.lastLoginAt?.toIso8601String(),
    );
  }

  /// Converte lista de UserDto para lista de User Entity
  static List<User> toEntityList(List<UserDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de User Entity para lista de UserDto
  static List<UserDto> toDtoList(List<User> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte Map (vindo diretamente do Supabase) para User Entity
  ///
  /// Útil para quando recebemos dados diretamente do Supabase
  /// sem passar pelo UserDto primeiro
  static User fromMap(Map<String, dynamic> map) {
    final dto = UserDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte User Entity para Map (para enviar ao Supabase)
  ///
  /// Útil para quando queremos enviar dados diretamente ao Supabase
  /// sem criar UserDto primeiro
  static Map<String, dynamic> toMap(User entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }

  /// Converte lista de Maps para lista de User Entity
  static List<User> fromMapList(List<Map<String, dynamic>> maps) {
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Converte lista de User Entity para lista de Maps
  static List<Map<String, dynamic>> toMapList(List<User> entities) {
    return entities.map((entity) => toMap(entity)).toList();
  }

  /// Atualiza um UserDto existente com dados de uma User Entity
  ///
  /// Útil para operações de update onde queremos manter alguns
  /// campos do DTO original e atualizar outros com dados da Entity
  static UserDto updateDtoFromEntity(UserDto originalDto, User updatedEntity) {
    return UserDto(
      id: originalDto.id, // Mantém ID original
      name: updatedEntity.name,
      email: updatedEntity.email,
      phone: updatedEntity.phone,
      avatar_url: updatedEntity.avatarUrl,
      is_active: updatedEntity.isActive,
      created_at: originalDto.created_at, // Mantém data criação original
      updated_at: updatedEntity.updatedAt.toIso8601String(),
      last_login_at: updatedEntity.lastLoginAt?.toIso8601String(),
    );
  }
}
