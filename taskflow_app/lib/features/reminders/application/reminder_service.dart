import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app/domain/entities/reminder.dart';
import '../../tasks/domain/entities/task.dart';
import '../../../services/notifications/notification_helper.dart';
import '../infrastructure/remote/supabase_reminders_remote_datasource.dart';
import '../../../services/core/supabase_service.dart';
import '../../app/infrastructure/mappers/reminder_mapper.dart';
import '../../auth/application/auth_service.dart';

/// ReminderService - Gerencia lembretes de tarefas
///
/// Responsabilidades:
/// - CRUD de lembretes
/// - Agendamento de notificações
/// - Persistência local de lembretes
/// - Gerenciamento de lembretes recorrentes
class ReminderService extends ChangeNotifier {
  static const String _cacheKey = 'reminders_cache_v1';

  final NotificationHelper _notificationHelper;
  final AuthService _authService;
  late final SupabaseRemindersRemoteDatasource? _remoteApi;
  final List<Reminder> _reminders = [];
  bool _isInitialized = false;

  ReminderService(this._notificationHelper, this._authService) {
    try {
      _remoteApi = SupabaseRemindersRemoteDatasource(client: SupabaseService.client);
      if (kDebugMode) {
        print('✅ ReminderService: Remote datasource inicializado com sucesso');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ ReminderService: Erro ao inicializar Supabase - modo offline');
        print('   Erro: $e');
        print('   Stack: $stack');
      }
      _remoteApi = null;
    }
    _initializeReminders();
  }

  // Getters
  List<Reminder> get reminders => List.unmodifiable(_reminders);
  bool get isInitialized => _isInitialized;

  /// Aguarda até que o serviço seja inicializado
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    // Aguarda até 5 segundos pela inicialização
    int attempts = 0;
    while (!_isInitialized && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  /// Inicializa o serviço
  Future<void> _initializeReminders() async {
    try {
      print('🔔 Inicializando ReminderService...');

      // Inicializa notificações
      await _notificationHelper.initialize();
      await _notificationHelper.requestPermission();

      // Carrega lembretes do cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);

      if (cached != null) {
        final List<dynamic> jsonList = json.decode(cached);
        _reminders.clear();
        _reminders.addAll(
          jsonList.map((json) => Reminder.fromMap(json)).toList(),
        );
      }

      print(
        '✅ ReminderService inicializado com ${_reminders.length} lembretes',
      );
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao inicializar ReminderService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Cria um novo lembrete
  Future<Reminder> createReminder({
    required Task task,
    required DateTime reminderDate,
    required ReminderType type,
    String? customMessage,
  }) async {
    try {
      // Obtém o userId do usuário autenticado
      final userId = _authService.userId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final reminder = Reminder(
        id: const Uuid().v4(),
        taskId: task.id,
        userId: userId,
        reminderDate: reminderDate,
        type: type,
        createdAt: DateTime.now(),
        customMessage: customMessage,
      );

      // Adiciona à lista
      _reminders.add(reminder);
      await _saveToCache();

      // Agenda notificação
      print('📅 Agendando notificação para: ${reminder.reminderDate}');
      print('⏰ Tempo atual: ${DateTime.now()}');
      print(
        '⏱️ Diferença: ${reminder.reminderDate.difference(DateTime.now())}',
      );

      await _scheduleNotification(reminder, task);

      print('✅ Lembrete criado: ${reminder.id}');
      print('📱 ID da notificação: ${_getNotificationId(reminder.id)}');

      // Tenta sincronizar com Supabase
      if (_remoteApi != null) {
        try {
          if (kDebugMode) print('📤 Sincronizando lembrete com Supabase...');
          final dto = ReminderMapper.toDto(reminder);
          if (kDebugMode) print('   DTO: ${dto.toMap()}');
          
          // Verifica se não é modo convidado
          final currentUserId = SupabaseService.currentUserId;
          if (currentUserId != null && 
              currentUserId != '00000000-0000-0000-0000-000000000000') {
            await _remoteApi.upsertReminders([dto]);
            if (kDebugMode) print('✅ Lembrete sincronizado com Supabase');
          } else {
            if (kDebugMode) print('⚠️ Modo convidado - lembrete não sincronizado');
          }
        } catch (syncError, stack) {
          if (kDebugMode) {
            print('❌ Erro ao sincronizar lembrete com Supabase:');
            print('   $syncError');
            print('   Stack: $stack');
          }
        }
      } else {
        if (kDebugMode) print('⚠️ Modo offline - lembrete não sincronizado');
      }

      // Debug: Lista todas as notificações pendentes
      await debugPendingNotifications();

      notifyListeners();
      return reminder;
    } catch (e) {
      print('❌ Erro ao criar lembrete: $e');
      rethrow;
    }
  }

  /// Atualiza um lembrete existente
  Future<void> updateReminder(Reminder updatedReminder, Task task) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
      if (index == -1) {
        throw Exception('Lembrete não encontrado');
      }

      // Cancela notificação antiga
      await _notificationHelper.cancelNotification(
        _getNotificationId(updatedReminder.id),
      );

      // Atualiza na lista
      _reminders[index] = updatedReminder;
      await _saveToCache();

      // Reagenda notificação
      if (updatedReminder.isActive) {
        await _scheduleNotification(updatedReminder, task);
      }

      print('✅ Lembrete atualizado: ${updatedReminder.id}');

      // Tenta sincronizar com Supabase
      if (_remoteApi != null) {
        try {
          if (kDebugMode) print('📤 Sincronizando lembrete atualizado com Supabase...');
          final dto = ReminderMapper.toDto(updatedReminder);
          
          // Verifica se não é modo convidado
          final currentUserId = SupabaseService.currentUserId;
          if (currentUserId != null && 
              currentUserId != '00000000-0000-0000-0000-000000000000') {
            await _remoteApi.upsertReminders([dto]);
            if (kDebugMode) print('✅ Lembrete atualizado sincronizado com Supabase');
          } else {
            if (kDebugMode) print('⚠️ Modo convidado - lembrete não sincronizado');
          }
        } catch (syncError, stack) {
          if (kDebugMode) {
            print('❌ Erro ao sincronizar lembrete com Supabase:');
            print('   $syncError');
            print('   Stack: $stack');
          }
        }
      } else {
        if (kDebugMode) print('⚠️ Modo offline - lembrete não sincronizado');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Erro ao atualizar lembrete: $e');
      rethrow;
    }
  }

  /// Remove um lembrete
  Future<void> deleteReminder(String reminderId) async {
    try {
      // Cancela notificação
      await _notificationHelper.cancelNotification(
        _getNotificationId(reminderId),
      );

      // Remove da lista
      _reminders.removeWhere((r) => r.id == reminderId);
      await _saveToCache();

      print('✅ Lembrete removido: $reminderId');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao remover lembrete: $e');
      rethrow;
    }
  }

  /// Remove todos os lembretes de uma tarefa
  Future<void> deleteRemindersByTask(String taskId) async {
    try {
      final taskReminders = _reminders
          .where((r) => r.taskId == taskId)
          .toList();

      for (final reminder in taskReminders) {
        await _notificationHelper.cancelNotification(
          _getNotificationId(reminder.id),
        );
      }

      _reminders.removeWhere((r) => r.taskId == taskId);
      await _saveToCache();

      print('✅ Lembretes da tarefa removidos: $taskId');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao remover lembretes da tarefa: $e');
      rethrow;
    }
  }

  /// Ativa/desativa um lembrete
  Future<void> toggleReminder(String reminderId, Task task) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index == -1) return;

      final reminder = _reminders[index];
      final updated = reminder.copyWith(isActive: !reminder.isActive);

      _reminders[index] = updated;
      await _saveToCache();

      if (updated.isActive) {
        await _scheduleNotification(updated, task);
      } else {
        await _notificationHelper.cancelNotification(
          _getNotificationId(reminderId),
        );
      }

      print(
        '✅ Lembrete ${updated.isActive ? "ativado" : "desativado"}: $reminderId',
      );
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao alternar lembrete: $e');
      rethrow;
    }
  }

  /// Retorna lembretes de uma tarefa específica
  List<Reminder> getRemindersForTask(String taskId) {
    return _reminders.where((r) => r.taskId == taskId).toList();
  }

  /// Agenda notificação para um lembrete
  Future<void> _scheduleNotification(Reminder reminder, Task task) async {
    final notificationId = _getNotificationId(reminder.id);
    final title = reminder.customMessage ?? 'Lembrete: ${task.title}';
    final body = task.description.isEmpty
        ? 'Você tem uma tarefa pendente'
        : task.description;

    switch (reminder.type) {
      case ReminderType.once:
        await _notificationHelper.scheduleNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: reminder.reminderDate,
          payload: task.id,
        );
        break;

      case ReminderType.daily:
        await _notificationHelper.scheduleRecurringNotification(
          id: notificationId,
          title: title,
          body: body,
          interval: RepeatInterval.daily,
          payload: task.id,
        );
        break;

      case ReminderType.weekly:
        await _notificationHelper.scheduleRecurringNotification(
          id: notificationId,
          title: title,
          body: body,
          interval: RepeatInterval.weekly,
          payload: task.id,
        );
        break;

      case ReminderType.monthly:
        // Nota: flutter_local_notifications não tem RepeatInterval.monthly nativo
        // Usamos weekly como aproximação (implementação básica)
        await _notificationHelper.scheduleRecurringNotification(
          id: notificationId,
          title: title,
          body: body,
          interval: RepeatInterval.weekly,
          payload: task.id,
        );
        break;
    }
  }

  /// Converte ID do lembrete em ID de notificação (inteiro)
  int _getNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 2147483647;
  }

  /// Salva lembretes no cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _reminders.map((r) => r.toMap()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      print('💾 Lembretes salvos no cache');
    } catch (e) {
      print('❌ Erro ao salvar lembretes no cache: $e');
    }
  }

  /// Limpa todos os lembretes (útil para debug)
  Future<void> clearAll() async {
    await _notificationHelper.cancelAllNotifications();
    _reminders.clear();
    await _saveToCache();
    print('🗑️ Todos os lembretes removidos');
    notifyListeners();
  }

  /// Debug: Lista todas as notificações pendentes
  Future<void> debugPendingNotifications() async {
    final pending = await _notificationHelper.getPendingNotifications();
    print('📋 === NOTIFICAÇÕES PENDENTES ===');
    print('📋 Total: ${pending.length}');
    for (var notification in pending) {
      print('   ID: ${notification.id}');
      print('   Title: ${notification.title}');
      print('   Body: ${notification.body}');
      print('   ---');
    }
    print('📋 === FIM DA LISTA ===');
  }
}
