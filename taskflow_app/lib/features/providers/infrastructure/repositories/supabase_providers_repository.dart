import '../../domain/entities/provider.dart';
import '../../domain/repositories/providers_repository.dart';
import '../dtos/provider_dto.dart';
import '../mappers/provider_mapper.dart';
import '../local/providers_local_dao.dart';
import '../remote/providers_remote_api.dart';

/// Implementação do repositório de provedores com padrão offline-first
class SupabaseProvidersRepository implements ProvidersRepository {
  final ProvidersRemoteApi _remoteApi = ProvidersRemoteApi();
  final ProvidersLocalDao _localDao = ProvidersLocalDao();

  @override
  Future<List<Provider>> getAllProviders() async {
    try {
      // Busca do cache primeiro (offline-first)
      final cachedProviders = await _localDao.getCachedProviders();
      
      // Se tem cache, retorna e sincroniza em background
      if (cachedProviders.isNotEmpty) {
        _syncInBackground();
        return ProviderMapper.toEntityList(cachedProviders);
      }
      
      // Se não tem cache, busca do servidor
      final remoteDtos = await _remoteApi.getAllProviders();
      await _localDao.saveCachedProviders(remoteDtos);
      
      return ProviderMapper.toEntityList(remoteDtos);
    } catch (e) {
      print('❌ Erro ao buscar provedores: $e');
      
      // Em caso de erro, tenta retornar o cache
      final cachedProviders = await _localDao.getCachedProviders();
      return ProviderMapper.toEntityList(cachedProviders);
    }
  }

  @override
  Future<Provider> createProvider(Provider provider) async {
    try {
      final dto = ProviderMapper.toDto(provider);
      final createdDto = await _remoteApi.createProvider(dto);
      
      // Atualiza cache
      await _updateCacheAfterCreate(createdDto);
      
      return ProviderMapper.toEntity(createdDto);
    } catch (e) {
      print('❌ Erro ao criar provedor: $e');
      throw Exception('Falha ao criar provedor: $e');
    }
  }

  @override
  Future<Provider> updateProvider(Provider provider) async {
    try {
      final updatedProvider = ProviderMapper.withUpdatedTimestamp(provider);
      final dto = ProviderMapper.toDto(updatedProvider);
      final updatedDto = await _remoteApi.updateProvider(dto);
      
      // Atualiza cache
      await _updateCacheAfterUpdate(updatedDto);
      
      return ProviderMapper.toEntity(updatedDto);
    } catch (e) {
      print('❌ Erro ao atualizar provedor: $e');
      throw Exception('Falha ao atualizar provedor: $e');
    }
  }

  @override
  Future<void> deleteProvider(String providerId) async {
    try {
      await _remoteApi.deleteProvider(providerId);
      
      // Remove do cache
      await _removeFromCache(providerId);
    } catch (e) {
      print('❌ Erro ao deletar provedor: $e');
      throw Exception('Falha ao deletar provedor: $e');
    }
  }

  @override
  Future<Provider?> getProviderById(String providerId) async {
    try {
      // Busca no cache primeiro
      final cachedProviders = await _localDao.getCachedProviders();
      final cachedProvider = cachedProviders
          .where((dto) => dto.id == providerId)
          .firstOrNull;
      
      if (cachedProvider != null) {
        return ProviderMapper.toEntity(cachedProvider);
      }
      
      // Se não encontrou no cache, busca no servidor
      final remoteDto = await _remoteApi.getProviderById(providerId);
      if (remoteDto != null) {
        return ProviderMapper.toEntity(remoteDto);
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao buscar provedor por ID: $e');
      return null;
    }
  }

  @override
  Future<List<Provider>> getActiveProviders() async {
    try {
      final activeDtos = await _remoteApi.getActiveProviders();
      return ProviderMapper.toEntityList(activeDtos);
    } catch (e) {
      print('❌ Erro ao buscar provedores ativos: $e');
      
      // Fallback para cache, filtrando apenas os ativos
      final cachedProviders = await _localDao.getCachedProviders();
      final activeProviders = cachedProviders
          .where((dto) => dto.is_active)
          .toList();
      
      return ProviderMapper.toEntityList(activeProviders);
    }
  }

  /// Sincronização em background
  Future<void> _syncInBackground() async {
    try {
      final remoteDtos = await _remoteApi.getAllProviders();
      await _localDao.saveCachedProviders(remoteDtos);
    } catch (e) {
      print('⚠️ Sync em background falhou: $e');
    }
  }

  /// Atualiza cache após criar
  Future<void> _updateCacheAfterCreate(ProviderDto newDto) async {
    final cachedProviders = await _localDao.getCachedProviders();
    cachedProviders.insert(0, newDto); // Adiciona no início
    await _localDao.saveCachedProviders(cachedProviders);
  }

  /// Atualiza cache após modificar
  Future<void> _updateCacheAfterUpdate(ProviderDto updatedDto) async {
    final cachedProviders = await _localDao.getCachedProviders();
    final index = cachedProviders.indexWhere((dto) => dto.id == updatedDto.id);
    
    if (index != -1) {
      cachedProviders[index] = updatedDto;
      await _localDao.saveCachedProviders(cachedProviders);
    }
  }

  /// Remove do cache
  Future<void> _removeFromCache(String providerId) async {
    final cachedProviders = await _localDao.getCachedProviders();
    cachedProviders.removeWhere((dto) => dto.id == providerId);
    await _localDao.saveCachedProviders(cachedProviders);
  }
}