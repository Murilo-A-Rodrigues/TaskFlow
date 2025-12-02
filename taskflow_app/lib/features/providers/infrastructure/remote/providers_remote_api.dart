import '../dtos/provider_dto.dart';

/// Classe auxiliar para paginação de dados remotos
class RemotePage<T> {
  final List<T> data;
  final PageCursor? nextCursor;

  const RemotePage({
    required this.data,
    this.nextCursor,
  });
}

/// Cursor para controle de paginação
class PageCursor {
  final int offset;
  final int limit;
  final dynamic value;

  const PageCursor({
    required this.offset,
    required this.limit,
    this.value,
  });
}

/// Interface da API remota para provedores (Prompt 15)
abstract class ProvidersRemoteApi {
  /// Busca provedores do servidor com suporte a paginação e sync incremental.
  Future<RemotePage<ProviderDto>> fetchProviders({
    PageCursor? cursor,
    DateTime? since,
    int limit = 100,
  });

  /// Envia múltiplos provedores para o servidor (batch upsert).
  Future<void> upsertProviders(List<ProviderDto> dtos);

  /// Deleta provedor no servidor.
  Future<void> deleteProvider(String id);
}
