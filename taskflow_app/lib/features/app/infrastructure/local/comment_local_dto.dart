import '../dtos/comment_dto.dart';

/// Interface abstrata para persistência local de CommentDto
/// 
/// Define o contrato para operações de cache local de comentários.
/// Implementações concretas devem fornecer mecanismos de armazenamento
/// (ex: SharedPreferences, SQLite, Hive, etc.).
abstract class CommentLocalDto {
  /// Upsert em lote por id (insere novos e atualiza existentes).
  /// 
  /// Para cada DTO na lista, se o id já existir no cache, atualiza;
  /// caso contrário, insere como novo registro.
  /// 
  /// Parâmetros:
  /// - [dtos]: Lista de CommentDto para persistir
  Future<void> upsertAll(List<CommentDto> dtos);

  /// Lista todos os registros locais (DTOs).
  /// 
  /// Retorna lista vazia se não houver dados em cache ou em caso de erro.
  /// 
  /// Retorno:
  /// - Lista de CommentDto do cache local
  Future<List<CommentDto>> listAll();

  /// Busca por id (DTO).
  /// 
  /// Retorna null se não encontrar o registro com o id especificado.
  /// 
  /// Parâmetros:
  /// - [id]: Identificador único do comentário
  /// 
  /// Retorno:
  /// - CommentDto se encontrado, null caso contrário
  Future<CommentDto?> getById(String id);

  /// Limpa o cache (útil para reset/diagnóstico).
  /// 
  /// Remove todos os registros de comentários do armazenamento local.
  /// Útil para logout, reset de dados ou limpeza de diagnóstico.
  Future<void> clear();
}
