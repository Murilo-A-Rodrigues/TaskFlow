import '../../domain/entities/project.dart';
import '../../domain/entities/project_status.dart';
import '../dtos/project_dto.dart';

/// ProjectMapper - Conversor centralizado entre ProjectDto e Project Entity
///
/// Esta classe é responsável por traduzir entre o formato de transporte (DTO)
/// e o formato interno da aplicação (Entity). Centraliza todas as regras de
/// conversão em um único local, facilitando manutenção e testes.
/// Segue o padrão Mapper do documento "Modelo DTO e Mapeamento".
class ProjectMapper {
  /// Converte ProjectDto (formato de rede/banco) para Project Entity (formato interno)
  ///
  /// Aplica conversões como:
  /// - String ISO8601 -> DateTime
  /// - snake_case -> camelCase
  /// - String -> ProjectStatus enum
  /// - Validações defensivas
  static Project toEntity(ProjectDto dto) {
    return Project(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      ownerId: dto.owner_id,
      status: ProjectStatus.fromValue(dto.status),
      startDate: dto.start_date != null
          ? DateTime.tryParse(dto.start_date!)
          : null,
      endDate: dto.end_date != null ? DateTime.tryParse(dto.end_date!) : null,
      deadline: dto.deadline != null ? DateTime.tryParse(dto.deadline!) : null,
      color: dto.color,
      isArchived: dto.is_archived,
      createdAt: DateTime.parse(dto.created_at),
      updatedAt: DateTime.parse(dto.updated_at),
    );
  }

  /// Converte Project Entity (formato interno) para ProjectDto (formato de rede/banco)
  ///
  /// Aplica conversões inversas como:
  /// - DateTime -> String ISO8601
  /// - camelCase -> snake_case
  /// - ProjectStatus enum -> String
  static ProjectDto toDto(Project entity) {
    return ProjectDto(
      id: entity.id,
      name: entity.name,
      description: entity.description.isNotEmpty ? entity.description : null,
      owner_id: entity.ownerId,
      status: entity.status.value,
      start_date: entity.startDate?.toIso8601String(),
      end_date: entity.endDate?.toIso8601String(),
      deadline: entity.deadline?.toIso8601String(),
      color: entity.color,
      is_archived: entity.isArchived,
      created_at: entity.createdAt.toIso8601String(),
      updated_at: entity.updatedAt.toIso8601String(),
    );
  }

  /// Converte lista de ProjectDto para lista de Project Entity
  static List<Project> toEntityList(List<ProjectDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de Project Entity para lista de ProjectDto
  static List<ProjectDto> toDtoList(List<Project> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte Map (vindo diretamente do Supabase) para Project Entity
  ///
  /// Útil para quando recebemos dados diretamente do Supabase
  /// sem passar pelo ProjectDto primeiro
  static Project fromMap(Map<String, dynamic> map) {
    final dto = ProjectDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte Project Entity para Map (para enviar ao Supabase)
  ///
  /// Útil para quando queremos enviar dados diretamente ao Supabase
  /// sem criar ProjectDto primeiro
  static Map<String, dynamic> toMap(Project entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }

  /// Converte lista de Maps para lista de Project Entity
  static List<Project> fromMapList(List<Map<String, dynamic>> maps) {
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Converte lista de Project Entity para lista de Maps
  static List<Map<String, dynamic>> toMapList(List<Project> entities) {
    return entities.map((entity) => toMap(entity)).toList();
  }

  /// Atualiza um ProjectDto existente com dados de uma Project Entity
  ///
  /// Útil para operações de update onde queremos manter alguns
  /// campos do DTO original e atualizar outros com dados da Entity
  static ProjectDto updateDtoFromEntity(
    ProjectDto originalDto,
    Project updatedEntity,
  ) {
    return ProjectDto(
      id: originalDto.id, // Mantém ID original
      name: updatedEntity.name,
      description: updatedEntity.description.isNotEmpty
          ? updatedEntity.description
          : null,
      owner_id: updatedEntity.ownerId,
      status: updatedEntity.status.value,
      start_date: updatedEntity.startDate?.toIso8601String(),
      end_date: updatedEntity.endDate?.toIso8601String(),
      deadline: updatedEntity.deadline?.toIso8601String(),
      color: updatedEntity.color,
      is_archived: updatedEntity.isArchived,
      created_at: originalDto.created_at, // Mantém data criação original
      updated_at: updatedEntity.updatedAt.toIso8601String(),
    );
  }
}
