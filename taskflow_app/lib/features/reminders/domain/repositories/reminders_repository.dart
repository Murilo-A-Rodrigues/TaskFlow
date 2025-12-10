import '../../../app/domain/entities/reminder.dart';

/// Interface de repositório para a entidade Reminder.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade Reminder possui métodos de conversão robustos
///   (ex: aceitar id como int ou string, datas como DateTime ou String).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode)
///   nos métodos principais para facilitar o diagnóstico de problemas de cache,
///   conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está
///   "mounted" antes de chamar setState, evitando exceções de widget desmontado.
/// - Consulte os arquivos de debug do projeto para exemplos de logs, prints
///   e soluções de problemas reais.
abstract class RemindersRepository {
  /// Carrega lembretes do cache local para renderização rápida inicial.
  ///
  /// Este método deve ser usado para popular a UI imediatamente,
  /// proporcionando feedback instantâneo ao usuário mesmo sem conexão.
  /// Após carregar do cache, você pode disparar um sync em background.
  ///
  /// Boas práticas:
  /// - Use este método para render inicial rápido (offline-first)
  /// - Não bloqueie a UI aguardando sincronização remota
  /// - Trate erros de cache corrompido retornando lista vazia
  Future<List<Reminder>> loadFromCache();

  /// Sincronização incremental com o servidor.
  ///
  /// Busca apenas registros alterados desde a última sincronização (>= lastSync),
  /// aplica as mudanças localmente e atualiza o marcador de última sincronização.
  ///
  /// Retorna a quantidade de registros que foram alterados/aplicados.
  ///
  /// Boas práticas:
  /// - Execute em background após loadFromCache() para não bloquear a UI
  /// - Use timestamps do servidor (created_at) para controle incremental
  /// - Registre logs de quantos itens foram sincronizados para debug
  /// - Em caso de erro, não limpe o cache; mantenha dados locais seguros
  Future<int> syncFromServer();

  /// Lista todos os lembretes (normalmente do cache após sincronização).
  ///
  /// Este método retorna a lista completa de lembretes disponíveis localmente.
  /// É ideal para telas de listagem principal.
  ///
  /// Boas práticas:
  /// - Use após loadFromCache() para garantir dados atualizados
  /// - Retorna sempre uma lista (nunca null) para facilitar uso na UI
  Future<List<Reminder>> listAll();

  /// Lista apenas lembretes ativos.
  ///
  /// Filtra lembretes com isActive = true, útil para exibir
  /// apenas lembretes que estão em vigor.
  ///
  /// Boas práticas:
  /// - Use este método para telas de lembretes ativos
  /// - Considere também filtrar por datas futuras conforme necessário
  Future<List<Reminder>> listActive();

  /// Lista lembretes de uma tarefa específica.
  ///
  /// Filtra lembretes pelo taskId fornecido.
  /// Útil para exibir lembretes na tela de detalhes de uma tarefa.
  ///
  /// Parâmetros:
  /// - [taskId]: ID da tarefa para filtrar lembretes
  ///
  /// Boas práticas:
  /// - Retorne lista vazia se não houver lembretes para a tarefa
  /// - Considere ordenar por reminder_date para melhor UX
  Future<List<Reminder>> listByTaskId(String taskId);

  /// Busca um lembrete específico por ID.
  ///
  /// Retorna o lembrete encontrado ou null se não existir.
  ///
  /// Parâmetros:
  /// - [id]: ID único do lembrete
  ///
  /// Boas práticas:
  /// - Retorne null de forma consistente (não lance exception)
  /// - Use para operações de detalhes ou verificação de existência
  Future<Reminder?> getById(String id);

  /// Cria um novo lembrete.
  ///
  /// Salva o lembrete no cache local e tenta enviar ao servidor.
  /// Se a sincronização remota falhar, o lembrete fica apenas local
  /// até a próxima sincronização.
  ///
  /// Parâmetros:
  /// - [reminder]: entidade Reminder a ser criada
  ///
  /// Retorna o lembrete criado (pode ter campos atualizados).
  ///
  /// Boas práticas:
  /// - Gere ID único antes de criar (UUID)
  /// - Defina created_at como DateTime.now()
  /// - Use optimistic update: salve local primeiro, sync depois
  /// - Não falhe a operação se o envio remoto falhar
  Future<Reminder> createReminder(Reminder reminder);

  /// Atualiza um lembrete existente.
  ///
  /// Atualiza o lembrete no cache local e tenta enviar ao servidor.
  ///
  /// Parâmetros:
  /// - [reminder]: entidade Reminder com dados atualizados
  ///
  /// Retorna o lembrete atualizado.
  ///
  /// Boas práticas:
  /// - Verifique se o lembrete existe antes de atualizar
  /// - Use optimistic update para melhor UX
  /// - Mantenha created_at original, não sobrescreva
  Future<Reminder> updateReminder(Reminder reminder);

  /// Remove um lembrete.
  ///
  /// Remove o lembrete do cache local e tenta remover do servidor.
  ///
  /// Parâmetros:
  /// - [id]: ID do lembrete a ser removido
  ///
  /// Boas práticas:
  /// - Considere implementar soft delete (marcar is_active = false)
  /// - Não falhe se o lembrete não existir (operação idempotente)
  /// - Use optimistic update: remova local primeiro
  Future<void> deleteReminder(String id);

  /// Limpa todo o cache de lembretes.
  ///
  /// ⚠️ ATENÇÃO: Esta operação é destrutiva e remove todos os dados locais.
  /// Use apenas para logout, reset completo ou casos específicos.
  ///
  /// Boas práticas:
  /// - Confirme com usuário antes de executar
  /// - Não sincronize com servidor (apenas limpa local)
  /// - Use para casos de reset ou troubleshooting
  Future<void> clearAllReminders();

  /// Força sincronização completa (full sync) com o servidor.
  ///
  /// Ignora lastSync e busca todos os lembretes do servidor,
  /// substituindo o cache local completamente.
  ///
  /// Retorna quantidade de lembretes sincronizados.
  ///
  /// Boas práticas:
  /// - Use para resolver inconsistências ou após limpar cache
  /// - Mostre indicador de carregamento (pode demorar)
  /// - Não use frequentemente; prefira syncFromServer() incremental
  Future<int> forceSyncAll();
}

/*
// Exemplo de uso:

final repository = RemindersRepositoryImpl(...);

// 1. Carregamento inicial (offline-first)
final cached = await repository.loadFromCache();
setState(() => reminders = cached);

// 2. Sincronização em background
repository.syncFromServer().then((count) {
  print('Sincronizados $count lembretes');
  // Recarrega para refletir mudanças
  repository.listAll().then((updated) {
    if (mounted) setState(() => reminders = updated);
  });
});

// 3. Criar novo lembrete
final newReminder = Reminder(
  id: Uuid().v4(),
  taskId: 'task_123',
  reminderDate: DateTime.now().add(Duration(days: 1)),
  type: ReminderType.once,
  isActive: true,
  createdAt: DateTime.now(),
);
await repository.createReminder(newReminder);

// 4. Listar lembretes de uma tarefa
final taskReminders = await repository.listByTaskId('task_123');
print('Tarefa tem ${taskReminders.length} lembretes');

// 5. Atualizar lembrete
final updated = reminder.copyWith(isActive: false);
await repository.updateReminder(updated);

// 6. Remover lembrete
await repository.deleteReminder('rem_456');
*/
