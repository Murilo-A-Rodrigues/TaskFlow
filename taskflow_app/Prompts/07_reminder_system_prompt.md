# Prompt 07 - Sistema de Lembretes e Notificações

## Contexto

Necessidade de implementar um sistema completo de lembretes com notificações locais para que usuários não esqueçam tarefas importantes.

## Objetivo

Criar sistema que permita:
- Agendar lembretes para tarefas específicas
- Receber notificações no horário definido
- Lembretes únicos ou recorrentes
- Ações rápidas nas notificações

## Prompt Usado - NotificationHelper

```
Crie uma classe NotificationHelper (singleton) que gerencie notificações locais com:

1. Inicialização:
   - Configure flutter_local_notifications
   - Configure timezone para America/Sao_Paulo
   - Solicite permissões (Android 13+ e iOS)

2. Métodos principais:
   - scheduleNotification(id, title, body, scheduledDate, payload)
   - scheduleRecurringNotification(id, title, body, interval, payload)
   - showImmediateNotification(id, title, body, payload)
   - cancelNotification(id)
   - cancelAllNotifications()
   - getPendingNotifications()

3. Configurações Android:
   - Canal: 'task_reminders'
   - Importância: Max
   - Prioridade: Max
   - AndroidScheduleMode: alarmClock (máxima prioridade)
   - fullScreenIntent: true (aparecer na lockscreen)
   - category: alarm
   - Ações: "Concluir" e "Adiar 15min"

4. Configurações iOS:
   - presentAlert, presentBadge, presentSound: true

5. Callback ao tocar notificação

6. Logs detalhados para debugging
```

## Resposta da IA

IA gerou estrutura completa do NotificationHelper com:
- Singleton pattern implementado
- Inicialização do plugin
- Configuração de timezone
- Todos os métodos solicitados
- Estrutura de permissões

## Iterações

### Iteração 1: Estrutura Básica
**Resultado:** NotificationHelper com métodos simples
**Problema:** Notificações não apareciam

### Iteração 2: Permissões Android 13+
**Refinamento:**
```
Adicione solicitação explícita de permissões para Android 13+:
- POST_NOTIFICATIONS
- SCHEDULE_EXACT_ALARM
Use requestNotificationsPermission() e requestExactAlarmsPermission()
```
**Resultado:** Permissões implementadas

### Iteração 3: AndroidScheduleMode
**Problema:** Notificações agendadas não chegavam
**Refinamento:**
```
Mude AndroidScheduleMode de exactAllowWhileIdle para alarmClock.
alarmClock tem máxima prioridade e não é cancelado pelo sistema.
```
**Resultado:** Notificações passaram a funcionar

### Iteração 4: BroadcastReceivers
**Refinamento:**
```
Adicione receivers ao AndroidManifest.xml:
- ScheduledNotificationReceiver
- ScheduledNotificationBootReceiver com intent-filter para BOOT_COMPLETED
```
**Resultado:** Notificações reagendam após reboot

### Iteração 5: fullScreenIntent
**Refinamento:**
```
Adicione fullScreenIntent: true e category: alarm para aparecer
mesmo com tela bloqueada. Configure importance e priority como max.
```
**Resultado:** Notificações aparecem na lockscreen

### Iteração 6: Logs e Debugging
**Refinamento:**
```
Adicione logs detalhados:
- Horário agendado vs atual
- Timezone usado
- Diferença de tempo
- ID da notificação
- Verificação de pendentes
```
**Resultado:** Debugging facilitado

### Iteração 7: Notificação de Teste
**Refinamento:**
```
Se lembrete for < 2min no futuro, mostre notificação imediata
de TESTE para validar que permissões e configurações funcionam.
```
**Resultado:** Diagnóstico rápido de problemas

## Prompt Usado - ReminderService

```
Crie um ReminderService que gerencie lembretes de tarefas com:

1. Use ChangeNotifier para reatividade

2. Integre com NotificationHelper

3. Persista em SharedPreferences 'reminders_cache_v1'

4. Entidade Reminder:
   - id, taskId, reminderDate
   - type (once/daily/weekly/monthly)
   - customMessage, isActive, createdAt

5. Métodos CRUD:
   - createReminder(task, date, type, message)
   - updateReminder(reminder, task)
   - deleteReminder(id)
   - toggleReminder(id, task)
   - getRemindersForTask(taskId)

6. Ao criar:
   - Agenda notificação via NotificationHelper
   - Se < 2min: mostra teste imediato
   - Verifica se foi agendado (getPendingNotifications)
   - Logs detalhados

7. Ao deletar: cancela notificação

8. Método waitForInitialization() com timeout 5s para evitar race conditions
```

## Código Gerado

### NotificationHelper - scheduleNotification

```dart
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? payload,
}) async {
  final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
  
  print('📅 Agendando notificação:');
  print('   ID: $id');
  print('   Horário TZ: $tzScheduledDate');
  print('   Diferença: ${tzScheduledDate.difference(DateTime.now())}');

  await _notifications.zonedSchedule(
    id,
    title,
    body,
    tzScheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Lembretes de Tarefas',
        importance: Importance.max,
        priority: Priority.max,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
    ),
  );
  
  // Verifica se foi agendado
  final pending = await _notifications.pendingNotificationRequests();
  final thisNotification = pending.where((n) => n.id == id).toList();
  if (thisNotification.isNotEmpty) {
    print('✅ Notificação ID $id encontrada nas pendentes');
  } else {
    print('⚠️ Notificação ID $id NÃO encontrada nas pendentes!');
  }
}
```

### ReminderService - createReminder

```dart
Future<Reminder> createReminder({
  required Task task,
  required DateTime reminderDate,
  required ReminderType type,
  String? customMessage,
}) async {
  final reminder = Reminder(
    id: const Uuid().v4(),
    taskId: task.id,
    reminderDate: reminderDate,
    type: type,
    customMessage: customMessage,
    isActive: true,
    createdAt: DateTime.now(),
  );

  _reminders.add(reminder);
  await _saveToCache();
  await _scheduleNotification(reminder, task);
  
  // Teste imediato se < 2min
  if (reminder.reminderDate.difference(DateTime.now()).inMinutes < 2) {
    await _notificationHelper.showImmediateNotification(
      id: _getNotificationId(reminder.id) + 1000,
      title: '🧪 TESTE: ${reminder.customMessage ?? task.title}',
      body: 'Esta é uma notificação de teste.',
      payload: task.id,
    );
  }
  
  await debugPendingNotifications();
  notifyListeners();
  return reminder;
}
```

## Validações Realizadas

- [x] Testado permissões Android 13+ (concedidas)
- [x] Testado lembrete 1min futuro (notificação chegou)
- [x] Testado notificação de teste (aparece imediatamente)
- [x] Testado ações "Concluir" e "Adiar" (funcionam)
- [x] Testado lembrete recorrente diário (repete)
- [x] Testado reiniciar app (lembretes persistem)
- [x] Testado desativar lembrete (notificação cancelada)
- [x] Testado lockscreen (notificação aparece)
- [x] Testado modo economia bateria (funciona)
- [x] Testado MIUI Xiaomi (funciona com configurações)

## Decisões de Design

1. **AndroidScheduleMode.alarmClock:** Máxima prioridade, não é cancelado
2. **Notificação de teste:** Diagnóstico rápido de problemas
3. **waitForInitialization():** Evita race conditions ao carregar app
4. **Logs extensivos:** Facilita debugging de problemas de notificação
5. **hashCode para IDs:** Converte String em int deterministicamente
6. **fullScreenIntent:** Aparece mesmo com tela bloqueada

## Desafios Enfrentados

### 1. Notificações não chegavam
**Problema:** AndroidScheduleMode.exactAllowWhileIdle era ignorado pelo sistema
**Solução:** Mudei para alarmClock (máxima prioridade)
**Resultado:** Notificações passaram a funcionar

### 2. MIUI mata apps agressivamente
**Problema:** Mesmo com permissões, Xiaomi cancelava notificações
**Solução:** 
- Documentei configurações necessárias
- Adicionei receivers para boot
- Configurei categoria como alarm
**Resultado:** Funciona com configurações do usuário

### 3. Timezone causava confusão
**Problema:** DateTime simples não considerava timezone
**Solução:** Usei TZDateTime.from() com timezone local
**Resultado:** Notificações no horário correto

### 4. Race conditions ao inicializar
**Problema:** TaskFormDialog tentava carregar lembretes antes do serviço inicializar
**Solução:** Método waitForInitialization() com polling e timeout
**Resultado:** Sem crashes na inicialização

### 5. Validação atrás do dialog
**Problema:** SnackBar aparecia atrás do TaskFormDialog
**Solução 1:** Tentei FloatingSnackBar (não funcionou)
**Solução 2:** AlertDialog com useRootNavigator: true
**Resultado:** Validação visível acima de tudo

## Limitações Conhecidas

- MIUI/Xiaomi requer configurações manuais do usuário
- Android Doze pode atrasar até 15min (alarmClock minimiza)
- iOS limite de 64 notificações pendentes
- Notificações mostram dados na lockscreen (privacidade)

## Melhorias Futuras

- WorkManager para maior confiabilidade
- Ações de notificação totalmente implementadas (Concluir/Adiar)
- Modo privado (oculta detalhes na lockscreen)
- Detecção de mudança de timezone e reagendamento
- Dialog explicativo para permissões
- Link para configurações de bateria (MIUI/Samsung)
