import 'package:uuid/uuid.dart';

/// User Entity - Representação interna rica e validada do usuário
/// 
/// Esta classe representa um usuário no domínio da aplicação TaskFlow.
/// Contém tipos fortes, validações e invariantes de domínio.
/// Segue o padrão Entity do documento "Modelo DTO e Mapeamento".
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  User({
    String? id,
    required String name,
    required String email,
    this.phone,
    this.avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
  })  : id = id ?? const Uuid().v4(),
        name = _validateName(name),
        email = _validateEmail(email),
        isActive = isActive ?? true,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Validação de nome - deve ser não vazio e trimmed
  static String _validateName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nome do usuário não pode ser vazio');
    }
    if (trimmedName.length < 2) {
      throw ArgumentError('Nome deve ter pelo menos 2 caracteres');
    }
    return trimmedName;
  }

  /// Validação de email - deve ter formato válido
  static String _validateEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email não pode ser vazio');
    }
    
    // Regex básico para validação de email
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      throw ArgumentError('Formato de email inválido');
    }
    
    return trimmedEmail;
  }

  /// Conveniências para a UI
  String get displayName => name;
  String get statusText => isActive ? 'Ativo' : 'Inativo';
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  /// Métodos de domínio
  User activate() {
    return copyWith(isActive: true, updatedAt: DateTime.now());
  }

  User deactivate() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  User updateLastLogin() {
    return copyWith(
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  User updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return copyWith(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      updatedAt: DateTime.now(),
    );
  }

  /// Copy with para imutabilidade
  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isActive: $isActive)';
  }
}
