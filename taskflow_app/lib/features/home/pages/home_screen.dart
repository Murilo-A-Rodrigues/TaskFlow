import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/core/task_service.dart';
import '../services/storage/preferences_service.dart';
import '../widgets/common/user_avatar.dart';
import '../widgets/home/stats_card.dart';
import '../widgets/home/first_steps_card.dart';
import '../widgets/home/task_list_widget.dart';
import '../widgets/home/home_drawer.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      appBar: AppBar(
        title: const Text('TaskFlow'),
        centerTitle: true,
        actions: [
          // Avatar do usuário no AppBar
          Consumer<PreferencesService>(
            builder: (context, prefsService, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0), // Aumentado de 4 para 8
                child: UserAvatar(
                  photoPath: prefsService.userPhotoPath,
                  userName: prefsService.userName,
                  radius: 16, // Aumentado de 14 para 16 para melhor visibilidade
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
            padding: const EdgeInsets.all(8), // Reduzido de 12 para 8
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ), // Adicionado constraints para garantir tamanho mínimo
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120), // Aumentado de 110 para 120
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), // Reduzido padding top de 8 para 4
                child: Container(
                  height: 44, // Reduzido de 48 para 44
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduzido vertical padding
                      isDense: true, // Adiciona densidade para reduzir altura
                    ),
                  ),
                ),
              ),
              Container(
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
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          return Column(
            children: [
              StatsCard(taskService: taskService),
              FirstStepsCard(taskService: taskService),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TaskListWidget(
                      tasks: taskService.searchTasks(_searchQuery),
                      searchQuery: _searchQuery,
                      onToggleTask: _toggleTask,
                      onEditTask: _editTask,
                      onDeleteTask: _deleteTask,
                    ),
                    TaskListWidget(
                      tasks: taskService.searchTasks(_searchQuery).where((task) => !task.isCompleted).toList(),
                      searchQuery: _searchQuery,
                      onToggleTask: _toggleTask,
                      onEditTask: _editTask,
                      onDeleteTask: _deleteTask,
                    ),
                    TaskListWidget(
                      tasks: taskService.searchTasks(_searchQuery).where((task) => task.isCompleted).toList(),
                      searchQuery: _searchQuery,
                      onToggleTask: _toggleTask,
                      onEditTask: _editTask,
                      onDeleteTask: _deleteTask,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewTask() async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (context) => const AddEditTaskScreen(),
      ),
    );

    if (result != null && mounted) {
      await context.read<TaskService>().addTask(result);
    }
  }

  void _editTask(Task task) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(task: task),
      ),
    );

    if (result != null && mounted) {
      await context.read<TaskService>().updateTask(result);
    }
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
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
}