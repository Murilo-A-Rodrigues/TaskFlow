import '../../domain/entities/category.dart';
import '../dtos/category_dto.dart';

/// CategoryMapper - Conversor centralizado entre CategoryDto e Category Entity
/// 
/// Esta classe é responsável por traduzir entre o formato de transporte (DTO)
/// e o formato interno da aplicação (Entity). Centraliza todas as regras de
/// conversão em um único local, facilitando manutenção e testes.
/// Segue o padrão Mapper do documento "Modelo DTO e Mapeamento".
class CategoryMapper {
  /// Converte CategoryDto (formato de rede/banco) para Category Entity (formato interno)
  /// 
  /// Aplica conversões como:
  /// - String ISO8601 -> DateTime
  /// - snake_case -> camelCase
  /// - Validações defensivas
  static Category toEntity(CategoryDto dto) {
    return Category(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      userId: dto.user_id,
      parentId: dto.parent_id,
      color: dto.color,
      icon: dto.icon,
      sortOrder: dto.sort_order,
      isActive: dto.is_active,
      createdAt: DateTime.parse(dto.created_at),
      updatedAt: DateTime.parse(dto.updated_at),
    );
  }

  /// Converte Category Entity (formato interno) para CategoryDto (formato de rede/banco)
  /// 
  /// Aplica conversões inversas como:
  /// - DateTime -> String ISO8601
  /// - camelCase -> snake_case
  static CategoryDto toDto(Category entity) {
    return CategoryDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      user_id: entity.userId,
      parent_id: entity.parentId,
      color: entity.color,
      icon: entity.icon,
      sort_order: entity.sortOrder,
      is_active: entity.isActive,
      created_at: entity.createdAt.toIso8601String(),
      updated_at: entity.updatedAt.toIso8601String(),
    );
  }

  /// Converte lista de CategoryDto para lista de Category Entity
  static List<Category> toEntityList(List<CategoryDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de Category Entity para lista de CategoryDto
  static List<CategoryDto> toDtoList(List<Category> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte Map (vindo diretamente do Supabase) para Category Entity
  /// 
  /// Útil para quando recebemos dados diretamente do Supabase
  /// sem passar pelo CategoryDto primeiro
  static Category fromMap(Map<String, dynamic> map) {
    final dto = CategoryDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte Category Entity para Map (para enviar ao Supabase)
  /// 
  /// Útil para quando queremos enviar dados diretamente ao Supabase
  /// sem criar CategoryDto primeiro
  static Map<String, dynamic> toMap(Category entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }

  /// Converte lista de Maps para lista de Category Entity
  static List<Category> fromMapList(List<Map<String, dynamic>> maps) {
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Converte lista de Category Entity para lista de Maps
  static List<Map<String, dynamic>> toMapList(List<Category> entities) {
    return entities.map((entity) => toMap(entity)).toList();
  }

  /// Atualiza um CategoryDto existente com dados de uma Category Entity
  /// 
  /// Útil para operações de update onde queremos manter alguns
  /// campos do DTO original e atualizar outros com dados da Entity
  static CategoryDto updateDtoFromEntity(CategoryDto originalDto, Category updatedEntity) {
    return CategoryDto(
      id: originalDto.id,  // Mantém ID original
      name: updatedEntity.name,
      description: updatedEntity.description,
      user_id: updatedEntity.userId,
      parent_id: updatedEntity.parentId,
      color: updatedEntity.color,
      icon: updatedEntity.icon,
      sort_order: updatedEntity.sortOrder,
      is_active: updatedEntity.isActive,
      created_at: originalDto.created_at,  // Mantém data criação original
      updated_at: updatedEntity.updatedAt.toIso8601String(),
    );
  }

  /// Helpers para hierarquia - constrói árvore de categorias
  /// 
  /// Útil para transformar lista flat em estrutura hierárquica
  static List<CategoryWithChildren> buildTree(List<Category> categories) {
    final List<CategoryWithChildren> roots = [];
    final Map<String, List<Category>> childrenMap = {};

    // Agrupa filhos por pai
    for (final category in categories) {
      if (category.parentId == null) {
        roots.add(CategoryWithChildren(category: category, children: []));
      } else {
        childrenMap.putIfAbsent(category.parentId!, () => []);
        childrenMap[category.parentId!]!.add(category);
      }
    }

    // Constrói hierarquia recursivamente
    void buildChildren(CategoryWithChildren parent) {
      final children = childrenMap[parent.category.id] ?? [];
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      
      for (final child in children) {
        final childWithChildren = CategoryWithChildren(category: child, children: []);
        parent.children.add(childWithChildren);
        buildChildren(childWithChildren);
      }
    }

    // Aplica para todas as raízes
    for (final root in roots) {
      buildChildren(root);
    }

    // Ordena raízes
    roots.sort((a, b) => a.category.sortOrder.compareTo(b.category.sortOrder));
    
    return roots;
  }
}

/// Classe auxiliar para representar categorias com filhos
class CategoryWithChildren {
  final Category category;
  final List<CategoryWithChildren> children;

  CategoryWithChildren({
    required this.category,
    required this.children,
  });

  /// Conveniência para verificar se tem filhos
  bool get hasChildren => children.isNotEmpty;
  
  /// Conta total de descendentes
  int get totalDescendants {
    int count = children.length;
    for (final child in children) {
      count += child.totalDescendants;
    }
    return count;
  }

  /// Busca categoria por ID na subárvore
  Category? findById(String id) {
    if (category.id == id) return category;
    
    for (final child in children) {
      final found = child.findById(id);
      if (found != null) return found;
    }
    
    return null;
  }
}
