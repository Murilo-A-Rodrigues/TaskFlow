import '../../../app/infrastructure/dtos/reminder_dto.dart';

/// Interface para API remota de Reminders
/// 
/// Define o contrato para comunicação com o backend (Supabase).
/// Implementações concretas devem lidar com autenticação, paginação,
/// tratamento de erros e conversão de dados.
abstract class RemindersRemoteApi {
  /// Busca lembretes do servidor com filtro opcional de data
  /// 
  /// Parâmetros:
  /// - [since]: timestamp opcional para sincronização incremental.
  ///   Se fornecido, retorna apenas lembretes com created_at >= since.
  /// - [cursor]: cursor de paginação para continuar de onde parou
  /// - [limit]: quantidade máxima de registros por página (padrão 100)
  /// 
  /// Retorna uma página de resultados com cursor para próxima página.
  /// 
  /// Boas práticas:
  /// - Sempre ordene por created_at para sincronização consistente
  /// - Use paginação para evitar timeouts em grandes volumes
  /// - Trate erros de rede retornando página vazia ao invés de exception
  Future<RemotePage<ReminderDto>> fetchReminders({
    DateTime? since,
    PageCursor? cursor,
    int limit = 100,
  });

  /// Envia lembretes para o servidor (create/update em lote)
  /// 
  /// Realiza upsert (insert or update) de múltiplos lembretes.
  /// 
  /// Retorna quantidade de registros processados pelo servidor.
  /// 
  /// Boas práticas:
  /// - Use upsert para evitar erros de duplicação
  /// - Envie em lotes de até 500 registros para melhor performance
  /// - Em caso de falha, não descarte os dados; retenha para retry
  Future<int> upsertReminders(List<ReminderDto> reminders);
}

/// Representa uma página de resultados de uma consulta paginada
class RemotePage<T> {
  /// Itens desta página
  final List<T> items;
  
  /// Cursor para buscar a próxima página (null se for a última)
  final PageCursor? next;

  const RemotePage({
    required this.items,
    this.next,
  });

  /// Verifica se há mais páginas disponíveis
  bool get hasMore => next != null;
}

/// Cursor para paginação
/// 
/// Pode ser baseado em offset, timestamp ou outro identificador
/// dependendo da implementação do backend.
class PageCursor {
  final dynamic value;

  const PageCursor(this.value);

  @override
  String toString() => 'PageCursor($value)';
}

/*
// Exemplo de uso:

final api = SupabaseRemindersRemoteDatasource();

// Buscar primeira página
var page = await api.fetchReminders(limit: 50);
print('Recebidos: ${page.items.length}');

// Buscar próxima página
while (page.hasMore) {
  page = await api.fetchReminders(cursor: page.next, limit: 50);
  print('Recebidos: ${page.items.length}');
}

// Sincronização incremental
final lastSync = DateTime(2024, 12, 1);
final delta = await api.fetchReminders(since: lastSync);
print('Mudanças desde $lastSync: ${delta.items.length}');

// Enviar lembretes para servidor
final sent = await api.upsertReminders([
  ReminderDto(...),
  ReminderDto(...),
]);
print('Enviados: $sent lembretes');
*/
