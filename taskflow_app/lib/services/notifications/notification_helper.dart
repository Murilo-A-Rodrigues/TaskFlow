import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// NotificationHelper - Configuração e gerenciamento de notificações locais
///
/// Responsável por:
/// - Inicializar plugin de notificações
/// - Agendar notificações
/// - Cancelar notificações
/// - Configurar ações de notificação
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializa o sistema de notificações
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializa timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configuração para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configuração para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuração geral
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializa
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('✅ NotificationHelper inicializado');
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notificação tocada: ${response.payload}');
    // TODO: Navegar para tela específica da tarefa
  }

  /// Solicita permissão para notificações (iOS e Android 13+)
  Future<bool> requestPermission() async {
    // Android 13+ precisa solicitar permissão em runtime
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      print('🔔 Solicitando permissão de notificação (Android)...');
      final granted = await androidPlugin.requestNotificationsPermission();
      print('🔔 Permissão concedida: $granted');

      // Solicita permissão para alarmes exatos (Android 12+)
      final exactAlarmGranted = await androidPlugin
          .requestExactAlarmsPermission();
      print('⏰ Permissão para alarmes exatos: $exactAlarmGranted');

      return granted ?? false;
    }

    // iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      print('🔔 Solicitando permissão de notificação (iOS)...');
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🔔 Permissão concedida: $granted');
      return granted ?? false;
    }

    // Outras plataformas
    return true;
  }

  /// Agenda uma notificação para um horário específico
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    print('📅 Agendando notificação:');
    print('   ID: $id');
    print('   Horário solicitado: $scheduledDate');
    print('   Horário TZ: $tzScheduledDate');
    print('   Diferença: ${tzScheduledDate.difference(DateTime.now())}');
    print('   Timezone: ${tz.local.name}');

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Lembretes de Tarefas',
            channelDescription: 'Notificações de lembretes para suas tarefas',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            actions: [
              AndroidNotificationAction(
                'complete',
                'Concluir',
                showsUserInterface: true,
              ),
              AndroidNotificationAction('snooze', 'Adiar 15min'),
            ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('✅ Notificação agendada com sucesso!');

      // Verifica se foi realmente agendada
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Total de notificações pendentes: ${pending.length}');
      final thisNotification = pending.where((n) => n.id == id).toList();
      if (thisNotification.isNotEmpty) {
        print('✅ Notificação ID $id encontrada nas pendentes');
      } else {
        print('⚠️ Notificação ID $id NÃO encontrada nas pendentes!');
      }
    } catch (e) {
      print('❌ Erro ao agendar notificação: $e');
      rethrow;
    }
  }

  /// Agenda notificação recorrente
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval interval,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      interval,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Lembretes de Tarefas',
          channelDescription: 'Notificações de lembretes para suas tarefas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    print('🔔 Notificação recorrente agendada');
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('❌ Notificação cancelada: $id');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('❌ Todas notificações canceladas');
  }

  /// Lista notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Mostra notificação imediata
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Lembretes de Tarefas',
          channelDescription: 'Notificações de lembretes para suas tarefas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );

    print('🔔 Notificação imediata exibida');
  }
}
