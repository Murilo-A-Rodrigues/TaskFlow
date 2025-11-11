import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import '../../features/app/domain/entities/category.dart';
import '../../features/app/infrastructure/local/category_local_dto_shared_prefs.dart';
import '../../features/app/infrastructure/mappers/category_mapper.dart';

/// CategoryService - Gerencia categorias do sistema
/// 
/// Responsabilidades:
/// - CRUD de categorias
/// - Hierarquia de categorias (parent/child)
/// - Persistência local usando CategoryLocalDto
/// - Notificação de mudanças para UI
class CategoryService extends ChangeNotifier {
  final CategoryLocalDtoSharedPrefs _localDao;
  
  final List<Category> _categories = [];
  bool _isInitialized = false;

  CategoryService(this._localDao) {
    _initializeCategories();
  }

  /// Inicializa o serviço carregando categorias do cache local
  Future<void> _initializeCategories() async {
    if (_isInitialized) return;

    try {
      print('🏷️ Inicializando CategoryService...');
      
      final dtos = await _localDao.listAll();
      _categories.clear();
      
      for (final dto in dtos) {
        _categories.add(CategoryMapper.toEntity(dto));
      }
      
      print('📋 CategoryService inicializado com ${_categories.length} categorias');
      _isInitialized = true;
      
      // Se não houver categorias, criar categorias padrão
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao inicializar CategoryService: $e');
      _isInitialized = true;
      notifyListeners();
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
        userId: 'local-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-personal',
        name: 'Pessoal',
        color: '#4CAF50',
        icon: 'person',
        userId: 'local-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-study',
        name: 'Estudos',
        color: '#9C27B0',
        icon: 'school',
        userId: 'local-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-health',
        name: 'Saúde',
        color: '#F44336',
        icon: 'favorite',
        userId: 'local-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cat-home',
        name: 'Casa',
        color: '#FF9800',
        icon: 'home',
        userId: 'local-user',
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
      
      print('✅ Categoria adicionada com sucesso');
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
      
      print('✅ Categoria atualizada com sucesso');
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
      notifyListeners();
      
      // Persiste no cache local
      final allDtos = _categories.map((c) => CategoryMapper.toDto(c)).toList();
      await _localDao.upsertAll(allDtos);
      
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

  /// Limpa todas as categorias (para testes)
  Future<void> clearAllCategories() async {
    try {
      print('🧹 Limpando todas as categorias...');
      
      _categories.clear();
      await _localDao.clear();
      notifyListeners();
      
      print('✅ Categorias limpas com sucesso');
    } catch (e) {
      print('❌ Erro ao limpar categorias: $e');
    }
  }
}
