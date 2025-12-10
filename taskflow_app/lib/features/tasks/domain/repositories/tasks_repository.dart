import '../entities/task.dart';

/// Interface de repositório para a entidade Task.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade Task possui métodos de conversão robustos
///   (ex: aceitar id como int ou string, datas como DateTime ou String).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode)
///   nos métodos principais para facilitar o diagnóstico de problemas de cache,
///   conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está
///   "mounted" antes de chamar setState, evitando exceções de widget desmontado.
/// - Consulte os arquivos de debug do projeto para exemplos de logs, prints
///   e soluções de problemas reais.
abstract class TasksRepository {
  /// Carrega tarefas do cache local para renderização rápida inicial.
  ///
  /// Este método deve ser usado para populuar a UI imediatamente,
  /// proporcionando feedback instantâneo ao usuário mesmo sem conexão.
  /// Após carregar do cache, você pode disparar um sync em background.
  ///
  /// Boas práticas:
  /// - Use este método para render inicial rápido (offline-first)
  /// - Não bloqueie a UI aguardando sincronização remota
  /// - Trate erros de cache corrompido retornando lista vazia
  Future<List<Task>> loadFromCache();

  /// Sincronização incremental com o servidor.
  ///
  /// Busca apenas registros alterados desde a última sincronização (>= lastSync),
  /// aplica as mudanças localmente e atualiza o marcador de última sincronização.
  ///
  /// Retorna a quantidade de registros que foram alterados/aplicados.
  ///
  /// Boas práticas:
  /// - Execute em background após loadFromCache() para não bloquear a UI
  /// - Use timestamps do servidor (updated_at) para controle incremental
  /// - Registre logs de quantos itens foram sincronizados para debug
  /// - Em caso de erro, não limpe o cache; mantenha dados locais seguros
  Future<int> syncFromServer();

  /// Lista todas as tarefas (normalmente do cache após sincronização).
  ///
  /// Este método retorna a lista completa de tarefas disponíveis localmente.
  /// É ideal para telas de listagem principal.
  ///
  /// Boas práticas:
  /// - Leia sempre do cache local (rápido)
  /// - Se precisar de dados frescos, chame syncFromServer() antes
  /// - Aplique filtros e ordenação na camada de apresentação/use case
  Future<List<Task>> listAll();

  /// Lista tarefas em destaque/favoritas (filtradas do cache).
  ///
  /// Retorna apenas tarefas marcadas como featured, pinned ou favoritas.
  /// Útil para dashboards e telas de visão rápida.
  ///
  /// Boas práticas:
  /// - Implemente este filtro eficientemente no cache local
  /// - Considere adicionar índices se usar banco local (SQLite)
  /// - Mantenha sincronizado com listAll() para consistência
  Future<List<Task>> listFeatured();

  /// Busca uma tarefa específica por ID no cache local.
  ///
  /// Retorna a tarefa se encontrada, ou null caso contrário.
  /// Ideal para telas de detalhes e edição.
  ///
  /// Boas práticas:
  /// - Busque sempre no cache local (rápido)
  /// - Se o item não existir, considere fazer sync antes de retornar null
  /// - Valide se o ID é válido antes de buscar (não vazio, formato correto)
  Future<Task?> getById(String id);

  /// Cria uma nova tarefa localmente e opcionalmente a envia ao servidor.
  ///
  /// Adiciona a tarefa ao cache local e retorna a instância criada.
  /// Dependendo da implementação, pode enviar ao servidor imediatamente
  /// ou marcar para sincronização posterior.
  ///
  /// Boas práticas:
  /// - Gere IDs únicos localmente (UUID) se offline
  /// - Persista no cache antes de tentar enviar ao servidor (optimistic update)
  /// - Em caso de falha no servidor, mantenha no cache com flag "pending sync"
  Future<Task> createTask(Task task);

  /// Atualiza uma tarefa existente localmente e opcionalmente no servidor.
  ///
  /// Atualiza o cache local e retorna a tarefa atualizada.
  ///
  /// Boas práticas:
  /// - Atualize o timestamp updated_at localmente
  /// - Persista no cache antes de tentar enviar ao servidor
  /// - Trate conflitos (se servidor tiver versão mais recente)
  Future<Task> updateTask(Task task);

  /// Remove uma tarefa por ID (localmente e opcionalmente do servidor).
  ///
  /// Remove a tarefa do cache local.
  ///
  /// Boas práticas:
  /// - Considere soft delete (marcar como deletado) ao invés de hard delete
  /// - Se falhar no servidor, mantenha flag local "pending deletion"
  /// - Ofereça opção de desfazer (undo) na UI
  Future<void> deleteTask(String taskId);

  /// Limpa todo o cache local de tarefas.
  ///
  /// Útil para logout, reset de dados ou troubleshooting.
  ///
  /// ⚠️ CUIDADO: Esta operação é destrutiva e irreversível.
  ///
  /// Boas práticas:
  /// - Use apenas em casos específicos (logout, debug, reset)
  /// - Considere fazer sync antes de limpar (push pendentes)
  /// - Mostre confirmação ao usuário antes de executar
  Future<void> clearAllTasks();

  /// Força sincronização completa (full sync) de todas as tarefas.
  ///
  /// Ao contrário de syncFromServer() que é incremental, este método
  /// busca todos os registros do servidor independente do lastSync.
  ///
  /// Boas práticas:
  /// - Use apenas quando necessário (primeiro sync, reset, problemas)
  /// - Mostre indicador de progresso (pode ser demorado)
  /// - Implemente paginação se houver muitos registros
  Future<void> forceSyncAll();
}

/*
// Exemplo de uso:
final repo = TasksRepositoryImpl(
  remoteApi: SupabaseTasksRemoteDatasource(),
  localDao: TasksLocalDaoSharedPrefs(),
);

// Padrão offline-first recomendado:
void loadTasks() async {
  // 1. Carrega cache para UI rápida
  final cached = await repo.loadFromCache();
  setState(() => tasks = cached);
  
  // 2. Sincroniza em background
  final changed = await repo.syncFromServer();
  if (changed > 0) {
    // 3. Recarrega cache se houver mudanças
    final updated = await repo.loadFromCache();
    setState(() => tasks = updated);
  }
}

// Dica: implemente esta interface usando um DAO local e um datasource remoto.
// Para testes, crie um mock que retorna dados fixos.

// Checklist de erros comuns e como evitar:
// ❌ Não verificar se widget está mounted antes de setState
//    ✅ Sempre use: if (mounted) setState(...)
// 
// ❌ Bloquear UI aguardando sync remoto
//    ✅ Carregue cache primeiro, sync depois em background
// 
// ❌ Não tratar erros de parsing de datas/tipos
//    ✅ Use DateTime.tryParse(), toInt() com fallback, null safety
// 
// ❌ Não adicionar logs para debug
//    ✅ Use if (kDebugMode) print('TasksRepo: synced $n items')
// 
// ❌ Perder dados locais em caso de erro de sync
//    ✅ Nunca limpe cache em caso de erro; mantenha dados seguros
// 
// ❌ Não validar entidades antes de persistir
//    ✅ Use validações da Entity (ArgumentError) para dados inválidos
// 
// 📚 Referências úteis:
// - providers_cache_debug_prompt.md: exemplos de logs e debug de cache
// - supabase_init_debug_prompt.md: problemas comuns de inicialização
// - supabase_rls_remediation.md: como lidar com erros de permissão RLS
*/
