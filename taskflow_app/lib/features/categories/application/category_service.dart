import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import '../../app/domain/entities/category.dart';
import '../../app/infrastructure/local/category_local_dto_shared_prefs.dart';
import '../../app/infrastructure/mappers/category_mapper.dart';
import '../infrastructure/remote/supabase_categories_remote_datasource.dart';
import '../../../services/core/supabase_service.dart';

/// CategoryService - Gerencia categorias do sistema
///
/// Responsabilidades:
/// - CRUD de categorias
/// - Hierarquia de categorias (parent/child)
/// - Persistência local usando CategoryLocalDto
/// - Notificação de mudanças para UI
class CategoryService extends ChangeNotifier {
  final CategoryLocalDtoSharedPrefs _localDao;
  SupabaseCategoriesRemoteDatasource? _remoteApi;

  final List<Category> _categories = [];
  bool _isInitialized = false;

  CategoryService(this._localDao) {
    try {
      _remoteApi = SupabaseCategoriesRemoteDatasource(SupabaseService.client);
      if (kDebugMode) {
        print('✅ CategoryService: Remote datasource inicializado com sucesso');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ CategoryService: Erro ao inicializar Supabase - modo offline');
        print('   Erro: $e');
        print('   Stack: $stack');
      }
      _remoteApi = null;
    }
    _initializeCategories();
  }

  /// Retorna o userId do usuário autenticado ou um UUID fixo para modo local
  String get _userId {
    // Tenta obter o userId do Supabase
    final supabaseUserId = SupabaseService.currentUserId;
    if (supabaseUserId != null) {
      return supabaseUserId;
    }
    // UUID fixo para modo local (compatível com PostgreSQL)
    return '00000000-0000-0000-0000-000000000000';
  }

  /// Inicializa o serviço carregando categorias do cache local
  Future<void> _initializeCategories() async {
    if (_isInitialized) return;

    try {
      print('🏷️ Inicializando CategoryService...');

      // Carrega do cache local primeiro
      final dtos = await _localDao.listAll();
      _categories.clear();

      for (final dto in dtos) {
        _categories.add(CategoryMapper.toEntity(dto));
      }

      print(
        '📋 CategoryService inicializado com ${_categories.length} categorias do cache',
      );
      _isInitialized = true;
      notifyListeners();

      // Sincroniza com Supabase se não for modo convidado
      if (_userId != '00000000-0000-0000-0000-000000000000') {
        print('🔄 Sincronizando categorias com Supabase...');
        await _syncFromSupabase();
        print('✅ Sincronização completa: ${_categories.length} categorias');
      } else {
        print('👤 Modo convidado detectado');
        // Se não houver categorias no modo convidado, criar localmente
        if (_categories.isEmpty) {
          print('🎨 Criando categorias padrão para modo convidado');
          await _createDefaultCategories();
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ Erro ao inicializar CategoryService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sincroniza categorias do Supabase para o cache local
  Future<void> _syncFromSupabase() async {
    if (_remoteApi == null) {
      print('⚠️ Remote API não disponível');
      return;
    }

    try {
      // Busca todas as categorias do usuário no Supabase
      final remotePage = await _remoteApi!.fetchCategories();
      final remoteDtos = remotePage.data;
      
      print('📥 Recebidas ${remoteDtos.length} categorias do Supabase');

      // Atualiza o cache local com dados do servidor (usa upsertAll)
      if (remoteDtos.isNotEmpty) {
        await _localDao.upsertAll(remoteDtos);
      }

      // Recarrega as categorias do cache atualizado
      final dtos = await _localDao.listAll();
      _categories.clear();
      for (final dto in dtos) {
        _categories.add(CategoryMapper.toEntity(dto));
      }

      notifyListeners();
    } catch (e) {
      print('❌ Erro ao sincronizar com Supabase: $e');
    }
  }

  /// Cria categorias padrão na primeira utilização
  Future<void> _createDefaultCategories() async {
    print('🎨 Criando categorias padrão...');

    final defaultCategories = [
      Category(
        id: 'cat-work',
        name: 'Trabalho',
        color: '#2196F3',
        icon: 'work',
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-personal',
        name: 'Pessoal',
        color: '#4CAF50',
        icon: 'person',
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-study',
        name: 'Estudos',
        color: '#FF9800',
        icon: 'school',
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-health',
        name: 'Saúde',
        color: '#E91E63',
        icon: 'favorite',
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-home',
        name: 'Casa',
        color: '#FF9800',
        icon: 'home',
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final category in defaultCategories) {
      await addCategory(category);
    }

    print('✅ ${defaultCategories.length} categorias padrão criadas');
  }

  /// Retorna todas as categorias
  List<Category> get categories => List.unmodifiable(_categories);

  /// Retorna apenas categorias raiz (sem parent)
  List<Category> get rootCategories {
    return _categories.where((cat) => cat.parentId == null).toList();
  }

  /// Retorna subcategorias de uma categoria pai
  List<Category> getSubcategories(String parentId) {
    return _categories.where((cat) => cat.parentId == parentId).toList();
  }

  /// Busca categoria por ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Adiciona nova categoria
  Future<void> addCategory(Category category) async {
    try {
      print('➕ Adicionando categoria: ${category.name}');

      // Adiciona à lista local
      _categories.add(category);
      notifyListeners();

      // Persiste no cache local
      final allDtos = _categories.map((c) => CategoryMapper.toDto(c)).toList();
      await _localDao.upsertAll(allDtos);

      print('✅ Categoria adicionada ao cache local');

      // Tenta sincronizar com Supabase
      if (_remoteApi != null) {
        try {
          if (kDebugMode) print('📤 Sincronizando categoria com Supabase...');
          final dto = CategoryMapper.toDto(category);
          if (kDebugMode) print('   DTO: ${dto.toMap()}');
          
          // Verifica se não é modo convidado
          final currentUserId = SupabaseService.currentUserId;
          if (currentUserId != null && 
              currentUserId != '00000000-0000-0000-0000-000000000000') {
            await _remoteApi!.upsertCategories([dto]);
            if (kDebugMode) print('✅ Categoria sincronizada com Supabase');
          } else {
            if (kDebugMode) print('⚠️ Modo convidado - categoria não sincronizada');
          }
        } catch (syncError, stack) {
          if (kDebugMode) {
            print('❌ Erro ao sincronizar com Supabase:');
            print('   $syncError');
            print('   Stack: $stack');
          }
        }
      } else {
        if (kDebugMode) print('⚠️ Modo offline - categoria não sincronizada');
      }
    } catch (e) {
      print('❌ Erro ao adicionar categoria: $e');
      _categories.removeWhere((c) => c.id == category.id);
      notifyListeners();
      rethrow;
    }
  }

  /// Atualiza categoria existente
  Future<void> updateCategory(Category updatedCategory) async {
    try {
      print('✏️ Atualizando categoria: ${updatedCategory.name}');

      final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
      if (index == -1) {
        throw Exception('Categoria não encontrada');
      }

      // Atualiza na lista local
      _categories[index] = updatedCategory;
      notifyListeners();

      // Persiste no cache local
      final allDtos = _categories.map((c) => CategoryMapper.toDto(c)).toList();
      await _localDao.upsertAll(allDtos);

      print('✅ Categoria atualizada no cache local');

      // Tenta sincronizar com Supabase
      if (_remoteApi != null) {
        try {
          if (kDebugMode) print('📤 Sincronizando categoria atualizada com Supabase...');
          final dto = CategoryMapper.toDto(updatedCategory);
          
          // Verifica se não é modo convidado
          final currentUserId = SupabaseService.currentUserId;
          if (currentUserId != null && 
              currentUserId != '00000000-0000-0000-0000-000000000000') {
            await _remoteApi!.upsertCategories([dto]);
            if (kDebugMode) print('✅ Categoria atualizada sincronizada com Supabase');
          } else {
            if (kDebugMode) print('⚠️ Modo convidado - categoria não sincronizada');
          }
        } catch (syncError, stack) {
          if (kDebugMode) {
            print('❌ Erro ao sincronizar com Supabase:');
            print('   $syncError');
            print('   Stack: $stack');
          }
        }
      } else {
        if (kDebugMode) print('⚠️ Modo offline - categoria não sincronizada');
      }
    } catch (e) {
      print('❌ Erro ao atualizar categoria: $e');
      await _refreshCategories();
      rethrow;
    }
  }

  /// Remove categoria
  Future<void> deleteCategory(String categoryId) async {
    try {
      print('🗑️ Removendo categoria: $categoryId');

      // Remove da lista local
      _categories.removeWhere((c) => c.id == categoryId);

      // Persiste a remoção no cache local
      await _localDao.delete(categoryId);

      notifyListeners();

      print('✅ Categoria removida com sucesso');
    } catch (e) {
      print('❌ Erro ao remover categoria: $e');
      await _refreshCategories();
      rethrow;
    }
  }

  /// Recarrega categorias do cache local
  Future<void> _refreshCategories() async {
    try {
      final dtos = await _localDao.listAll();
      _categories.clear();

      for (final dto in dtos) {
        _categories.add(CategoryMapper.toEntity(dto));
      }

      notifyListeners();
    } catch (e) {
      print('❌ Erro ao recarregar categorias: $e');
    }
  }

  /// Limpa todas as categorias (usado no logout)
  Future<void> clearAllCategories() async {
    try {
      print('🧹 Limpando todas as categorias do cache...');
      
      _categories.clear();
      await _localDao.clear();
      
      // NÃO marca como não inicializado aqui
      // O reinitialize() logo após o login cuidará disso
      
      notifyListeners();
      print('✅ Cache de categorias limpo');
    } catch (e) {
      print('❌ Erro ao limpar categorias: $e');
    }
  }

  /// Reinicializa o serviço (usado após login/logout)
  Future<void> reinitialize() async {
    print('🔄 Reinicializando CategoryService...');
    print('   Estado atual: _isInitialized = $_isInitialized, categorias = ${_categories.length}');
    
    // Limpa TUDO: memória E cache local
    _categories.clear();
    await _localDao.clear();
    
    // Marca como não inicializado e reinicializa
    _isInitialized = false;
    await _initializeCategories();
  }
}
