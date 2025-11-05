import 'package:uuid/uuid.dart';

/// Category Entity - Representação interna rica e validada da categoria
/// 
/// Esta classe representa uma categoria no domínio da aplicação TaskFlow.
/// Contém tipos fortes, validações e invariantes de domínio para hierarquia.
/// Segue o padrão Entity do documento "Modelo DTO e Mapeamento".
class Category {
  final String id;
  final String name;
  final String? description;
  final String userId;            // FK para User - categorias são por usuário
  final String? parentId;         // FK para Category - hierarquia opcional
  final String color;            // Cor em hex (obrigatória para UI)
  final String? icon;            // Ícone opcional (nome do ícone)
  final int sortOrder;           // Ordem de exibição
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    String? id,
    required String name,
    this.description,
    required String userId,
    this.parentId,
    String? color,
    this.icon,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        name = _validateName(name),
        userId = _validateUserId(userId),
        color = _validateColor(color ?? '#2196F3'),
        sortOrder = sortOrder ?? 0,
        isActive = isActive ?? true,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    _validateHierarchy();
  }

  /// Validação de nome - deve ser único por usuário (validação no repository)
  static String _validateName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nome da categoria não pode ser vazio');
    }
    if (trimmedName.length < 2) {
      throw ArgumentError('Nome deve ter pelo menos 2 caracteres');
    }
    if (trimmedName.length > 50) {
      throw ArgumentError('Nome deve ter no máximo 50 caracteres');
    }
    return trimmedName;
  }

  /// Validação de user ID
  static String _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('ID do usuário não pode ser vazio');
    }
    return userId.trim();
  }

  /// Validação de cor - deve ser hex válido
  static String _validateColor(String color) {
    final trimmedColor = color.trim();
    
    // Adiciona # se não tiver
    final hexColor = trimmedColor.startsWith('#') ? trimmedColor : '#$trimmedColor';
    
    // Valida formato hex
    final hexRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    if (!hexRegex.hasMatch(hexColor)) {
      throw ArgumentError('Cor deve estar em formato hex válido (#RRGGBB ou #RGB)');
    }
    
    return hexColor.toUpperCase();
  }

  /// Validação de hierarquia
  void _validateHierarchy() {
    // Não pode ser pai de si mesmo
    if (parentId == id) {
      throw ArgumentError('Categoria não pode ser pai de si mesma');
    }
  }

  /// Conveniências para a UI
  String get displayName => name;
  bool get hasParent => parentId != null;
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasIcon => icon != null && icon!.isNotEmpty;
  
  /// Helpers para cor
  String get colorWithoutHash => color.replaceFirst('#', '');
  int get colorValue => int.parse(colorWithoutHash, radix: 16);

  /// Métodos de domínio
  Category activate() {
    return copyWith(isActive: true, updatedAt: DateTime.now());
  }

  Category deactivate() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  Category moveTo({String? newParentId}) {
    // Validação básica - não pode mover para si mesmo
    if (newParentId == id) {
      throw ArgumentError('Categoria não pode ser movida para si mesma');
    }
    
    return copyWith(
      parentId: newParentId,
      updatedAt: DateTime.now(),
    );
  }

  Category updateOrder(int newOrder) {
    return copyWith(
      sortOrder: newOrder,
      updatedAt: DateTime.now(),
    );
  }

  Category updateAppearance({
    String? color,
    String? icon,
  }) {
    return copyWith(
      color: color,
      icon: icon,
      updatedAt: DateTime.now(),
    );
  }

  /// Validação de profundidade de hierarquia (deve ser implementada no service)
  static const int maxDepth = 5;
  
  /// Copy with para imutabilidade
  Category copyWith({
    String? name,
    String? description,
    String? userId,
    String? parentId = 'KEEP_ORIGINAL', // Marker para distinguir de null
    String? color,
    String? icon,
    int? sortOrder,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      parentId: parentId == 'KEEP_ORIGINAL' ? this.parentId : parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, userId: $userId, parent: $parentId)';
  }
}