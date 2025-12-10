# 🗑️ SOFT DELETE IMPLEMENTATION - TASKFLOW

## 📋 Resumo

O sistema de **soft delete** foi implementado com sucesso para prevenir perda acidental de dados. Ao invés de remover registros do banco de dados permanentemente, o sistema agora marca itens como "deletados" com um timestamp, permitindo:

- ✅ Recuperação de dados deletados acidentalmente (funcionalidade futura)
- ✅ Auditoria completa das exclusões
- ✅ Sincronização correta entre dispositivos
- ✅ Manutenção da integridade referencial

---

## 🏗️ Arquitetura Implementada

### 1️⃣ Domain Layer (Entities)

**Task Entity** (`lib/features/tasks/domain/entities/task.dart`)
```dart
class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final bool isDeleted;        // ✅ NOVO
  final DateTime? deletedAt;   // ✅ NOVO
  // ... outros campos
}
```

**Category Entity** (`lib/features/app/domain/entities/category.dart`)
```dart
class Category {
  final String id;
  final String name;
  final bool isActive;
  final bool isDeleted;        // ✅ NOVO
  final DateTime? deletedAt;   // ✅ NOVO
  // ... outros campos
}
```

### 2️⃣ Infrastructure Layer (DTOs)

**TaskDto** (`lib/features/tasks/infrastructure/dtos/task_dto.dart`)
```dart
class TaskDto {
  final String id;
  final String title;
  final bool is_completed;
  final bool is_deleted;       // ✅ NOVO (snake_case para DB)
  final String? deleted_at;    // ✅ NOVO (ISO8601 string)
  // ... outros campos
}
```

**CategoryDto** (`lib/features/app/infrastructure/dtos/category_dto.dart`)
```dart
class CategoryDto {
  final String id;
  final String name;
  final bool is_active;
  final bool is_deleted;       // ✅ NOVO (snake_case para DB)
  final String? deleted_at;    // ✅ NOVO (ISO8601 string)
  // ... outros campos
}
```

### 3️⃣ Mappers

**TaskMapper** e **CategoryMapper** foram atualizados para converter entre:
- Entity: `isDeleted: bool`, `deletedAt: DateTime?`
- DTO: `is_deleted: bool`, `deleted_at: String?` (ISO8601)

**Conversão de Data:**
```dart
// Entity → DTO
deleted_at: entity.deletedAt?.toIso8601String()

// DTO → Entity
deletedAt: dto.deleted_at != null 
    ? DateTime.tryParse(dto.deleted_at!) 
    : null
```

### 4️⃣ Repository Implementation

#### TasksRepositoryImpl

**Método deleteTask():**
```dart
Future<void> deleteTask(String taskId) async {
  // 1. Busca a task atual
  final tasks = await localDao.getAll();
  final taskDto = tasks.firstWhere((t) => t.id == taskId);
  
  // 2. Marca como deletada com timestamp
  final deletedTask = taskDto.copyWith(
    is_deleted: true,
    deleted_at: DateTime.now().toIso8601String(),
    updated_at: DateTime.now().toIso8601String(),
  );
  
  // 3. Atualiza no cache local
  await localDao.upsert(deletedTask);
  
  // 4. Sincroniza com servidor
  await remoteApi.upsert(deletedTask);
}
```

**Filtragem de itens deletados:**
```dart
Future<List<Task>> loadFromCache() async {
  final dtos = await localDao.listAll();
  final entities = dtos
      .where((dto) => !dto.is_deleted)  // ✅ FILTRO
      .map((dto) => TaskMapper.toEntity(dto))
      .toList();
  return entities;
}
```

#### CategoriesRepositoryImpl

**Implementação idêntica:**
- `deleteCategory()`: marca como deletada ao invés de remover
- `loadFromCache()` e `listAll()`: filtram itens com `is_deleted = true`
- Sincronização completa com Supabase

---

## 🗄️ Database Schema

### Colunas Adicionadas

**Tabela `tasks`:**
```sql
is_deleted BOOLEAN NOT NULL DEFAULT false,
deleted_at TIMESTAMPTZ NULL
```

**Tabela `categories`:**
```sql
is_deleted BOOLEAN NOT NULL DEFAULT false,
deleted_at TIMESTAMPTZ NULL
```

### Índices de Performance

```sql
CREATE INDEX idx_tasks_is_deleted ON public.tasks(is_deleted);
CREATE INDEX idx_categories_is_deleted ON public.categories(is_deleted);
```

---

## 📦 Arquivos Modificados

### Entities
- ✅ `lib/features/tasks/domain/entities/task.dart`
- ✅ `lib/features/app/domain/entities/category.dart`

### DTOs
- ✅ `lib/features/tasks/infrastructure/dtos/task_dto.dart`
- ✅ `lib/features/app/infrastructure/dtos/category_dto.dart`

### Mappers
- ✅ `lib/features/tasks/infrastructure/mappers/task_mapper.dart`
- ✅ `lib/features/app/infrastructure/mappers/category_mapper.dart`

### Repositories
- ✅ `lib/features/tasks/infrastructure/repositories/tasks_repository_impl.dart`
- ✅ `lib/features/categories/infrastructure/repositories/categories_repository_impl.dart`

### Database
- ✅ `supabase_setup.sql` - Schema completo atualizado
- ✅ `supabase_soft_delete_migration.sql` - **NOVO**: Script de migração

---

## 🚀 Como Aplicar no Supabase

### Opção 1: Novo Banco de Dados
Execute o arquivo `supabase_setup.sql` completo.

### Opção 2: Banco Existente (Migração)
Execute o arquivo `supabase_soft_delete_migration.sql`:

1. Acesse o Supabase Dashboard
2. Vá em **SQL Editor**
3. Cole o conteúdo de `supabase_soft_delete_migration.sql`
4. Execute (Run)
5. Verifique os logs de confirmação

**O script de migração:**
- ✅ Verifica se as colunas já existem antes de criar
- ✅ Adiciona `is_deleted` e `deleted_at` com valores padrão seguros
- ✅ Cria índices para performance
- ✅ Não afeta dados existentes (todas as tarefas/categorias existentes ficam com `is_deleted = false`)

---

## ✅ Comportamento Atual

### Ao Deletar uma Task ou Category:

1. **Não remove** do banco de dados
2. **Marca** como deletada: `is_deleted = true`
3. **Registra** timestamp: `deleted_at = NOW()`
4. **Atualiza** o campo `updated_at`
5. **Sincroniza** com Supabase automaticamente

### Ao Listar Tasks ou Categories:

1. **Busca** todos os registros do cache
2. **Filtra** itens onde `is_deleted = false`
3. **Retorna** apenas itens ativos
4. **Interface** não mostra itens deletados

---

## 🔮 Funcionalidades Futuras (Não Implementadas)

### Restauração de Itens Deletados
```dart
Future<void> restoreTask(String taskId) async {
  final task = await getDeletedTask(taskId);
  final restoredTask = task.copyWith(
    is_deleted: false,
    deleted_at: null,
    updated_at: DateTime.now().toIso8601String(),
  );
  await localDao.upsert(restoredTask);
  await remoteApi.upsert(restoredTask);
}
```

### Hard Delete (Limpeza Permanente)
```dart
Future<void> permanentlyDeleteOldItems() async {
  // Deletar permanentemente itens marcados há mais de 30 dias
  final cutoffDate = DateTime.now().subtract(Duration(days: 30));
  final oldDeleted = await getDeletedItemsOlderThan(cutoffDate);
  
  for (var item in oldDeleted) {
    await localDao.delete(item.id);  // Remove do cache
    await remoteApi.delete(item.id); // Remove do servidor
  }
}
```

### Lixeira (Trash View)
- Tela mostrando itens deletados
- Opção de restaurar ou deletar permanentemente
- Filtro por data de exclusão

---

## 🧪 Como Testar

### Teste Manual:

1. **Deletar uma Task:**
   - Abra o app
   - Swipe para deletar uma task
   - ✅ Task desaparece da lista
   - ✅ No Supabase, task tem `is_deleted = true`

2. **Deletar uma Category:**
   - Vá em Gerenciamento de Categorias
   - Delete uma categoria
   - ✅ Categoria desaparece da lista
   - ✅ No Supabase, categoria tem `is_deleted = true`

3. **Sincronização:**
   - Delete itens no dispositivo A
   - Sincronize
   - Abra o app no dispositivo B
   - ✅ Itens deletados não aparecem no dispositivo B

### Verificar no Supabase:

```sql
-- Ver todas as tasks, incluindo deletadas
SELECT id, title, is_deleted, deleted_at, updated_at 
FROM tasks 
ORDER BY updated_at DESC;

-- Ver apenas tasks deletadas
SELECT id, title, deleted_at 
FROM tasks 
WHERE is_deleted = true;

-- Ver apenas tasks ativas
SELECT id, title 
FROM tasks 
WHERE is_deleted = false;
```

---

## 🔒 Row Level Security (RLS)

### Atualização Necessária nas Policies:

Se você usa RLS no Supabase, atualize as políticas para filtrar itens deletados:

```sql
-- Exemplo: Policy para SELECT de tasks
CREATE POLICY "Users can view their own active tasks" 
ON tasks FOR SELECT 
USING (
  auth.uid() = assigned_to 
  AND is_deleted = false  -- ✅ ADICIONAR
);

-- Exemplo: Policy para SELECT de categories
CREATE POLICY "Users can view their own active categories" 
ON categories FOR SELECT 
USING (
  auth.uid() = user_id 
  AND is_deleted = false  -- ✅ ADICIONAR
);
```

---

## 📊 Impacto na Performance

### Antes (Hard Delete):
- DELETE físico do registro
- Rápido, mas irreversível
- Sem histórico de exclusões

### Depois (Soft Delete):
- UPDATE com flag booleana
- Performance similar (UPDATE vs DELETE)
- Índice em `is_deleted` mantém queries rápidas
- Histórico completo mantido

### Consultas com Índice:
```sql
-- Query otimizada com índice
SELECT * FROM tasks WHERE is_deleted = false;

-- Usa idx_tasks_is_deleted para filtrar rapidamente
```

---

## ⚠️ Considerações Importantes

1. **Crescimento do Banco:**
   - Itens deletados ocupam espaço
   - Implementar limpeza periódica no futuro
   - Sugestão: Hard delete após 30-90 dias

2. **Unique Constraints:**
   - Se houver constraints UNIQUE, considerar:
   ```sql
   UNIQUE (user_id, name) WHERE is_deleted = false
   ```

3. **Cascata:**
   - ON DELETE CASCADE não afeta soft delete
   - Se deletar categoria, suas tasks permanecem
   - Implementar lógica de cascata no código se necessário

4. **Backup:**
   - Soft delete NÃO substitui backups
   - Manter estratégia de backup regular

---

## 📝 Conclusão

✅ **Soft delete implementado com sucesso!**

O sistema agora:
- Preserva dados deletados
- Sincroniza corretamente
- Filtra itens deletados da UI
- Mantém integridade dos dados
- Permite recuperação futura

**Próximos passos sugeridos:**
1. Executar migration no Supabase
2. Testar deleção em desenvolvimento
3. Implementar tela de lixeira (opcional)
4. Implementar restauração (opcional)
5. Configurar limpeza automática (opcional)
