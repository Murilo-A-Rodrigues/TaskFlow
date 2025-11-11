# Prompt 06 - Sistema de Categorização e Filtros

## Contexto

Necessidade de implementar um sistema completo de categorização de tarefas com filtros avançados para melhorar a organização e produtividade dos usuários.

## Objetivo

Criar um sistema que permita:
- Criar categorias personalizadas com cores e ícones
- Atribuir categorias às tarefas
- Filtrar tarefas por múltiplos critérios
- Visualizar filtros ativos

## Prompt Usado

```
Crie um serviço CategoryService que gerencie categorias de tarefas com as seguintes características:

1. Use ChangeNotifier para reatividade
2. Persista em SharedPreferences com chave 'categories_v1'
3. Cada categoria deve ter:
   - id (String, UUID)
   - name (String)
   - color (Color, hex)
   - icon (IconData)
   - createdAt (DateTime)

4. Implemente métodos CRUD completos:
   - createCategory(name, color, icon)
   - updateCategory(id, name, color, icon)
   - deleteCategory(id)
   - getCategoryById(id)
   - getAllCategories()

5. Adicione validações:
   - Nome não pode ser vazio
   - Cores devem ser válidas
   - Máximo 50 caracteres no nome

6. Tratamento de erros:
   - Try-catch em todas as operações
   - Logs detalhados para debugging

7. Serialização JSON para persistência
```

## Resposta da IA

A IA gerou a estrutura completa do CategoryService com todos os métodos solicitados, incluindo:
- Classe com ChangeNotifier
- Métodos CRUD completos
- Persistência em SharedPreferences
- Validações básicas
- Logs coloridos

## Iterações

### Iteração 1: Estrutura Básica
**Problema:** Código inicial não tinha persistência
**Refinamento:** "Adicione persistência em SharedPreferences"
**Resultado:** Métodos _saveToCache() e _loadFromCache() implementados

### Iteração 2: Validações
**Problema:** Não validava nome vazio
**Refinamento:** "Adicione validação para nome vazio com throw ArgumentError"
**Resultado:** Validação implementada com exceção customizada

### Iteração 3: Tratamento de Erros
**Problema:** Sem try-catch
**Refinamento:** "Envolva operações críticas em try-catch e logue erros"
**Resultado:** Todos os métodos com tratamento de exceções

### Iteração 4: TaskFilterService
**Prompt adicional:**
```
Crie um TaskFilterService que:
1. Gerencie filtros ativos em um Map<String, dynamic>
2. Suporte 4 tipos de filtro: category, status, priority, date
3. Método getFilteredTasks() que aplique todos os filtros sequencialmente
4. Persista filtros ativos em SharedPreferences
5. Métodos: applyFilter, removeFilter, clearFilters, hasActiveFilters
```

**Resultado:** Serviço completo com composição de filtros

## Código Gerado

### CategoryService (trecho principal)

```dart
Future<Category> createCategory({
  required String name,
  required Color color,
  IconData icon = Icons.label,
}) async {
  if (name.trim().isEmpty) {
    throw ArgumentError('Nome da categoria não pode ser vazio');
  }

  final category = Category(
    id: const Uuid().v4(),
    name: name.trim(),
    color: color,
    icon: icon,
    createdAt: DateTime.now(),
  );

  _categories.add(category);
  await _saveToCache();
  notifyListeners();
  
  print('✅ Categoria criada: ${category.name}');
  return category;
}
```

### TaskFilterService (trecho principal)

```dart
List<Task> getFilteredTasks(List<Task> tasks) {
  if (!hasActiveFilters) return tasks;
  
  var filtered = List<Task>.from(tasks);
  
  // Aplica cada filtro sequencialmente
  if (_activeFilters.containsKey(FilterType.category.toString())) {
    final categoryId = _activeFilters[FilterType.category.toString()];
    filtered = filtered.where((task) => 
      task.categoryId == categoryId
    ).toList();
  }
  
  // Outros filtros...
  
  return filtered;
}
```

## Validações Realizadas

- [x] Testado criar categoria com nome vazio (lança exceção)
- [x] Testado criar 10+ categorias (persistência funciona)
- [x] Testado reiniciar app (categorias carregam)
- [x] Testado aplicar múltiplos filtros (composição funciona)
- [x] Testado limpar filtros (volta ao normal)
- [x] Testado deletar categoria (remove da lista e cache)

## Decisões de Design

1. **Separação de serviços:** CategoryService e TaskFilterService separados para SRP
2. **Map para filtros:** Permite múltiplos filtros simultâneos
3. **Filtros locais:** Aplicados em memória, não no servidor (performance)
4. **Persistência de filtros:** Mantém estado entre sessões

## Limitações Conhecidas

- SharedPreferences tem limite de ~1MB (máx 50 categorias)
- Filtros não sincronizam entre dispositivos
- Ícones limitados ao Material Icons

## Melhorias Futuras

- Upload de imagens customizadas para categorias
- Sincronização de filtros via Supabase
- Filtros salvos (presets)
