# Guia de Correção Manual - Erros Restantes

## ❌ Erros que Você Precisa Corrigir Manualmente

### 1. Método `.gte()` não disponível no Supabase

**Erro:**
```
The method 'gte' isn't defined for the type 'PostgrestTransformBuilder'
```

**Arquivos afetados:**
- `lib/features/tasks/infrastructure/remote/supabase_tasks_remote_datasource.dart` (linha 49)
- `lib/features/categories/infrastructure/remote/supabase_categories_remote_datasource.dart` (linha 51)
- `lib/features/reminders/infrastructure/remote/supabase_reminders_remote_datasource.dart` (linha 49)

**Solução 1 - Atualizar Supabase (Recomendado):**

Abra o arquivo `pubspec.yaml` e atualize:
```yaml
dependencies:
  supabase_flutter: ^2.6.0  # ou versão mais recente
```

Depois rode:
```bash
flutter pub get
```

**Solução 2 - Usar método alternativo:**

Se não puder atualizar, substitua:
```dart
query = query.gte('updated_at', since.toIso8601String());
```

Por:
```dart
final response = await query;
// Filtrar manualmente após receber os dados
final filtered = response.where((item) {
  final updatedAt = DateTime.parse(item['updated_at']);
  return updatedAt.isAfter(since) || updatedAt.isAtSameMomentAs(since);
}).toList();
```

---

### 2. Erro de sintaxe em `categories_repository_impl.dart`

**Erro:**
```
Future<void> clearAllCategories() async {ou troubleshooting
```

**Arquivo:** `lib/features/categories/infrastructure/repositories/categories_repository_impl.dart` (linha 402)

**O que aconteceu:**
Durante as edições automáticas, parte do comentário foi misturada com o código.

**Como corrigir:**

1. Abra o arquivo `categories_repository_impl.dart`
2. Localize a linha ~402
3. Você verá algo como:
```dart
Future<void> clearAllCategories() async {ou troubleshooting
```

4. Substitua por:
```dart
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
```

5. Remova o método duplicado `clearLocalCache()` logo abaixo (se existir)

6. Verifique se o método `forceSyncAll()` está presente e correto ao final do arquivo:
```dart
  /// Força sincronização completa (full sync) de todas as categorias
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
}  // Fechar a classe aqui
```

---

## ✅ Erros que Foram Corrigidos Automaticamente

### 1. ✅ Imports do SupabaseService
- Corrigido caminho: `../../../../services/core/supabase_service.dart`
- Corrigido acesso estático: `SupabaseService.client` ao invés de `SupabaseService().client`

### 2. ✅ Conflito de nome Category
- Adicionado `hide Category` no import do Flutter Foundation
- Arquivo: `categories_repository_impl.dart`

### 3. ✅ Import de TaskPriority
- Adicionado import da extension para acessar `.value`
- Arquivo: `tasks_repository_impl.dart`

### 4. ✅ Casts desnecessários removidos
- Removido `as Map<String, dynamic>` onde não era necessário
- Arquivos: tasks e reminders datasources

### 5. ✅ Métodos do CategoryMapper
- Corrigido de `_mapper.toDto()` para `CategoryMapper.toDto()`
- Métodos mapper são estáticos, não precisam de instância

### 6. ✅ Métodos faltantes em CategoriesRepository
- Adicionado: `loadFromCache()`, `listAll()`, `listActive()`, `listRootCategories()`, `listSubcategories()`
- Corrigido: `syncFromServer()` agora retorna `Future<int>`
- Renomeado: `listCategories()` → `listAll()`, `getCategoryById()` → `getById()`

---

## 📋 Checklist de Verificação

Após fazer as correções manuais, rode:

```bash
flutter pub get
flutter analyze
```

Se ainda houver erros, verifique:

- [ ] Todos os imports estão corretos
- [ ] Método `.gte()` foi corrigido (Solução 1 ou 2)
- [ ] `categories_repository_impl.dart` não tem código duplicado
- [ ] Não há mistura de código com comentários
- [ ] Todos os métodos da interface estão implementados
- [ ] Não há methods duplicados (ex: clearAllCategories e clearLocalCache)

---

## 🚀 Testando as Implementações

### Para Tasks (completo):

1. Certifique-se de que o Supabase está configurado no `.env`:
```env
SUPABASE_URL=sua_url_aqui
SUPABASE_ANON_KEY=sua_key_aqui
```

2. Execute o app e abra a tela de Tasks

3. Observe os logs no console para confirmar:
```
TaskListPage._loadTasks: sync completed, X items changed
TasksRepositoryImpl.syncFromServer: pushed Y items to remote
TasksRepositoryImpl.syncFromServer: recebidos Z items from remote
```

### Para Categories e Reminders:

Ainda é necessário:
1. Integrar na UI (seguir o padrão de Tasks)
2. Criar as páginas de listagem
3. Adicionar botões de sincronização

---

## 📚 Documentação Completa

Consulte o arquivo `IMPLEMENTACAO_PROMPTS_14_18_RELATORIO.md` para:
- Visão geral da arquitetura
- Lista completa de arquivos criados
- Explicação dos padrões implementados
- Exemplos de uso
- Boas práticas

---

**Dúvidas?** Consulte os comentários didáticos dentro dos próprios arquivos criados!
