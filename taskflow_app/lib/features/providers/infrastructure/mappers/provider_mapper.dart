import '../../domain/entities/provider.dart';
import '../dtos/provider_dto.dart';

/// ProviderMapper - Conversor entre ProviderDto e Provider Entity
class ProviderMapper {
  /// Converte DTO para Entity
  static Provider toEntity(ProviderDto dto) {
    return Provider(
      id: dto.id ?? '',
      name: dto.name,
      email: dto.email,
      phone: dto.phone,
      address: dto.address,
      isActive: dto.is_active,
      createdAt: dto.created_at,
      updatedAt: dto.updated_at,
    );
  }

  /// Converte Entity para DTO
  static ProviderDto toDto(Provider entity) {
    return ProviderDto(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      is_active: entity.isActive,
      created_at: entity.createdAt,
      updated_at: entity.updatedAt,
    );
  }

  /// Converte lista de DTOs para lista de Entities
  static List<Provider> toEntityList(List<ProviderDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de Entities para lista de DTOs
  static List<ProviderDto> toDtoList(List<Provider> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Cria Entity com timestamp atualizado
  static Provider withUpdatedTimestamp(Provider entity) {
    return entity.copyWith(updatedAt: DateTime.now());
  }

  /// Converte Map para Entity (usando DTO como intermediário)
  static Provider fromMap(Map<String, dynamic> map) {
    final dto = ProviderDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte Entity para Map (usando DTO como intermediário)
  static Map<String, dynamic> toMap(Provider entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }
}
