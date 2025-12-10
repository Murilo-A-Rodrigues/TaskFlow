import 'package:flutter/foundation.dart' hide Category;
import '../../../app/domain/entities/category.dart';
import '../../../app/infrastructure/dtos/category_dto.dart';
import '../../../app/infrastructure/mappers/category_mapper.dart';
import '../../domain/repositories/categories_repository.dart';
import '../local/categories_local_dao.dart';
import '../remote/categories_remote_api.dart';

/// Implementação concreta do repositório de categorias
///
/// Esta classe coordena operações entre:
/// - Cache local (CategoriesLocalDao)
/// - API remota (CategoriesRemoteApi)
/// - Conversão entre DTOs e Entities (CategoryMapper)
///
/// Responsabilidades:
/// - Gerenciar estratégia de cache (cache-first)
/// - Sincronizar dados locais com servidor
/// - Converter entre camadas (DTO <-> Entity)
/// - Tratar erros e fallbacks
class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesLocalDao _localDao;
  final CategoriesRemoteApi _remoteApi;

  CategoriesRepositoryImpl({
    required CategoriesLocalDao localDao,
    required CategoriesRemoteApi remoteApi,
  }) : _localDao = localDao,
       _remoteApi = remoteApi;

  /// Carrega categorias do cache local (para render rápido inicial)
  @override
  Future<List<Category>> loadFromCache() async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Carregando do cache local');
      }

      final dtos = await _localDao.listAll();
      final entities = dtos
          .where((dto) => !dto.is_deleted) // Filtra categorias deletadas
          .map(CategoryMapper.toEntity)
          .toList();

      if (kDebugMode) {
        print(
          '[CategoriesRepository] ${entities.length} categorias carregadas do cache',
        );
      }

      return entities;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao carregar do cache: $e');
        print(stack);
      }
      return [];
    }
  }

  /// Lista todas as categorias do cache local
  @override
  Future<List<Category>> listAll() async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Listando categorias do cache local');
      }

      final dtos = await _localDao.listAll();
      final entities = dtos
          .where((dto) => !dto.is_deleted) // Filtra categorias deletadas
          .map(CategoryMapper.toEntity)
          .toList();

      if (kDebugMode) {
        print(
          '[CategoriesRepository] ${entities.length} categorias retornadas',
        );
      }

      return entities;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao listar categorias: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Cria uma nova categoria
  ///
  /// Fluxo:
  /// 1. Salva no cache local
  /// 2. Retorna entity criada
  ///
  /// Nota: Sincronização com servidor ocorre via syncFromServer()
  @override
  Future<Category> createCategory(Category category) async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Criando categoria: ${category.name}');
      }

      // Converte para DTO e salva localmente
      final dto = CategoryMapper.toDto(category);
      await _localDao.upsert(dto);

      if (kDebugMode) {
        print(
          '[CategoriesRepository] Categoria ${category.id} criada com sucesso',
        );
      }

      return category;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao criar categoria: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Atualiza uma categoria existente
  ///
  /// Fluxo:
  /// 1. Atualiza no cache local
  /// 2. Retorna entity atualizada
  ///
  /// Nota: Sincronização com servidor ocorre via syncFromServer()
  @override
  Future<Category> updateCategory(Category category) async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Atualizando categoria: ${category.id}');
      }

      // Converte para DTO e atualiza localmente
      final dto = CategoryMapper.toDto(category);
      await _localDao.upsert(dto);

      if (kDebugMode) {
        print(
          '[CategoriesRepository] Categoria ${category.id} atualizada com sucesso',
        );
      }

      return category;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao atualizar categoria: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Remove uma categoria por ID (soft delete)
  ///
  /// Fluxo:
  /// 1. Marca categoria como deletada (is_deleted = true)
  /// 2. Define timestamp de deleção (deleted_at)
  /// 3. Atualiza no cache local
  /// 4. Sincroniza com servidor
  ///
  /// Nota: Não remove fisicamente, apenas marca como deletada
  @override
  Future<void> deleteCategory(String id) async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Deletando categoria (soft delete): $id');
      }

      // Busca a categoria atual
      final categories = await _localDao.listAll();
      final categoryDto = categories.firstWhere((c) => c.id == id);

      // Marca como deletada com timestamp
      final deletedCategory = categoryDto.copyWith(
        is_deleted: true,
        deleted_at: DateTime.now().toIso8601String(),
        updated_at: DateTime.now().toIso8601String(),
      );

      // Atualiza no cache local
      await _localDao.upsert(deletedCategory);

      // Sincroniza com servidor
      await _remoteApi.upsertCategories([deletedCategory]);

      if (kDebugMode) {
        print('[CategoriesRepository] Categoria $id marcada como deletada');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao deletar categoria: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Lista categorias ativas (filtradas do cache)
  @override
  Future<List<Category>> listActive() async {
    try {
      final all = await listAll();
      final active = all.where((c) => c.isActive).toList();

      if (kDebugMode) {
        print(
          '[CategoriesRepository] ${active.length} categorias ativas de ${all.length}',
        );
      }

      return active;
    } catch (e) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao listar ativas: $e');
      }
      return [];
    }
  }

  /// Lista categorias raiz (sem parent_id)
  @override
  Future<List<Category>> listRootCategories() async {
    try {
      final all = await listAll();
      final roots = all.where((c) => c.parentId == null).toList();

      if (kDebugMode) {
        print('[CategoriesRepository] ${roots.length} categorias raiz');
      }

      return roots;
    } catch (e) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao listar raiz: $e');
      }
      return [];
    }
  }

  /// Lista subcategorias de uma categoria pai
  @override
  Future<List<Category>> listSubcategories(String parentId) async {
    try {
      final all = await listAll();
      final subs = all.where((c) => c.parentId == parentId).toList();

      if (kDebugMode) {
        print(
          '[CategoriesRepository] ${subs.length} subcategorias de $parentId',
        );
      }

      return subs;
    } catch (e) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao listar subcategorias: $e');
      }
      return [];
    }
  }

  /// Busca uma categoria específica por ID
  @override
  Future<Category?> getById(String id) async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Buscando categoria: $id');
      }

      final dto = await _localDao.getById(id);
      if (dto == null) {
        if (kDebugMode) {
          print('[CategoriesRepository] Categoria $id não encontrada');
        }
        return null;
      }

      final entity = CategoryMapper.toEntity(dto);

      if (kDebugMode) {
        print(
          '[CategoriesRepository] Categoria $id encontrada: ${entity.name}',
        );
      }

      return entity;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao buscar categoria: $e');
        print(stack);
      }
      return null;
    }
  }

  /// Sincroniza dados locais com o servidor remoto
  ///
  /// Estratégia: Push-then-Pull
  ///
  /// 1. PUSH: Envia mudanças locais para o servidor
  ///    - Busca todas as categorias locais
  ///    - Envia para o servidor (upsert)
  ///
  /// 2. PULL: Busca atualizações do servidor
  ///    - Usa timestamp da última sync para busca incremental
  ///    - Busca todas as páginas disponíveis
  ///    - Atualiza cache local com dados do servidor
  ///
  /// Sincroniza dados locais com o servidor remoto
  ///
  /// Estratégia: Push-then-Pull
  ///
  /// 1. PUSH: Envia mudanças locais para o servidor
  /// 2. PULL: Busca atualizações do servidor
  /// 3. Atualiza timestamp de última sincronização
  @override
  Future<int> syncFromServer() async {
    try {
      if (kDebugMode) {
        print(
          '[CategoriesRepository] ========== INICIANDO SINCRONIZAÇÃO ==========',
        );
      }

      // ===== FASE 1: PUSH (Enviar mudanças locais) =====
      if (kDebugMode) {
        print(
          '[CategoriesRepository] FASE 1: Enviando mudanças locais para servidor',
        );
      }

      final localCategories = await _localDao.listAll();
      if (localCategories.isNotEmpty) {
        if (kDebugMode) {
          print(
            '[CategoriesRepository] Enviando ${localCategories.length} categorias locais',
          );
        }

        await _remoteApi.upsertCategories(localCategories);

        if (kDebugMode) {
          print('[CategoriesRepository] Push concluído com sucesso');
        }
      } else {
        if (kDebugMode) {
          print('[CategoriesRepository] Nenhuma categoria local para enviar');
        }
      }

      // ===== FASE 2: PULL (Buscar atualizações do servidor) =====
      if (kDebugMode) {
        print(
          '[CategoriesRepository] FASE 2: Buscando atualizações do servidor',
        );
      }

      // Busca timestamp da última sincronização para sync incremental
      final lastSync = await _localDao.getLastSync();
      if (kDebugMode) {
        if (lastSync != null) {
          print('[CategoriesRepository] Última sincronização: $lastSync');
          print('[CategoriesRepository] Modo: Sincronização incremental');
        } else {
          print('[CategoriesRepository] Primeira sincronização (full sync)');
        }
      }

      // Busca todas as páginas do servidor
      final allRemoteCategories = <CategoryDto>[];
      PageCursor? cursor;
      int pageCount = 0;

      do {
        pageCount++;
        if (kDebugMode) {
          print('[CategoriesRepository] Buscando página $pageCount...');
        }

        final page = await _remoteApi.fetchCategories(
          cursor: cursor,
          since: lastSync,
        );

        allRemoteCategories.addAll(page.data);
        cursor = page.nextCursor;

        if (kDebugMode) {
          print(
            '[CategoriesRepository] Página $pageCount: ${page.data.length} categorias',
          );
        }
      } while (cursor != null);

      if (kDebugMode) {
        print(
          '[CategoriesRepository] Total de categorias remotas: ${allRemoteCategories.length}',
        );
      }

      // Atualiza cache local com dados do servidor
      if (allRemoteCategories.isNotEmpty) {
        // Em sync incremental, precisamos mesclar com dados locais
        if (lastSync != null) {
          if (kDebugMode) {
            print(
              '[CategoriesRepository] Mesclando dados remotos com cache local',
            );
          }

          final localDtos = await _localDao.listAll();
          final localMap = {for (var dto in localDtos) dto.id: dto};

          // Atualiza o map com dados remotos (sobrescreve se existir)
          for (var remoteDto in allRemoteCategories) {
            localMap[remoteDto.id] = remoteDto;
          }

          await _localDao.upsertAll(localMap.values.toList());
        } else {
          // Full sync: substitui todo o cache
          if (kDebugMode) {
            print(
              '[CategoriesRepository] Substituindo cache local completamente',
            );
          }
          await _localDao.upsertAll(allRemoteCategories);
        }
      }

      // ===== FASE 3: Atualizar timestamp =====
      final now = DateTime.now();
      await _localDao.setLastSync(now);

      if (kDebugMode) {
        print(
          '[CategoriesRepository] Timestamp de sincronização atualizado: $now',
        );
        print(
          '[CategoriesRepository] ========== SINCRONIZAÇÃO CONCLUÍDA ==========',
        );
      }

      return allRemoteCategories.length;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro na sincronização: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Limpa todo o cache local de categorias
  @override
  Future<void> clearAllCategories() async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Limpando cache local de categorias');
      }

      await _localDao.clear();

      if (kDebugMode) {
        print('[CategoriesRepository] Cache local limpo com sucesso');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro ao limpar cache: $e');
        print(stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> forceSyncAll() async {
    try {
      if (kDebugMode) {
        print('[CategoriesRepository] Forçando full sync');
      }

      // Limpa marcador de última sync para forçar full sync
      await _localDao.setLastSync(DateTime(1970, 1, 1));

      // Executa sync (que agora será full sync)
      final synced = await syncFromServer();

      if (kDebugMode) {
        print('[CategoriesRepository] Full sync concluído: $synced categorias');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CategoriesRepository] Erro no full sync: $e');
        print(stack);
      }
      rethrow;
    }
  }
}
