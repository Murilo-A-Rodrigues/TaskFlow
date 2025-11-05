# Guia de Melhores Práticas - TaskFlow App

## 🎯 Princípios Fundamentais

### 1. Clean Architecture
- **Separação de Camadas**: UI → Services → Data
- **Dependências**: Sempre apontando "para dentro"
- **Regra de Ouro**: Camadas internas não conhecem camadas externas

### 2. Single Responsibility Principle (SRP)
- **Uma responsabilidade por classe/widget**
- **Exemplo**: `StatsCard` só exibe estatísticas
- **Evitar**: Widgets que fazem múltiplas coisas

### 3. Organização por Features/Domains
```
lib/
├── widgets/
│   ├── common/      # Widgets reutilizáveis globalmente
│   └── [feature]/   # Widgets específicos de uma feature
├── services/
│   ├── core/        # Lógica de negócio central
│   ├── storage/     # Persistência de dados
│   └── integrations/ # APIs e integrações externas
```

## 📁 Convenções de Nomenclatura

### Arquivos e Pastas
```dart
// ✅ CORRETO
lib/widgets/home/stats_card.dart
lib/services/core/task_service.dart
lib/utils/format_utils.dart

// ❌ EVITAR
lib/widgets/StatsCard.dart        // PascalCase em arquivos
lib/services/TaskService.dart     // Sem organização por categoria
lib/helpers/FormatHelper.dart     // Inconsistência de nomenclatura
```

### Classes e Widgets
```dart
// ✅ CORRETO
class TaskListWidget extends StatefulWidget { }
class ValidationUtils { }
class AppConfig { }

// ❌ EVITAR  
class taskList extends StatefulWidget { }  // camelCase em classes
class Utils { }                            // Nome muito genérico
class Helper { }                           // Nome não descritivo
```

### Métodos e Variáveis
```dart
// ✅ CORRETO
void _buildTaskCard() { }
final List<Task> activeTasks = [];
static const double defaultPadding = 16.0;

// ❌ EVITAR
void _BuildTaskCard() { }          // PascalCase em métodos privados
final List<Task> Tasks = [];       // PascalCase em variáveis
static const double padding = 16.0; // Nome muito genérico
```

## 🏗️ Estrutura de Widgets

### Widget Simples (Stateless)
```dart
class StatsCard extends StatelessWidget {
  const StatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, taskService, child) {
        return Card(
          child: _buildContent(taskService),
        );
      },
    );
  }
  
  Widget _buildContent(TaskService taskService) {
    // Implementação focada
  }
}
```

### Widget com Estado (Stateful)
```dart
class TaskListWidget extends StatefulWidget {
  const TaskListWidget({Key? key}) : super(key: key);

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  // ✅ Estado mínimo necessário
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, taskService, child) {
        return _isLoading 
          ? const CircularProgressIndicator()
          : _buildTaskList(taskService);
      },
    );
  }
  
  // ✅ Métodos privados focados
  Widget _buildTaskList(TaskService taskService) { }
  void _refreshTasks() async { }
}
```

## 🔧 Padrões de Serviços

### Estrutura Base de Serviço
```dart
// lib/services/core/task_service.dart
class TaskService extends ChangeNotifier {
  // ✅ Estado privado
  List<Task> _tasks = [];
  bool _isLoading = false;
  
  // ✅ Getters públicos
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get activeTasks => _tasks.where((task) => !task.isCompleted).toList();
  bool get isLoading => _isLoading;
  
  // ✅ Métodos públicos com validação
  Future<void> addTask(Task task) async {
    final validation = ValidationUtils.validateTaskTitle(task.title);
    if (validation != null) {
      throw ArgumentError(validation);
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _tasks.add(task);
      await _persistTasks();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // ✅ Métodos privados para implementação
  Future<void> _persistTasks() async { }
}
```

### Padrão de Error Handling
```dart
class TaskService extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  Future<void> addTask(Task task) async {
    try {
      _clearError();
      _setLoading(true);
      
      // Lógica principal
      await _performAddTask(task);
      
    } on ValidationException catch (e) {
      _setError('Erro de validação: ${e.message}');
    } on NetworkException catch (e) {
      _setError('Erro de conexão: ${e.message}');
    } catch (e) {
      _setError('Erro inesperado: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
```

## 📱 Padrões de UI/UX

### Responsive Design
```dart
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }
}
```

### Uso de Constantes de Tema
```dart
// ✅ CORRETO - Usando constantes centralizadas
Container(
  padding: const EdgeInsets.all(AppConfig.defaultPadding),
  decoration: BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
    boxShadow: AppTheme.cardShadow,
  ),
  child: Text(
    'Título',
    style: AppTheme.titleStyle,
  ),
)

// ❌ EVITAR - Valores hardcoded
Container(
  padding: const EdgeInsets.all(16.0),      // Valor fixo
  decoration: BoxDecoration(
    color: Colors.white,                     // Cor hardcoded
    borderRadius: BorderRadius.circular(12), // Valor fixo
  ),
  child: Text(
    'Título',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Estilo inline
  ),
)
```

## 🧪 Padrões de Teste

### Teste de Widget
```dart
// test/widgets/stats_card_test.dart
class MockTaskService extends Mock implements TaskService {}

void main() {
  group('StatsCard', () {
    late MockTaskService mockTaskService;
    
    setUp(() {
      mockTaskService = MockTaskService();
    });
    
    testWidgets('should display correct stats', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.totalTasks).thenReturn(10);
      when(mockTaskService.completedTasks).thenReturn(List.generate(5, (i) => Task()));
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskService>.value(
            value: mockTaskService,
            child: const StatsCard(),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Total: 10'), findsOneWidget);
      expect(find.text('Concluídas: 5'), findsOneWidget);
    });
  });
}
```

### Teste de Serviço
```dart
// test/services/task_service_test.dart
void main() {
  group('TaskService', () {
    late TaskService taskService;
    
    setUp(() {
      taskService = TaskService();
    });
    
    test('should add task successfully', () async {
      // Arrange
      final task = Task(title: 'Test Task', description: 'Test Description');
      
      // Act
      await taskService.addTask(task);
      
      // Assert
      expect(taskService.tasks.length, 1);
      expect(taskService.tasks.first.title, 'Test Task');
    });
    
    test('should throw error for invalid task', () async {
      // Arrange
      final invalidTask = Task(title: '', description: 'Test');
      
      // Act & Assert
      expect(
        () async => await taskService.addTask(invalidTask),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

## 📋 Checklist para Novas Features

### Antes de Implementar
- [ ] Feature quebrada em componentes pequenos?
- [ ] Responsabilidades bem definidas?
- [ ] Serviços organizados por categoria?
- [ ] Nomenclatura consistente?
- [ ] Constantes centralizadas?

### Durante a Implementação
- [ ] Um widget = uma responsabilidade
- [ ] Métodos privados focados
- [ ] Error handling adequado
- [ ] Validações nos serviços
- [ ] UI responsiva

### Após a Implementação  
- [ ] Testes unitários criados
- [ ] Testes de widget funcionando
- [ ] Documentação atualizada
- [ ] Performance verificada
- [ ] Acessibilidade considerada

## 🚫 Anti-Padrões para Evitar

### 1. God Class/Widget
```dart
// ❌ EVITAR
class MegaHomeScreen extends StatefulWidget {
  // 1000+ linhas fazendo tudo
}

// ✅ CORRETO
class HomeScreen extends StatefulWidget {
  // 150 linhas coordenando widgets específicos
}
```

### 2. Magic Numbers
```dart
// ❌ EVITAR
Container(height: 56)  // O que significa 56?
EdgeInsets.all(8)      // Por que 8?

// ✅ CORRETO  
Container(height: AppConfig.appBarHeight)
EdgeInsets.all(AppConfig.smallPadding)
```

### 3. Hardcoded Strings
```dart
// ❌ EVITAR
Text('Adicionar Tarefa')
showDialog(title: 'Erro')

// ✅ CORRETO (preparação para i18n)
Text(AppStrings.addTask)
showDialog(title: AppStrings.error)
```

### 4. Tight Coupling
```dart
// ❌ EVITAR - Widget conhece implementação específica
class TaskCard extends StatelessWidget {
  final SqliteTaskRepository repository; // Acoplamento forte
}

// ✅ CORRETO - Widget depende de abstração
class TaskCard extends StatelessWidget {
  final TaskService taskService; // Interface/abstração
}
```

## 📈 Métricas de Qualidade

### Limites Recomendados
- **Linhas por arquivo**: Max 300 linhas
- **Métodos por classe**: Max 10 métodos públicos
- **Parâmetros por método**: Max 5 parâmetros
- **Níveis de indentação**: Max 4 níveis
- **Complexidade ciclomática**: Max 10

### Code Review Checklist
- [ ] Single Responsibility respeitado?
- [ ] Nomenclatura clara e consistente?
- [ ] Constantes ao invés de magic numbers?
- [ ] Error handling adequado?
- [ ] Testes cobrindo casos principais?
- [ ] Performance considerada?
- [ ] Documentação suficiente?

---

**Lembre-se**: Consistência é mais importante que perfeição. Mantenha os padrões estabelecidos e evolua gradualmente.