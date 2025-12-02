import '../../../app/domain/entities/category.dart';

/// Interface de repositório para a entidade Category.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade Category possui métodos de conversão robustos
/// - Adicione prints/logs (usando kDebugMode) nos métodos principais
/// - Sempre verifique se o widget está "mounted" antes de chamar setState
/// - Consulte os arquivos de debug do projeto para exemplos
abstract class CategoriesRepository {
  /// Carrega categorias do cache local para renderização rápida inicial
  Future<List<Category>> loadFromCache();

  /// Sincronização incremental com o servidor
  /// Retorna a quantidade de registros alterados
  Future<int> syncFromServer();

  /// Lista todas as categorias (do cache após sincronização)
  Future<List<Category>> listAll();

  /// Lista categorias ativas (filtradas do cache)
  Future<List<Category>> listActive();

  /// Lista categorias raiz (sem parent_id)
  Future<List<Category>> listRootCategories();

  /// Lista subcategorias de uma categoria pai
  Future<List<Category>> listSubcategories(String parentId);

  /// Busca uma categoria específica por ID no cache local
  Future<Category?> getById(String id);

  /// Cria uma nova categoria localmente e opcionalmente a envia ao servidor
  Future<Category> createCategory(Category category);

  /// Atualiza uma categoria existente
  Future<Category> updateCategory(Category category);

  /// Remove uma categoria por ID
  Future<void> deleteCategory(String categoryId);

  /// Limpa todo o cache local de categorias
  Future<void> clearAllCategories();

  /// Força sincronização completa de todas as categorias
  Future<void> forceSyncAll();
}
