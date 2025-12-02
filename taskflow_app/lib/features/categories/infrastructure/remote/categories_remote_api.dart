import '../../../app/infrastructure/dtos/category_dto.dart';

/// Representa uma página de dados retornada pela API remota
/// 
/// Contém os dados solicitados e um cursor opcional para buscar a próxima página
class RemotePage<T> {
  final List<T> data;
  final PageCursor? nextCursor;

  const RemotePage({
    required this.data,
    this.nextCursor,
  });
}

/// Cursor para paginação de dados remotos
/// 
/// Usado para buscar páginas subsequentes de dados da API
class PageCursor {
  final int offset;
  final int limit;

  const PageCursor({
    required this.offset,
    required this.limit,
  });
}

/// Interface para comunicação com API remota de categorias
/// 
/// Define os contratos que qualquer implementação de datasource remoto
/// (Supabase, REST API, GraphQL, etc) deve seguir
abstract class CategoriesRemoteApi {
  /// Busca categorias do servidor com suporte a paginação e sincronização incremental
  /// 
  /// [cursor] - Cursor de paginação para buscar páginas específicas
  /// [since] - Timestamp para buscar apenas categorias modificadas após essa data
  /// 
  /// Retorna uma página de CategoryDto com cursor para próxima página se houver
  Future<RemotePage<CategoryDto>> fetchCategories({
    PageCursor? cursor,
    DateTime? since,
  });

  /// Envia categorias locais para o servidor (upsert)
  /// 
  /// Cria novas categorias ou atualiza existentes no servidor remoto
  /// 
  /// [categories] - Lista de categorias a serem sincronizadas
  /// 
  /// Retorna lista de categorias após processamento no servidor
  Future<List<CategoryDto>> upsertCategories(List<CategoryDto> categories);
}
