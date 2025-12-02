import 'package:flutter/foundation.dart';
import '../../domain/entities/provider.dart';
import '../../domain/repositories/providers_repository.dart';
import '../dtos/provider_dto.dart';
import '../local/providers_local_dao.dart';
import '../mappers/provider_mapper.dart';
import '../remote/providers_remote_api.dart';

/// Implementação concreta do repositório de Providers (Prompt 15)
/// 
/// Esta classe orquestra o fluxo de dados entre cache local (DAO) e
/// servidor remoto (Supabase). Implementa o padrão offline-first:
/// - Cache local é sempre a fonte da verdade para a UI
/// - Sincronização remota acontece em background
/// - Conversões DTO ↔ Entity são feitas nas fronteiras
class ProvidersRepositoryImpl implements ProvidersRepository {
  final ProvidersRemoteApi _remoteApi;
  final ProvidersLocalDao _localDao;

  ProvidersRepositoryImpl({
    required ProvidersRemoteApi remoteApi,
    required ProvidersLocalDao localDao,
  })  : _remoteApi = remoteApi,
        _localDao = localDao;

  @override
  Future<void> loadFromCache() async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] Carregando do cache...');
      }

      final dtos = await _localDao.listAll();

      if (kDebugMode) {
        print('[ProvidersRepository] ${dtos.length} providers carregados do cache');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao carregar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<int> syncFromServer() async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] ========== INICIANDO SINCRONIZAÇÃO ==========');
      }

      // ===== FASE 1: PUSH (Enviar mudanças locais) =====
      if (kDebugMode) {
        print('[ProvidersRepository] FASE 1: Enviando mudanças locais para servidor');
      }

      final localProviders = await _localDao.listAll();
      if (localProviders.isNotEmpty) {
        if (kDebugMode) {
          print('[ProvidersRepository] Enviando ${localProviders.length} providers locais');
        }

        try {
          await _remoteApi.upsertProviders(localProviders);

          if (kDebugMode) {
            print('[ProvidersRepository] Push concluído com sucesso');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[ProvidersRepository] Erro no push (continuando com pull): $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('[ProvidersRepository] Nenhum provider local para enviar');
        }
      }

      // ===== FASE 2: PULL (Buscar atualizações do servidor) =====
      if (kDebugMode) {
        print('[ProvidersRepository] FASE 2: Buscando atualizações do servidor');
      }

      // Busca timestamp da última sincronização para sync incremental
      final lastSync = await _localDao.getLastSync();
      if (kDebugMode) {
        if (lastSync != null) {
          print('[ProvidersRepository] Última sincronização: $lastSync');
          print('[ProvidersRepository] Modo: Sincronização incremental');
        } else {
          print('[ProvidersRepository] Primeira sincronização (full sync)');
        }
      }

      // Busca todas as páginas do servidor
      final allRemoteProviders = <ProviderDto>[];
      PageCursor? cursor;
      int pageCount = 0;

      do {
        pageCount++;
        if (kDebugMode) {
          print('[ProvidersRepository] Buscando página $pageCount...');
        }

        final page = await _remoteApi.fetchProviders(
          cursor: cursor,
          since: lastSync,
        );

        allRemoteProviders.addAll(page.data);
        cursor = page.nextCursor;

        if (kDebugMode) {
          print('[ProvidersRepository] Página $pageCount: ${page.data.length} providers');
        }
      } while (cursor != null);

      if (kDebugMode) {
        print('[ProvidersRepository] Total de providers remotos: ${allRemoteProviders.length}');
      }

      // Atualiza cache local com dados do servidor
      if (allRemoteProviders.isNotEmpty) {
        // Em sync incremental, precisamos mesclar com dados locais
        if (lastSync != null) {
          if (kDebugMode) {
            print('[ProvidersRepository] Mesclando dados remotos com cache local');
          }

          final localDtos = await _localDao.listAll();
          final localMap = {for (var dto in localDtos) dto.id: dto};

          // Atualiza o map com dados remotos (sobrescreve se existir)
          for (var remoteDto in allRemoteProviders) {
            localMap[remoteDto.id] = remoteDto;
          }

          await _localDao.upsertAll(localMap.values.toList());
        } else {
          // Full sync: substitui todo o cache
          if (kDebugMode) {
            print('[ProvidersRepository] Substituindo cache local completamente');
          }
          await _localDao.upsertAll(allRemoteProviders);
        }
      }

      // ===== FASE 3: Atualizar timestamp =====
      final now = DateTime.now();
      await _localDao.setLastSync(now);

      if (kDebugMode) {
        print('[ProvidersRepository] Timestamp de sincronização atualizado: $now');
        print('[ProvidersRepository] ========== SINCRONIZAÇÃO CONCLUÍDA ==========');
      }

      return allRemoteProviders.length;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro na sincronização: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<List<Provider>> listAll() async {
    try {
      final dtos = await _localDao.listAll();
      return dtos.map((dto) => ProviderMapper.toEntity(dto)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao listar: $e');
      }
      return [];
    }
  }

  @override
  Future<List<Provider>> listActive() async {
    try {
      final all = await listAll();
      return all.where((p) => p.isActive).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao listar ativos: $e');
      }
      return [];
    }
  }

  @override
  Future<Provider?> getById(String id) async {
    try {
      final dto = await _localDao.getById(id);
      if (dto == null) return null;
      return ProviderMapper.toEntity(dto);
    } catch (e) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao buscar por ID: $e');
      }
      return null;
    }
  }

  @override
  Future<Provider> createProvider(Provider provider) async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] Criando provider: ${provider.name}');
      }

      final dto = ProviderMapper.toDto(provider);

      // Salva localmente primeiro (optimistic update)
      await _localDao.upsertAll([dto]);

      // Envia para servidor
      try {
        await _remoteApi.upsertProviders([dto]);
      } catch (e) {
        if (kDebugMode) {
          print('[ProvidersRepository] Erro ao enviar ao servidor: $e');
          print('[ProvidersRepository] Dados salvos localmente, serão sincronizados depois');
        }
      }

      return provider;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao criar provider: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<Provider> updateProvider(Provider provider) async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] Atualizando provider: ${provider.id}');
      }

      // Atualiza timestamp
      final updated = ProviderMapper.withUpdatedTimestamp(provider);
      final dto = ProviderMapper.toDto(updated);

      // Atualiza localmente primeiro (optimistic update)
      await _localDao.upsertAll([dto]);

      // Envia para servidor
      try {
        await _remoteApi.upsertProviders([dto]);
      } catch (e) {
        if (kDebugMode) {
          print('[ProvidersRepository] Erro ao enviar ao servidor: $e');
          print('[ProvidersRepository] Dados salvos localmente, serão sincronizados depois');
        }
      }

      return updated;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao atualizar provider: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteProvider(String id) async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] Deletando provider: $id');
      }

      // Remove do cache local
      final all = await _localDao.listAll();
      final remaining = all.where((dto) => dto.id != id).toList();
      
      // Limpa e salva de volta sem o deletado
      await _localDao.clear();
      if (remaining.isNotEmpty) {
        await _localDao.upsertAll(remaining);
      }

      // Deleta do servidor
      try {
        await _remoteApi.deleteProvider(id);
      } catch (e) {
        if (kDebugMode) {
          print('[ProvidersRepository] Erro ao deletar no servidor: $e');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao deletar provider: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> clearAllProviders() async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] Limpando cache local de providers');
      }

      await _localDao.clear();

      if (kDebugMode) {
        print('[ProvidersRepository] Cache local limpo com sucesso');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro ao limpar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> forceSyncAll() async {
    try {
      if (kDebugMode) {
        print('[ProvidersRepository] Forçando full sync');
      }

      // Limpa marcador de última sync para forçar full sync
      await _localDao.setLastSync(DateTime(1970, 1, 1));

      // Executa sync (que agora será full sync)
      final synced = await syncFromServer();

      if (kDebugMode) {
        print('[ProvidersRepository] Full sync concluído: $synced providers');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersRepository] Erro no full sync: $e');
        print(stack);
      }
      rethrow;
    }
  }
}
