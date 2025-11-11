# Script de Commits e Merge - TaskFlow

## Status Atual
- Branch atual: feature/category-filters
- Contém: Feature 2 (Categorização) + Feature 3 (Lembretes)
- Precisa: Separar em branches e fazer merges organizados

---

## Plano de Ação

### Opção A: Commits Diretos (Mais Simples)
Fazer commits na branch atual e merge direto para main.

### Opção B: Branches Separadas (Mais Organizada)
Criar branches específicas para cada feature.

**VAMOS USAR: Opção A (Mais Simples)**

---

## Comandos Git - Opção A

### 1. Verificar status atual
```bash
cd "c:\Users\Muril\Downloads\Trabalho OO\TaskFlow\taskflow_app"
git status
git branch
```

### 2. Adicionar arquivos de prompts
```bash
git add Prompts/06_category_system_prompt.md
git add Prompts/07_reminder_system_prompt.md
git commit -m "docs: adiciona prompts das features 2 e 3"
```

### 3. Adicionar documentação atualizada
```bash
git add docs/apresentacao.md
git commit -m "docs: documenta features de categorização e notificações"
```

### 4. Verificar se há mudanças não commitadas
```bash
git status
```

### 5. Se houver mudanças, adicionar
```bash
# Ver o que mudou
git diff

# Adicionar tudo (se estiver OK)
git add .
git commit -m "feat: finaliza features de categorização e notificações"
```

### 6. Fazer merge para main
```bash
# Ir para main
git checkout main

# Verificar se está atualizado
git pull origin main

# Fazer merge
git merge feature/category-filters --no-ff -m "merge: categorização e notificações implementadas"

# Push para repositório
git push origin main
```

### 7. Deletar branch antiga (opcional)
```bash
# Local
git branch -d feature/category-filters

# Remoto
git push origin --delete feature/category-filters
```

---

## Comandos Git - Opção B (Alternativa)

Se preferir branches separadas:

### 1. Criar branch para Feature 2
```bash
git checkout -b feature/categorizacao
git add lib/services/core/category_service.dart
git add lib/services/core/task_filter_service.dart
git add lib/features/categories/
git commit -m "feat: sistema de categorização implementado"
```

### 2. Criar branch para Feature 3
```bash
git checkout -b feature/notificacoes
git add lib/services/notifications/
git add lib/services/core/reminder_service.dart
git add lib/features/reminders/
git commit -m "feat: sistema de notificações implementado"
```

### 3. Merge Feature 2
```bash
git checkout main
git merge feature/categorizacao --no-ff -m "merge: categorização implementada"
```

### 4. Merge Feature 3
```bash
git merge feature/notificacoes --no-ff -m "merge: notificações implementadas"
```

---

## Resumo dos Commits Necessários

1. ✅ `docs: adiciona prompts das features 2 e 3`
2. ✅ `docs: documenta features de categorização e notificações`
3. ✅ `feat: finaliza features de categorização e notificações`
4. ✅ `merge: categorização e notificações implementadas`

---

## Verificação Final

Após merge, verificar:
```bash
git log --oneline -10
git branch
flutter clean
flutter pub get
flutter run
```

---

## Em caso de conflitos

Se houver conflitos durante o merge:

1. Ver arquivos em conflito:
```bash
git status
```

2. Resolver manualmente cada arquivo

3. Adicionar arquivos resolvidos:
```bash
git add <arquivo>
```

4. Continuar merge:
```bash
git commit
```

---

## Backup antes do merge

```bash
# Criar backup da branch
git branch backup-category-filters

# Se algo der errado:
git reset --hard backup-category-filters
```
