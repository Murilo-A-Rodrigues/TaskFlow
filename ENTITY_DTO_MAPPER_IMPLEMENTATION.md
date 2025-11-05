# Implementação da Arquitetura Entity/DTO/Mapper - TaskFlow

**Data:** 4 de novembro de 2025  
**Projeto:** TaskFlow Flutter App  
**Baseado em:** Documento "Modelo DTO e Mapeamento" (FoodSafe pattern)

## 📋 Resumo Executivo

Implementação completa da arquitetura **Entity/DTO/Mapper** no TaskFlow seguindo fielmente o padrão estabelecido no documento "Modelo DTO e Mapeamento" do FoodSafe. Esta arquitetura separa claramente:

- **Entity**: Modelo interno limpo e validado para uso na aplicação
- **DTO**: Formato de transporte que espelha a estrutura do Supabase  
- **Mapper**: Conversor centralizado entre os dois formatos

## 🎯 Objetivos Alcançados

- ✅ **Isolamento de mudanças** - Backend pode mudar sem afetar UI
- ✅ **Qualidade e segurança** - Dados sempre validados na Entity
- ✅ **Cache otimizado** - DTOs eficientes para armazenamento local
- ✅ **Testes simplificados** - Conversões isoladas e testáveis
- ✅ **Offline-first preparado** - Cache com DTOs + UI com Entities

## 🏗️ Arquitetura Implementada

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   TaskService   │───▶│  TaskRepository  │───▶│   Supabase DB   │
│  (Provider)     │    │  (DTO/Entity)    │    │   (DTOs)        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                        │                        │
        │ Consume                 │ Store                  │ Transport
        │ Entities               │ DTOs                   │ DTOs
        ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   UI Widgets    │    │ SharedPreferences│    │   TaskMapper    │
│   (Clean Data)  │    │  (Cache Local)   │    │ (Conversões)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📁 Estrutura de Arquivos Criados

### 1. Domain Layer (Modelo Interno)

#### `lib/domain/entities/task.dart`
**Propósito:** Task Entity - Representação interna rica e validada

**Características Implementadas:**
```dart
class Task {
  // Campos com tipos seguros
  final String id;
  final String title;
  final String description;        // Sempre trimmed, nunca null
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;         // Nullable seguro
  final TaskPriority priority;     // Enum forte
  final DateTime updatedAt;       // Para sincronização

  // Validação no construtor
  Task({...}) : description = description?.trim() ?? '',
                priority = priority ?? TaskPriority.medium;
                
  // Conveniências para a UI
  String get statusText => isCompleted ? 'Concluída' : 'Pendente';
  String get priorityIcon {...}    // 🟢🟡🔴 baseado na prioridade  
  String get priorityColorHex {...} // Cores hex para UI
  String get subtitle {...}        // Texto formatado pronto
  bool get isOverdue {...}         // Lógica de atraso
  bool get isDueToday {...}        // Vence hoje
}
```

**Benefícios:**
- ✅ **Tipos seguros** - DateTime vs String, enum vs int
- ✅ **Validação centralizada** - description sempre trimmed  
- ✅ **Conveniências UI** - getters formatados prontos
- ✅ **Lógica de negócio** - isOverdue, isDueToday encapsulados

#### `lib/domain/enums/task_priority.dart`
**Propósito:** Enum TaskPriority com extensões

```dart
enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get displayName => {...};  // 'Baixa', 'Média', 'Alta'
  int get value => {...};          // 1, 2, 3 para persistência
}

class TaskPriorityHelper {
  static TaskPriority fromValue(int value) {...} // Conversão segura
}
```

### 2. Data Layer (Transporte e Persistência)

#### `lib/data/dtos/task_dto.dart`
**Propósito:** TaskDto - Espelha estrutura exata do Supabase

**Características do DTO:**
```dart
class TaskDto {
  // Nomes snake_case (iguais ao banco)
  final String id;
  final String title;
  final String? description;
  final bool is_completed;         // snake_case
  final String created_at;         // ISO8601 string
  final String? due_date;          // ISO8601 string ou null  
  final int priority;              // int para o banco
  final String updated_at;         // ISO8601 para sync

  // Serialização para rede/cache
  factory TaskDto.fromMap(Map<String, dynamic> map) {...}
  Map<String, dynamic> toMap() {...}
  factory TaskDto.fromJson(String jsonString) {...}
  String toJson() {...}
}
```

**Benefícios:**
- ✅ **Espelha banco** - Nomes e tipos exatos do Supabase
- ✅ **Serialização eficiente** - JSON nativo para cache
- ✅ **Tipagem primitiva** - Fácil conversão rede ↔ objeto

#### `lib/data/mappers/task_mapper.dart`
**Propósito:** Conversor único e centralizado entre DTO ↔ Entity

**Responsabilidades do Mapper:**
```dart
class TaskMapper {
  // Conversão principal: DTO → Entity
  static Task toEntity(TaskDto dto) {
    return Task(
      // Conversões de tipo
      createdAt: DateTime.parse(dto.created_at),
      dueDate: dto.due_date != null ? DateTime.tryParse(dto.due_date!) : null,
      priority: TaskPriorityHelper.fromValue(dto.priority),
      // Validação acontece na Entity
    );
  }

  // Conversão inversa: Entity → DTO
  static TaskDto toDto(Task entity) {
    return TaskDto(
      created_at: entity.createdAt.toIso8601String(),
      due_date: entity.dueDate?.toIso8601String(),
      priority: entity.priority.value,
      // snake_case vs camelCase
    );
  }

  // Conveniências para listas
  static List<Task> toEntityList(List<TaskDto> dtos) {...}
  static List<TaskDto> toDtoList(List<Task> entities) {...}
  
  // Conveniências para Maps (Supabase direto)
  static Task fromMap(Map<String, dynamic> map) {...}
  static Map<String, dynamic> toMap(Task entity) {...}
}
```

**O que o Mapper FAZ:**
- ✅ Renomeia campos (snake_case ↔ camelCase)
- ✅ Converte tipos (String ↔ DateTime, int ↔ enum)
- ✅ Aplica defaults seguros
- ✅ Documenta conversões

**O que o Mapper NÃO FAZ:**
- ❌ Regras de negócio (ficam na Entity)
- ❌ Operações I/O (ficam no Repository)
- ❌ Validações complexas (ficam na Entity)

### 3. Repository Layer (Persistência com DTO/Entity)

#### `lib/repositories/task_repository_v2.dart`
**Propósito:** Repository offline-first usando arquitetura DTO/Entity

**Estratégia Cache-First com DTOs:**
```dart
class TaskRepository {
  // Cache armazena DTOs (eficiente para serialização)
  Future<List<Task>> getAllTasks() async {
    // 1. Carrega DTOs do cache (rápido)
    final cachedDtos = await _loadDtosFromCache();
    
    // 2. Sincroniza em background
    if (await _shouldSync()) {
      await _syncIncrementally();
    }
    
    // 3. Recarrega DTOs e converte para Entities
    final updatedDtos = await _loadDtosFromCache();
    return TaskMapper.toEntityList(updatedDtos); // UI recebe Entities
  }

  // CRUD com conversões automáticas
  Future<Task?> createTask(Task entity) async {
    final dto = TaskMapper.toDto(entity);        // Entity → DTO
    await _addDtoToCache(dto);                   // Cache otimista
    
    final taskMap = TaskMapper.toMap(entity);    // Para Supabase
    final response = await _supabase.insert(taskMap);
    
    final serverDto = TaskDto.fromMap(response); // Resposta → DTO
    return TaskMapper.toEntity(serverDto);       // DTO → Entity
  }
}
```

**Benefícios da Separação:**
- ✅ **Cache eficiente** - DTOs são mais leves para serialização
- ✅ **UI limpa** - Sempre recebe Entities validadas  
- ✅ **Sync incremental** - DTOs têm updated_at nativo
- ✅ **Optimistic updates** - Cache local com DTOs

### 4. Service Layer (Consumo de Entities)

#### `lib/services/core/task_service_v2.dart`
**Propósito:** TaskService que consome apenas Entities

**Separação Clara de Responsabilidades:**
```dart
class TaskService extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();
  final List<Task> _tasks = [];  // Apenas Entities

  Future<void> addTask(Task entity) async {
    // 1. Optimistic update com Entity
    _tasks.add(entity);
    notifyListeners();
    
    // 2. Repository abstrai DTOs
    final result = await _repository.createTask(entity);
    
    // 3. Confirma com Entity retornada
    if (result != null) {
      final index = _tasks.indexWhere((t) => t.id == entity.id);
      if (index != -1) _tasks[index] = result;
    }
  }

  // Getters usando conveniências da Entity
  List<Task> get overdueTasks => _tasks.where((task) => task.isOverdue).toList();
  List<Task> get tasksDueToday => _tasks.where((task) => task.isDueToday).toList();
}
```

**Benefícios:**
- ✅ **Service limpo** - Não sabe que DTOs existem
- ✅ **UI rica** - Usa getters e métodos da Entity
- ✅ **Optimistic updates** - Com objetos tipados
- ✅ **Separação clara** - Repository abstrai persistência

### 5. Sample Data Atualizado

#### `lib/data/sample_data_v2.dart`
**Propósito:** Dados de exemplo usando nova Entity

```dart
class SampleData {
  static List<Task> getSampleTasks() {
    return [
      Task(
        id: 'sample_1',
        title: 'Implementar arquitetura Entity/DTO',
        priority: TaskPriority.high,
        updatedAt: now.subtract(Duration(days: 1)), // Obrigatório na Entity
      ),
      // ... mais tarefas usando Entity
    ];
  }

  static List<Task> generateBulkSampleTasks(int count) {...} // Para testes
}
```

## 🔄 Fluxo de Dados Implementado

### Fluxo de Leitura (Cache-First)
```
1. UI solicita tarefas
   ↓
2. TaskService.getAllTasks()
   ↓  
3. TaskRepository.getAllTasks()
   ↓
4. Cache: _loadDtosFromCache() → List<TaskDto>
   ↓
5. TaskMapper.toEntityList(dtos) → List<Task>
   ↓
6. UI recebe List<Task> (Entities limpas)

Paralelo:
4b. Sync: _syncIncrementally() → DTOs atualizados no cache
```

### Fluxo de Escrita (Optimistic Update)
```
1. UI cria/edita tarefa (Task Entity)
   ↓
2. TaskService.addTask(entity)
   ↓
3. Optimistic: _tasks.add(entity) + notifyListeners()
   ↓
4. TaskRepository.createTask(entity)
   ↓
5. TaskMapper.toDto(entity) → TaskDto
   ↓
6. Cache: _addDtoToCache(dto)
   ↓
7. Supabase: insert(TaskMapper.toMap(entity))
   ↓
8. Response: TaskDto.fromMap() → TaskMapper.toEntity() → Task
   ↓
9. Confirma na UI com Task final
```

## 📊 Comparação: Antes vs. Depois

### ❌ Arquitetura Anterior (Monolítica)
```dart
// Task única para tudo
class Task {
  // Misturava responsabilidades
  Map<String, dynamic> toJson() // Para Supabase E cache E UI
  factory Task.fromJson()       // Do Supabase E cache E UI
}

// Repository confuso
class TaskRepository {
  Task task = Task.fromJson(supabaseResponse); // Conversão direta
  cache.setString(task.toJson());               // Serialização única
  return task; // UI recebe dados "sujos" do servidor
}
```

**Problemas:**
- ❌ Mudança no Supabase quebra UI
- ❌ Validação espalhada por todo código  
- ❌ Cache ineficiente (dados formatados para UI)
- ❌ Testes complexos (muitas responsabilidades)

### ✅ Nova Arquitetura (Entity/DTO/Mapper)
```dart
// Separação clara
TaskDto     // Apenas para transporte/cache
Task        // Apenas para UI/negócio  
TaskMapper  // Apenas para conversão

// Repository limpo  
TaskRepository {
  TaskDto dto = TaskDto.fromMap(supabaseResponse);  // DTO do servidor
  cache.setString(dto.toJson());                    // DTO eficiente no cache
  Task entity = TaskMapper.toEntity(dto);           // Conversão isolada
  return entity; // UI recebe dados limpos e validados
}
```

**Benefícios:**
- ✅ Mudança no Supabase só afeta Mapper
- ✅ Validação centralizada na Entity
- ✅ Cache eficiente com DTOs
- ✅ Testes isolados e simples

## 🧪 Validação e Testes

### Teste da Arquitetura
```bash
# Compilação sem erros
> flutter analyze lib/domain/ --fatal-infos
✅ No issues found!

> flutter analyze lib/data/ --fatal-infos  
✅ No issues found!

> flutter analyze lib/repositories/task_repository_v2.dart --fatal-infos
✅ No issues found!

> flutter analyze lib/services/core/task_service_v2.dart --fatal-infos
✅ No issues found!
```

### Testes de Conversão (Exemplos)
```dart
void main() {
  test('TaskMapper: DTO → Entity conversion', () {
    // Arrange
    final dto = TaskDto(
      id: 'test_1',
      title: 'Test Task',
      is_completed: false,
      created_at: '2025-11-04T10:00:00Z',
      priority: 2,
      updated_at: '2025-11-04T10:00:00Z',
    );
    
    // Act
    final entity = TaskMapper.toEntity(dto);
    
    // Assert
    expect(entity.id, 'test_1');
    expect(entity.title, 'Test Task');
    expect(entity.isCompleted, false);
    expect(entity.priority, TaskPriority.medium);
    expect(entity.createdAt, DateTime.parse('2025-11-04T10:00:00Z'));
  });
}
```

## 🎯 Próximos Passos

### Para Produção
1. **Migração gradual**: Usar TaskRepository_v2 e TaskService_v2 paralelamente
2. **Testes unitários**: Criar suíte completa para TaskMapper
3. **Performance**: Benchmarks de serialização DTO vs Entity
4. **Monitoring**: Logs de conversão e cache hit rate

### Para Desenvolvimento
1. **Gerador de código**: Automatizar criação de DTOs/Entities
2. **Validação**: JSON Schema para DTOs
3. **Documentação**: Swagger/OpenAPI integration
4. **CI/CD**: Testes automáticos de conversão

## 📈 Métricas de Sucesso

- ✅ **0 erros de compilação** - Arquitetura bem estruturada
- ✅ **Separação clara** - 3 camadas distintas (Entity/DTO/Mapper)  
- ✅ **Cache eficiente** - DTOs serializáveis nativamente
- ✅ **UI rica** - Entities com conveniências (isOverdue, priorityIcon, etc.)
- ✅ **Offline-first** - Cache com DTOs + UI com Entities
- ✅ **Testabilidade** - Mapper isolado e sem dependências
- ✅ **Manutenibilidade** - Mudanças isoladas por camada

## 🔚 Conclusão

A implementação da arquitetura **Entity/DTO/Mapper** no TaskFlow foi concluída com sucesso, seguindo fielmente os padrões estabelecidos no documento "Modelo DTO e Mapeamento" do FoodSafe. 

Esta arquitetura proporciona:
- **Robustez** - Dados sempre validados e tipados
- **Flexibilidade** - Mudanças no backend não afetam UI  
- **Performance** - Cache eficiente com DTOs
- **Manutenibilidade** - Responsabilidades bem separadas
- **Testabilidade** - Componentes isolados e testáveis

O TaskFlow agora possui uma base sólida e escalável para evoluir mantendo qualidade e consistência dos dados em toda a aplicação.

---

**Implementação Entity/DTO/Mapper concluída!** 🎉  
*Seguindo padrão FoodSafe adaptado para TaskFlow com arquitetura offline-first*