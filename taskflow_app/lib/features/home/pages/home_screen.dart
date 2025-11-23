import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/domain/entities/task.dart';
import '../../tasks/application/task_service.dart';
import '../../../services/core/task_filter_service.dart';
import '../../../services/storage/preferences_service.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../widgets/stats_card.dart';
import '../widgets/home_drawer.dart';
import '../../tasks/widgets/task_card.dart';
import '../../tasks/widgets/task_form_dialog.dart';
import '../../tasks/widgets/filter_bottom_sheet.dart';
import '../../tasks/widgets/active_filters_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Tutorial e animação do FAB
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _showTutorial = false;
  bool _dontShowAgain = false;
  bool _checkedFirstTime = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // Animação do FAB (pulsação contínua)
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Verifica se deve mostrar tutorial após a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verifica novamente quando as dependências mudam
    if (!_checkedFirstTime) {
      _checkedFirstTime = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkFirstTimeUser();
      });
    }
  }
  
  void _checkFirstTimeUser() {
    if (!mounted) return;
    
    try {
      final prefsService = context.read<PreferencesService>();

      print('🔍 Checking first time user on HomeScreen...');
      print('   isFirstTimeUser: ${prefsService.isFirstTimeUser}');
      print('   isOnboardingCompleted: ${prefsService.isOnboardingCompleted}');
      print('   hasValidConsent: ${prefsService.hasValidConsent}');
      
      if (prefsService.isFirstTimeUser) {
        print('🎉 First time detected! Showing tutorial and starting animation...');
        
        // Inicia a pulsação do FAB
        _fabAnimationController.repeat(reverse: true);
        
        setState(() {
          _showTutorial = true;
        });
        
        print('✅ Tutorial state set to true, animation started');
        print('✅ _showTutorial = $_showTutorial');
      } else {
        print('ℹ️ Not first time, skipping tutorial');
        // Garante que animação está parada se não for primeira vez
        _fabAnimationController.stop();
        _fabAnimationController.value = 1.0;
      }
    } catch (e) {
      print('❌ Error checking first time user: $e');
    }
  }
  
  void _dismissTutorial({bool dontShowAgain = false}) async {
    // NÃO para a pulsação - ela continua até criar primeira tarefa
    // Apenas fecha o tutorial overlay
    
    setState(() {
      _showTutorial = false;
    });

    if (dontShowAgain) {
      final prefsService = context.read<PreferencesService>();
      await prefsService.completeFirstTimeSetup();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          drawer: const HomeDrawer(),
          appBar: AppBar(
        title: const Text('TaskFlow'),
        centerTitle: true,
        actions: [
          // Botão de filtros
          Consumer<TaskFilterService>(
            builder: (context, filterService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FilterBottomSheet(),
                      );
                    },
                  ),
                  if (filterService.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${filterService.activeFiltersCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Avatar do usuário no AppBar
          Consumer<PreferencesService>(
            builder: (context, prefsService, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: UserAvatar(
                  photoPath: prefsService.userPhotoPath,
                  userName: prefsService.userName,
                  radius: 16,
                  onTap: () => _showPhotoOptions(context),
                  showBorder: true,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160), // Aumentado para comportar filtros
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), // Reduzido padding
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar tarefas...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              // Chips de filtros ativos com SafeArea
              SafeArea(
                bottom: false,
                child: const ActiveFiltersChip(),
              ),
              SizedBox(
                height: 48, // Altura fixa para o TabBar
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Pendentes'),
                    Tab(text: 'Concluídas'),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer2<TaskService, TaskFilterService>(
        builder: (context, taskService, filterService, child) {
          // Aplica busca e filtros
          List<Task> allTasks = taskService.searchTasks(_searchQuery);
          allTasks = filterService.applyFilters(allTasks);
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildScrollableTaskView(
                taskService: taskService,
                tasks: allTasks,
              ),
              _buildScrollableTaskView(
                taskService: taskService,
                tasks: allTasks.where((task) => !task.isCompleted).toList(),
              ),
              _buildScrollableTaskView(
                taskService: taskService,
                tasks: allTasks.where((task) => task.isCompleted).toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton(
              onPressed: _addNewTask,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    ),
    // Tutorial Overlay sobre tudo
    if (_showTutorial) _buildTutorialOverlay(),
      ],
    );
  }

  void _addNewTask() async {
    // Usando nova dialog reutilizável (Prompt 05)
    final result = await showTaskFormDialog(context);

    if (result != null && mounted) {
      await context.read<TaskService>().addTask(result);
      
      // Para a pulsação do FAB SOMENTE quando criar primeira tarefa
      _fabAnimationController.stop();
      _fabAnimationController.value = 1.0;
      
      // Marca que não é mais primeira vez
      final prefsService = context.read<PreferencesService>();
      if (prefsService.isFirstTimeUser) {
        await prefsService.completeFirstTimeSetup();
      }
      
      // Fecha o tutorial se ainda estiver aberto
      setState(() {
        _showTutorial = false;
      });
    }
  }

  Widget _buildScrollableTaskView({
    required TaskService taskService,
    required List<Task> tasks,
  }) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatsCard(taskService: taskService),
          ),
        ),
        if (tasks.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma tarefa encontrada',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onToggle: () => _toggleTask(task.id),
                  onEdit: () => _editTask(task),
                  onDelete: () => _deleteTask(task),
                );
              },
              childCount: tasks.length,
            ),
          ),
      ],
    );
  }

  void _editTask(Task task) async {
    // Usando nova dialog reutilizável (Prompt 05)
    final result = await showTaskFormDialog(context, initial: task);

    if (result != null && mounted) {
      await context.read<TaskService>().updateTask(result);
    }
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<TaskService>().deleteTask(task.id);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _toggleTask(String taskId) async {
    final taskService = context.read<TaskService>();
    final task = taskService.tasks.firstWhere((task) => task.id == taskId);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await taskService.updateTask(updatedTask);
  }

  void _showPhotoOptions(BuildContext context) {
    // Implementação movida para HomeDrawer
    // Mantida aqui para compatibilidade com o AppBar avatar
    Scaffold.of(context).openDrawer();
  }
  
  /// Tutorial Overlay
  Widget _buildTutorialOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'Bem-vindo ao TaskFlow!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Recursos
                  _buildFeatureItem(
                    Icons.add_task,
                    'Crie tarefas com prioridades',
                  ),
                  _buildFeatureItem(
                    Icons.track_changes,
                    'Acompanhe seu progresso',
                  ),
                  _buildFeatureItem(
                    Icons.calendar_today,
                    'Organize seu dia a dia',
                  ),
                  const SizedBox(height: 24),

                  // Checkbox "Não exibir novamente"
                  Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (value) {
                          setState(() {
                            _dontShowAgain = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text('Não exibir dica novamente'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botão Entendi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _dismissTutorial(
                        dontShowAgain: _dontShowAgain,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Entendi!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
