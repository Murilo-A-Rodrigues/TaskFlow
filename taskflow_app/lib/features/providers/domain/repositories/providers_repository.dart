import '../entities/provider.dart';

/// Interface do repositório de provedores
abstract class ProvidersRepository {
  Future<List<Provider>> getAllProviders();
  Future<Provider> createProvider(Provider provider);
  Future<Provider> updateProvider(Provider provider);
  Future<void> deleteProvider(String providerId);
  Future<Provider?> getProviderById(String providerId);
  Future<List<Provider>> getActiveProviders();
}
