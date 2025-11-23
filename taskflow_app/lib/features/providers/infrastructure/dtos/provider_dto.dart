/// ProviderDto - Objeto de transferência de dados para provedores
class ProviderDto {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final bool is_active;
  final DateTime created_at;
  final DateTime? updated_at;

  const ProviderDto({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.is_active,
    required this.created_at,
    this.updated_at,
  });

  factory ProviderDto.fromMap(Map<String, dynamic> map) {
    return ProviderDto(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      is_active: map['is_active'] ?? true,
      created_at: DateTime.parse(map['created_at']),
      updated_at: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      'is_active': is_active,
      'created_at': created_at.toIso8601String(),
      if (updated_at != null) 'updated_at': updated_at!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ProviderDto(id: $id, name: $name, email: $email, is_active: $is_active)';
  }
}
