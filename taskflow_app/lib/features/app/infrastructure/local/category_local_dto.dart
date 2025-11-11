import '../dtos/category_dto.dart';

/// Interface abstrata para persistência local de CategoryDto
/// 
/// Define o contrato para operações de cache local de categorias.
/// Implementações concretas devem fornecer mecanismos de armazenamento
/// (ex: SharedPreferences, SQLite, Hive, etc.).
abstract class CategoryLocalDto {
  /// Upsert em lote por id (insere novos e atualiza existentes).
  /// 
  /// Para cada DTO na lista, se o id já existir no cache, atualiza;
  /// caso contrário, insere como novo registro.
  /// 
  /// Parâmetros:
  /// - [dtos]: Lista de CategoryDto para persistir
  Future<void> upsertAll(List<CategoryDto> dtos);

  /// Lista todos os registros locais (DTOs).
  /// 
  /// Retorna lista vazia se não houver dados em cache ou em caso de erro.
  /// 
  /// Retorno:
  /// - Lista de CategoryDto do cache local
  Future<List<CategoryDto>> listAll();

  /// Busca por id (DTO).
  /// 
  /// Retorna null se não encontrar o registro com o id especificado.
  /// 
  /// Parâmetros:
  /// - [id]: Identificador único da categoria
  /// 
  /// Retorno:
  /// - CategoryDto se encontrado, null caso contrário
  Future<CategoryDto?> getById(String id);

  /// Limpa o cache (útil para reset/diagnóstico).
  /// 
  /// Remove todos os registros de categorias do armazenamento local.
  /// Útil para logout, reset de dados ou limpeza de diagnóstico.
  Future<void> clear();
}
