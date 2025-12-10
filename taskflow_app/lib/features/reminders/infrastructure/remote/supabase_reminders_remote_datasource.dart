import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/core/supabase_service.dart';
import '../../../app/infrastructure/dtos/reminder_dto.dart';
import 'reminders_remote_api.dart';

/// Implementação Supabase do datasource remoto de Reminders
///
/// Esta classe comunica com a tabela 'reminders' no Supabase para buscar
/// e enviar lembretes. Implementa paginação, sincronização incremental
/// e tratamento robusto de erros.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Garanta que o DTO e o Mapper aceitam múltiplos formatos vindos do backend
///   (ex: id como int/string, datas como DateTime/String)
/// - Sempre adicione prints/logs (usando kDebugMode) nos métodos de fetch/upsert
///   mostrando o conteúdo dos dados recebidos e convertidos
/// - Envolva parsing de datas, conversão de tipos e chamadas externas em try/catch,
///   logando o erro e retornando valores seguros
/// - Não exponha segredos (keys) em prints/logs
/// - Consulte os arquivos de debug do projeto para exemplos de logs e soluções
class SupabaseRemindersRemoteDatasource implements RemindersRemoteApi {
  final SupabaseClient client;

  /// Construtor com client opcional (fallback para SupabaseService global)
  SupabaseRemindersRemoteDatasource({SupabaseClient? client})
    : client = client ?? SupabaseService.client;

  @override
  Future<RemotePage<ReminderDto>> fetchReminders({
    DateTime? since,
    PageCursor? cursor,
    int limit = 100,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'SupabaseRemindersRemoteDatasource.fetchReminders: '
          'since=$since, cursor=$cursor, limit=$limit',
        );
      }

      // Inicia query na tabela reminders
      var query = client
          .from('reminders')
          .select('*')
          .order('created_at', ascending: false);

      // Aplica paginação por offset
      final offset = cursor?.value as int? ?? 0;
      query = query.range(offset, offset + limit - 1);

      // Executa query
      final response = await query;

      // Aplica filtro de sincronização incremental manualmente
      List<dynamic> filteredResponse = response;
      if (since != null) {
        filteredResponse = response.where((item) {
          final createdAt = DateTime.parse(item['created_at']);
          return createdAt.isAfter(since) || createdAt.isAtSameMomentAs(since);
        }).toList();

        if (kDebugMode) {
          print(
            'SupabaseRemindersRemoteDatasource.fetchReminders: '
            'Filtrados ${filteredResponse.length} de ${response.length} items após $since',
          );
        }
      }

      if (kDebugMode) {
        print(
          'SupabaseRemindersRemoteDatasource.fetchReminders: '
          'recebidos ${filteredResponse.length} registros',
        );
      }

      // Converte resposta para DTOs
      final List<ReminderDto> reminders = [];
      for (var row in filteredResponse) {
        try {
          final dto = ReminderDto.fromMap(row);
          reminders.add(dto);
        } catch (e) {
          // Log de erro de conversão mas continua processando outros registros
          if (kDebugMode) {
            print(
              'SupabaseRemindersRemoteDatasource.fetchReminders: '
              'erro ao converter registro: $e\nRow: $row',
            );
          }
        }
      }

      // Determina se há próxima página
      final hasMore = response.length == limit;
      final nextCursor = hasMore ? PageCursor(offset + limit) : null;

      return RemotePage<ReminderDto>(items: reminders, next: nextCursor);
    } catch (e, stackTrace) {
      // Log do erro mas retorna página vazia para não quebrar o fluxo
      if (kDebugMode) {
        print('SupabaseRemindersRemoteDatasource.fetchReminders ERROR: $e');
        print('Stack trace: $stackTrace');
      }

      return const RemotePage<ReminderDto>(items: []);
    }
  }

  @override
  Future<int> upsertReminders(List<ReminderDto> reminders) async {
    if (reminders.isEmpty) {
      return 0;
    }

    try {
      if (kDebugMode) {
        print(
          'SupabaseRemindersRemoteDatasource.upsertReminders: '
          'sending ${reminders.length} items',
        );
      }

      // Converte DTOs para Maps
      final List<Map<String, dynamic>> maps = reminders
          .map((dto) => dto.toMap())
          .toList();

      // Realiza upsert no Supabase
      final response = await client.from('reminders').upsert(maps).select();

      if (kDebugMode) {
        print(
          'SupabaseRemindersRemoteDatasource.upsertReminders: '
          'response length: ${response.length}',
        );
      }

      return response.length;
    } catch (e, stackTrace) {
      // Log do erro detalhado
      if (kDebugMode) {
        print('SupabaseRemindersRemoteDatasource.upsertReminders ERROR: $e');
        print('Stack trace: $stackTrace');
        print('Attempted to upsert ${reminders.length} reminders');
      }

      // Retorna 0 indicando que nenhum lembrete foi processado
      // Não lança exception para não quebrar o fluxo de sync
      return 0;
    }
  }
}

/*
// Exemplo de uso:

final datasource = SupabaseRemindersRemoteDatasource();

// Buscar todos os lembretes (primeira página)
final page1 = await datasource.fetchReminders(limit: 100);
print('Página 1: ${page1.items.length} lembretes');

// Buscar próxima página
if (page1.hasMore) {
  final page2 = await datasource.fetchReminders(
    cursor: page1.next,
    limit: 100,
  );
  print('Página 2: ${page2.items.length} lembretes');
}

// Sincronização incremental (buscar apenas novos desde última sync)
final lastSync = DateTime(2024, 12, 1);
final delta = await datasource.fetchReminders(since: lastSync);
print('Novos desde $lastSync: ${delta.items.length}');

// Enviar lembretes para o servidor
final remindersToSend = [
  ReminderDto(
    id: 'rem_123',
    task_id: 'task_456',
    reminder_date: '2024-12-15T10:00:00Z',
    type: 'once',
    is_active: true,
    created_at: '2024-12-01T08:00:00Z',
  ),
];
final sent = await datasource.upsertReminders(remindersToSend);
print('Enviados: $sent lembretes');
*/
