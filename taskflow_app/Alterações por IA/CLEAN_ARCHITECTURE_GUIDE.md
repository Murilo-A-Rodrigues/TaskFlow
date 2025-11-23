# 🏗️ Clean Architecture - TaskFlow

## 📋 Visão Geral

Este projeto segue os princípios do **Clean Architecture** (Arquitetura Limpa) proposta por Robert C. Martin, organizando o código em camadas bem definidas com responsabilidades claras e separação de conceitos.

---

## 🎯 Princípios Fundamentais

### 1. **Separação de Responsabilidades**
Cada camada tem uma responsabilidade específica e bem definida.

### 2. **Independência de Frameworks**
A lógica de negócio não depende de frameworks externos.

### 3. **Testabilidade**
Código organizado para facilitar testes unitários e de integração.

### 4. **Independência de UI**
A interface pode ser alterada sem modificar a lógica de negócio.

### 5. **Independência de Banco de Dados**
A persistência pode ser trocada (SQLite, Supabase, Firebase) sem impactar o domínio.

---

## 📁 Estrutura de Pastas

```
lib/
├── features/                    # Organização por funcionalidades
│   ├── app/                     # Entidades e DTOs compartilhados
│   │   ├── domain/
│   │   │   ├── entities/       # Entidades do domínio (Task, Category, etc)
│   │   │   └── repositories/   # Interfaces dos repositórios
│   │   ├── infrastructure/
│   │   │   ├── dtos/          # Data Transfer Objects
│   │   │   ├── mappers/       # Conversores Entity ↔ DTO
│   │   │   └── repositories/  # Implementações dos repositórios
│   │   └── presentation/
│   │
│   ├── tasks/                   # Feature: Gerenciamento de Tarefas
│   │   ├── application/        # ⭐ Casos de uso e serviços
│   │   │   └── task_service.dart
│   │   ├── domain/             # ⭐ Regras de negócio específicas
│   │   ├── infrastructure/     # ⭐ Implementações técnicas
│   │   ├── pages/              # Telas/páginas
│   │   └── widgets/            # Componentes visuais
│   │
│   ├── categories/              # Feature: Categorias
│   │   ├── application/        # ⭐ Serviços de categorias
│   │   │   └── category_service.dart
│   │   ├── pages/
│   │   └── widgets/
│   │
│   ├── reminders/               # Feature: Lembretes
│   │   ├── application/        # ⭐ Serviços de lembretes
│   │   │   └── reminder_service.dart
│   │   ├── pages/
│   │   └── widgets/
│   │
│   └── ... (outras features)
│
├── services/                    # ⚠️ LEGACY - Será migrado
│   ├── core/                   # Serviços principais (mover para features/*/application)
│   ├── storage/                # Serviços de armazenamento
│   ├── notifications/          # Serviços de notificações
│   └── integrations/           # Integrações externas (Supabase, etc)
│
├── shared/                      # Código compartilhado entre features
│   ├── widgets/                # Widgets reutilizáveis
│   ├── utils/                  # Utilitários gerais
│   └── constants/              # Constantes globais
│
├── theme/                       # Tema e estilos da aplicação
└── main.dart                    # Entry point
```

---

## 🔄 Camadas do Clean Architecture

### 1️⃣ **Domain (Domínio)**
📍 Localização: `lib/features/app/domain/` e `lib/features/*/domain/`

**Responsabilidades:**
- Entidades de negócio (Task, Category, Reminder)
- Interfaces de repositórios
- Regras de negócio puras
- Value Objects
- Exceções de domínio

**Características:**
- ✅ Não depende de nada
- ✅ Código 100% Dart puro
- ✅ Sem imports do Flutter
- ✅ Altamente testável

**Exemplo:**
```dart
// lib/features/app/domain/entities/task.dart
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final TaskPriority priority;
  final String? categoryId;
  
  // Regras de negócio
  bool get isOverdue => dueDate != null && 
                        dueDate!.isBefore(DateTime.now()) && 
                        !isCompleted;
}
```

---

### 2️⃣ **Application (Aplicação)**
📍 Localização: `lib/features/*/application/`

**Responsabilidades:**
- Casos de uso (Use Cases)
- Serviços de aplicação
- Orquestração de operações
- Validações de aplicação
- Transformação de dados

**Características:**
- ✅ Depende apenas do Domain
- ✅ Implementa lógica de aplicação
- ✅ Coordena entre repositórios
- ✅ Usa ChangeNotifier para estado (Flutter)

**Exemplo:**
```dart
// lib/features/tasks/application/task_service.dart
class TaskService extends ChangeNotifier {
  final TaskRepository _repository;
  final CategoryService _categoryService;
  
  Future<void> createTask(Task task) async {
    // Validações de aplicação
    if (task.categoryId != null) {
      final category = _categoryService.getCategoryById(task.categoryId!);
      if (category == null) {
        throw InvalidCategoryException();
      }
    }
    
    // Delega para o repositório
    await _repository.createTask(task);
    notifyListeners();
  }
}
```

---

### 3️⃣ **Infrastructure (Infraestrutura)**
📍 Localização: `lib/features/app/infrastructure/` e `lib/features/*/infrastructure/`

**Responsabilidades:**
- Implementação de repositórios
- DTOs (Data Transfer Objects)
- Mappers (conversão Entity ↔ DTO)
- Acesso a APIs externas
- Acesso a banco de dados
- Cache e persistência

**Características:**
- ✅ Implementa interfaces do Domain
- ✅ Lida com tecnologias específicas
- ✅ Transforma dados externos em Entities
- ✅ Pode usar frameworks (Supabase, HTTP, etc)

**Exemplo:**
```dart
// lib/features/app/infrastructure/repositories/task_repository.dart
class TaskRepository implements ITaskRepository {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  
  @override
  Future<List<Task>> getAllTasks() async {
    // 1. Busca do cache local
    final cachedDtos = await _loadFromCache();
    
    // 2. Converte DTOs para Entities
    final tasks = cachedDtos.map((dto) => TaskMapper.toEntity(dto)).toList();
    
    // 3. Sincroniza com backend em background
    _syncInBackground();
    
    return tasks;
  }
}
```

---

### 4️⃣ **Presentation (Apresentação)**
📍 Localização: `lib/features/*/pages/` e `lib/features/*/widgets/`

**Responsabilidades:**
- Páginas (Screens)
- Widgets (Componentes visuais)
- Controllers de formulários
- Navegação
- Tratamento de eventos de UI

**Características:**
- ✅ Depende de Application e Domain
- ✅ Usa Provider/ChangeNotifier
- ✅ Código específico do Flutter
- ✅ Focado em UX/UI

**Exemplo:**
```dart
// lib/features/tasks/pages/task_list_page.dart
class TaskListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, taskService, child) {
        final tasks = taskService.tasks;
        
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskCard(task: tasks[index]);
          },
        );
      },
    );
  }
}
```

---

## 🔀 Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────┐
│                         PRESENTATION                         │
│  (UI Layer - Pages, Widgets, Screens)                       │
│  - TaskListPage                                             │
│  - TaskCard                                                 │
│  - TaskFormDialog                                           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ↓ Provider/ChangeNotifier
┌─────────────────────────────────────────────────────────────┐
│                        APPLICATION                           │
│  (Use Cases - Business Logic Orchestration)                 │
│  - TaskService                                              │
│  - CategoryService                                          │
│  - ReminderService                                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ↓ Interface
┌─────────────────────────────────────────────────────────────┐
│                          DOMAIN                              │
│  (Business Rules - Pure Dart)                               │
│  - Task Entity                                              │
│  - Category Entity                                          │
│  - ITaskRepository (interface)                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ↑ Implementation
┌─────────────────────────────────────────────────────────────┐
│                      INFRASTRUCTURE                          │
│  (Technical Details - External Services)                    │
│  - TaskRepository (implementação)                           │
│  - TaskDto, TaskMapper                                      │
│  - Supabase, SharedPreferences                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Organização por Feature

Cada feature é auto-contida e segue a mesma estrutura:

```
features/tasks/
├── application/
│   └── task_service.dart          # Casos de uso
├── domain/
│   └── task_rules.dart            # Regras específicas de tarefas
├── infrastructure/
│   └── task_cache.dart            # Implementações técnicas específicas
├── pages/
│   ├── task_list_page.dart        # Tela de listagem
│   └── add_edit_task_screen.dart  # Tela de edição
└── widgets/
    ├── task_card.dart             # Card de tarefa
    └── task_form_dialog.dart      # Formulário
```

---

## 🎯 Benefícios Alcançados

### ✅ Testabilidade
- Domain e Application testáveis sem UI
- Mocks fáceis de criar
- Testes isolados por camada

### ✅ Manutenibilidade
- Código organizado e fácil de encontrar
- Responsabilidades claras
- Mudanças localizadas

### ✅ Escalabilidade
- Novas features seguem o mesmo padrão
- Fácil adicionar novos casos de uso
- Não há acoplamento entre features

### ✅ Flexibilidade
- Trocar Supabase por Firebase? Apenas Infrastructure muda
- Trocar Flutter por outro UI? Domain permanece intacto
- Adicionar cache? Apenas Repository muda

---

## 🔧 Migração em Andamento

### ⚠️ Legacy (services/)
Serviços antigos em `lib/services/` serão migrados para suas respectivas features:

- `services/core/task_service.dart` → `features/tasks/application/task_service.dart`
- `services/core/category_service.dart` → `features/categories/application/category_service.dart`
- `services/core/reminder_service.dart` → `features/reminders/application/reminder_service.dart`

### ✅ Já Migrado
- `features/app/domain/` - Entidades principais
- `features/app/infrastructure/` - Repositórios, DTOs e Mappers

### 🔄 Próximos Passos
1. Mover serviços para application/
2. Criar interfaces no domain/
3. Separar lógica de negócio de orquestração
4. Adicionar testes unitários por camada

---

## 📚 Referências

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [DDD e Clean Architecture](https://khalilstemmler.com/articles/software-design-architecture/organizing-app-logic/)

---

## 🎨 Convenções do Projeto

### Nomenclatura
- **Entities**: Substantivos no singular (Task, Category)
- **Services**: Substantivo + "Service" (TaskService)
- **Repositories**: Substantivo + "Repository" (TaskRepository)
- **DTOs**: Substantivo + "Dto" (TaskDto)
- **Pages**: Descritivo + "Page" (TaskListPage)

### Imports
```dart
// 1. Flutter/Dart
import 'package:flutter/material.dart';

// 2. Pacotes externos
import 'package:provider/provider.dart';

// 3. Domain (sempre antes)
import '../../domain/entities/task.dart';

// 4. Application
import '../application/task_service.dart';

// 5. Infrastructure
import '../../infrastructure/repositories/task_repository.dart';

// 6. Presentation (dentro da própria camada)
import '../widgets/task_card.dart';
```

---

**Última atualização:** 23/11/2025
**Versão:** 2.0
**Status:** ✅ Em conformidade com Clean Architecture
