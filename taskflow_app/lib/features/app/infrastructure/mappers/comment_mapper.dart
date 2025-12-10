import '../../domain/entities/comment.dart';
import '../dtos/comment_dto.dart';

/// CommentMapper - Conversor centralizado entre CommentDto e Comment Entity
///
/// Esta classe é responsável por traduzir entre o formato de transporte (DTO)
/// e o formato interno da aplicação (Entity). Centraliza todas as regras de
/// conversão em um único local, facilitando manutenção e testes.
/// Segue o padrão Mapper do documento "Modelo DTO e Mapeamento".
class CommentMapper {
  /// Converte CommentDto (formato de rede/banco) para Comment Entity (formato interno)
  ///
  /// Aplica conversões como:
  /// - String ISO8601 -> DateTime
  /// - snake_case -> camelCase
  /// - Validações defensivas
  static Comment toEntity(CommentDto dto) {
    return Comment(
      id: dto.id,
      content: dto.content,
      taskId: dto.task_id,
      authorId: dto.author_id,
      parentId: dto.parent_id,
      isEdited: dto.is_edited,
      editedAt: dto.edited_at != null
          ? DateTime.tryParse(dto.edited_at!)
          : null,
      isDeleted: dto.is_deleted,
      createdAt: DateTime.parse(dto.created_at),
      updatedAt: DateTime.parse(dto.updated_at),
    );
  }

  /// Converte Comment Entity (formato interno) para CommentDto (formato de rede/banco)
  ///
  /// Aplica conversões inversas como:
  /// - DateTime -> String ISO8601
  /// - camelCase -> snake_case
  static CommentDto toDto(Comment entity) {
    return CommentDto(
      id: entity.id,
      content: entity.content,
      task_id: entity.taskId,
      author_id: entity.authorId,
      parent_id: entity.parentId,
      is_edited: entity.isEdited,
      edited_at: entity.editedAt?.toIso8601String(),
      is_deleted: entity.isDeleted,
      created_at: entity.createdAt.toIso8601String(),
      updated_at: entity.updatedAt.toIso8601String(),
    );
  }

  /// Converte lista de CommentDto para lista de Comment Entity
  static List<Comment> toEntityList(List<CommentDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Converte lista de Comment Entity para lista de CommentDto
  static List<CommentDto> toDtoList(List<Comment> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }

  /// Converte Map (vindo diretamente do Supabase) para Comment Entity
  ///
  /// Útil para quando recebemos dados diretamente do Supabase
  /// sem passar pelo CommentDto primeiro
  static Comment fromMap(Map<String, dynamic> map) {
    final dto = CommentDto.fromMap(map);
    return toEntity(dto);
  }

  /// Converte Comment Entity para Map (para enviar ao Supabase)
  ///
  /// Útil para quando queremos enviar dados diretamente ao Supabase
  /// sem criar CommentDto primeiro
  static Map<String, dynamic> toMap(Comment entity) {
    final dto = toDto(entity);
    return dto.toMap();
  }

  /// Converte lista de Maps para lista de Comment Entity
  static List<Comment> fromMapList(List<Map<String, dynamic>> maps) {
    return maps.map((map) => fromMap(map)).toList();
  }

  /// Converte lista de Comment Entity para lista de Maps
  static List<Map<String, dynamic>> toMapList(List<Comment> entities) {
    return entities.map((entity) => toMap(entity)).toList();
  }

  /// Atualiza um CommentDto existente com dados de uma Comment Entity
  ///
  /// Útil para operações de update onde queremos manter alguns
  /// campos do DTO original e atualizar outros com dados da Entity
  static CommentDto updateDtoFromEntity(
    CommentDto originalDto,
    Comment updatedEntity,
  ) {
    return CommentDto(
      id: originalDto.id, // Mantém ID original
      content: updatedEntity.content,
      task_id: updatedEntity.taskId,
      author_id: updatedEntity.authorId,
      parent_id: updatedEntity.parentId,
      is_edited: updatedEntity.isEdited,
      edited_at: updatedEntity.editedAt?.toIso8601String(),
      is_deleted: updatedEntity.isDeleted,
      created_at: originalDto.created_at, // Mantém data criação original
      updated_at: updatedEntity.updatedAt.toIso8601String(),
    );
  }

  /// Helpers para threading - constrói árvore de comentários com replies
  ///
  /// Útil para transformar lista flat em estrutura hierárquica
  static List<CommentWithReplies> buildThreads(List<Comment> comments) {
    final List<CommentWithReplies> topLevel = [];
    final Map<String, List<Comment>> repliesMap = {};

    // Agrupa replies por pai
    for (final comment in comments) {
      if (comment.isTopLevel) {
        topLevel.add(CommentWithReplies(comment: comment, replies: []));
      } else if (comment.parentId != null) {
        repliesMap.putIfAbsent(comment.parentId!, () => []);
        repliesMap[comment.parentId!]!.add(comment);
      }
    }

    // Constrói hierarquia recursivamente
    void buildReplies(CommentWithReplies parent) {
      final replies = repliesMap[parent.comment.id] ?? [];
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final reply in replies) {
        final replyWithReplies = CommentWithReplies(
          comment: reply,
          replies: [],
        );
        parent.replies.add(replyWithReplies);
        buildReplies(replyWithReplies); // Recursão para sub-replies
      }
    }

    // Aplica para todos os comentários top-level
    for (final topComment in topLevel) {
      buildReplies(topComment);
    }

    // Ordena por data de criação (mais recentes primeiro)
    topLevel.sort((a, b) => b.comment.createdAt.compareTo(a.comment.createdAt));

    return topLevel;
  }

  /// Filtra comentários por task
  static List<Comment> filterByTask(List<Comment> comments, String taskId) {
    return comments.where((comment) => comment.taskId == taskId).toList();
  }

  /// Filtra comentários ativos (não deletados)
  static List<Comment> filterActive(List<Comment> comments) {
    return comments.where((comment) => !comment.isDeleted).toList();
  }
}

/// Classe auxiliar para representar comentários com replies
class CommentWithReplies {
  final Comment comment;
  final List<CommentWithReplies> replies;

  CommentWithReplies({required this.comment, required this.replies});

  /// Conveniência para verificar se tem replies
  bool get hasReplies => replies.isNotEmpty;

  /// Conta total de replies (recursivo)
  int get totalReplies {
    int count = replies.length;
    for (final reply in replies) {
      count += reply.totalReplies;
    }
    return count;
  }

  /// Busca comentário por ID na thread
  Comment? findById(String id) {
    if (comment.id == id) return comment;

    for (final reply in replies) {
      final found = reply.findById(id);
      if (found != null) return found;
    }

    return null;
  }

  /// Flatten da thread em lista
  List<Comment> flatten() {
    final List<Comment> result = [comment];
    for (final reply in replies) {
      result.addAll(reply.flatten());
    }
    return result;
  }
}
