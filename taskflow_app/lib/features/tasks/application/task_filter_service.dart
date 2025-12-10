import 'package:flutter/foundation.dart';
import '../domain/entities/task.dart';
import '../domain/entities/task_priority.dart';

/// TaskFilterService - Serviço para filtrar tarefas
///
/// Gerencia os filtros ativos e aplica-os à lista de tarefas.
/// Suporta filtros por:
/// - Categoria
/// - Prioridade
/// - Status (Todas/Pendentes/Concluídas/Atrasadas)
/// - Intervalo de datas
class TaskFilterService extends ChangeNotifier {
  // Filtros ativos
  final Set<String> _selectedCategoryIds = {};
  final Set<TaskPriority> _selectedPriorities = {};
  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  DateRangeFilter _dateRangeFilter = DateRangeFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Getters
  Set<String> get selectedCategoryIds => Set.unmodifiable(_selectedCategoryIds);
  Set<TaskPriority> get selectedPriorities =>
      Set.unmodifiable(_selectedPriorities);
  TaskStatusFilter get statusFilter => _statusFilter;
  DateRangeFilter get dateRangeFilter => _dateRangeFilter;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  /// Verifica se há algum filtro ativo
  bool get hasActiveFilters {
    return _selectedCategoryIds.isNotEmpty ||
        _selectedPriorities.isNotEmpty ||
        _statusFilter != TaskStatusFilter.all ||
        _dateRangeFilter != DateRangeFilter.all;
  }

  /// Conta quantos filtros estão ativos
  int get activeFiltersCount {
    int count = 0;
    if (_selectedCategoryIds.isNotEmpty) count++;
    if (_selectedPriorities.isNotEmpty) count++;
    if (_statusFilter != TaskStatusFilter.all) count++;
    if (_dateRangeFilter != DateRangeFilter.all) count++;
    return count;
  }

  /// Adiciona/remove categoria dos filtros
  void toggleCategory(String categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  /// Adiciona/remove prioridade dos filtros
  void togglePriority(TaskPriority priority) {
    if (_selectedPriorities.contains(priority)) {
      _selectedPriorities.remove(priority);
    } else {
      _selectedPriorities.add(priority);
    }
    notifyListeners();
  }

  /// Define o filtro de status
  void setStatusFilter(TaskStatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  /// Define o filtro de intervalo de datas
  void setDateRangeFilter(
    DateRangeFilter filter, {
    DateTime? start,
    DateTime? end,
  }) {
    _dateRangeFilter = filter;
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  /// Remove todos os filtros
  void clearAllFilters() {
    _selectedCategoryIds.clear();
    _selectedPriorities.clear();
    _statusFilter = TaskStatusFilter.all;
    _dateRangeFilter = DateRangeFilter.all;
    _customStartDate = null;
    _customEndDate = null;
    notifyListeners();
  }

  /// Remove um filtro específico por tipo
  void removeFilter(FilterType type) {
    switch (type) {
      case FilterType.category:
        _selectedCategoryIds.clear();
        break;
      case FilterType.priority:
        _selectedPriorities.clear();
        break;
      case FilterType.status:
        _statusFilter = TaskStatusFilter.all;
        break;
      case FilterType.dateRange:
        _dateRangeFilter = DateRangeFilter.all;
        _customStartDate = null;
        _customEndDate = null;
        break;
    }
    notifyListeners();
  }

  /// Aplica os filtros a uma lista de tarefas
  List<Task> applyFilters(List<Task> tasks) {
    List<Task> filtered = List.from(tasks);

    // Filtro por categoria
    if (_selectedCategoryIds.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.categoryId != null &&
            _selectedCategoryIds.contains(task.categoryId);
      }).toList();
    }

    // Filtro por prioridade
    if (_selectedPriorities.isNotEmpty) {
      filtered = filtered.where((task) {
        return _selectedPriorities.contains(task.priority);
      }).toList();
    }

    // Filtro por status
    filtered = _applyStatusFilter(filtered);

    // Filtro por data
    filtered = _applyDateRangeFilter(filtered);

    return filtered;
  }

  /// Aplica filtro de status
  List<Task> _applyStatusFilter(List<Task> tasks) {
    switch (_statusFilter) {
      case TaskStatusFilter.all:
        return tasks;
      case TaskStatusFilter.pending:
        return tasks.where((task) => !task.isCompleted).toList();
      case TaskStatusFilter.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case TaskStatusFilter.overdue:
        final now = DateTime.now();
        return tasks.where((task) {
          return !task.isCompleted &&
              task.dueDate != null &&
              task.dueDate!.isBefore(now);
        }).toList();
    }
  }

  /// Aplica filtro de intervalo de datas
  List<Task> _applyDateRangeFilter(List<Task> tasks) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_dateRangeFilter) {
      case DateRangeFilter.all:
        return tasks;
      case DateRangeFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateRangeFilter.thisWeek:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case DateRangeFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateRangeFilter.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return tasks;
        }
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
    }

    return tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(startDate!) &&
          task.dueDate!.isBefore(endDate!);
    }).toList();
  }
}

/// Enum para tipos de filtro
enum FilterType { category, priority, status, dateRange }

/// Enum para filtros de status
enum TaskStatusFilter { all, pending, completed, overdue }

/// Enum para filtros de intervalo de datas
enum DateRangeFilter { all, today, thisWeek, thisMonth, custom }

/// Extensão para obter labels dos filtros
extension TaskStatusFilterExtension on TaskStatusFilter {
  String get label {
    switch (this) {
      case TaskStatusFilter.all:
        return 'Todas';
      case TaskStatusFilter.pending:
        return 'Pendentes';
      case TaskStatusFilter.completed:
        return 'Concluídas';
      case TaskStatusFilter.overdue:
        return 'Atrasadas';
    }
  }
}

extension DateRangeFilterExtension on DateRangeFilter {
  String get label {
    switch (this) {
      case DateRangeFilter.all:
        return 'Todas as datas';
      case DateRangeFilter.today:
        return 'Hoje';
      case DateRangeFilter.thisWeek:
        return 'Esta semana';
      case DateRangeFilter.thisMonth:
        return 'Este mês';
      case DateRangeFilter.custom:
        return 'Personalizado';
    }
  }
}
