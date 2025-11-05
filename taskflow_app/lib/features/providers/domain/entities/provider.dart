/// Provider Entity - Representa um provedor no domínio da aplicação
class Provider {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Provider({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Provider copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Provider(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Provider(id: $id, name: $name, email: $email, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Provider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}