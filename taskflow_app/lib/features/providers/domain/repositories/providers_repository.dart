import '../entities/provider.dart';

/// Interface do repositório de Providers (Prompt 14)
/// 
/// Define o contrato para gerenciamento de provedores seguindo
/// o padrão offline-first com sincronização bidirecional.
/// 
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e permite criar mocks para testes unitários.
/// 
/// ⚠️ Boas práticas ao implementar:
/// - Certifique-se de que a entidade Provider possui métodos de conversão robustos 
///   entre Entity e DTO (Map<String, dynamic>).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode) 
///   nos métodos principais para facilitar o diagnóstico de problemas de cache, 
///   conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está 
///   "mounted" antes de chamar setState, evitando exceções de widget desmontado.
abstract class ProvidersRepository {
  /// Carrega provedores do cache local.
  Future<void> loadFromCache();

  /// Sincroniza dados com servidor remoto (Push-then-Pull).
  Future<int> syncFromServer();

  /// Lista todos os provedores disponíveis localmente.
  Future<List<Provider>> listAll();

  /// Lista apenas provedores ativos.
  Future<List<Provider>> listActive();

  /// Busca provedor por ID.
  Future<Provider?> getById(String id);

  /// Cria novo provedor.
  Future<Provider> createProvider(Provider provider);

  /// Atualiza provedor existente.
  Future<Provider> updateProvider(Provider provider);

  /// Deleta provedor.
  Future<void> deleteProvider(String id);

  /// Limpa todo o cache local de provedores.
  Future<void> clearAllProviders();

  /// Força sincronização completa (full sync).
  Future<void> forceSyncAll();
}
