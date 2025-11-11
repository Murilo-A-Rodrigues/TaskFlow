import '../dtos/user_dto.dart';

/// Interface abstrata para persistência local de UserDto
/// 
/// Define o contrato para operações de cache local de usuários.
/// Implementações concretas devem fornecer mecanismos de armazenamento
/// (ex: SharedPreferences, SQLite, Hive, etc.).
abstract class UserLocalDto {
  /// Upsert em lote por id (insere novos e atualiza existentes).
  /// 
  /// Para cada DTO na lista, se o id já existir no cache, atualiza;
  /// caso contrário, insere como novo registro.
  /// 
  /// Parâmetros:
  /// - [dtos]: Lista de UserDto para persistir
  Future<void> upsertAll(List<UserDto> dtos);

  /// Lista todos os registros locais (DTOs).
  /// 
  /// Retorna lista vazia se não houver dados em cache ou em caso de erro.
  /// 
  /// Retorno:
  /// - Lista de UserDto do cache local
  Future<List<UserDto>> listAll();

  /// Busca por id (DTO).
  /// 
  /// Retorna null se não encontrar o registro com o id especificado.
  /// 
  /// Parâmetros:
  /// - [id]: Identificador único do usuário
  /// 
  /// Retorno:
  /// - UserDto se encontrado, null caso contrário
  Future<UserDto?> getById(String id);

  /// Limpa o cache (útil para reset/diagnóstico).
  /// 
  /// Remove todos os registros de usuários do armazenamento local.
  /// Útil para logout, reset de dados ou limpeza de diagnóstico.
  Future<void> clear();
}
