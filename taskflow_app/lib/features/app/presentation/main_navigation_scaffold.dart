import 'package:flutter/material.dart';
import '../../tasks/pages/task_list_page.dart';
import '../../home/pages/home_screen.dart';
import '../../settings/pages/settings_screen.dart';

/// Scaffold principal com navegação inferior
///
/// Gerencia navegação entre:
/// - Home (estatísticas e visão geral)
/// - Tarefas (lista completa com estado vazio)
/// - Configurações
class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0; // Começa na aba Início para mostrar tutorial

  // Páginas da navegação
  final List<Widget> _pages = const [
    HomeScreen(),
    TaskListPage(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
