import 'package:uuid/uuid.dart';

/// Comment Entity - Representação interna rica e validada do comentário
///
/// Esta classe representa um comentário no domínio da aplicação TaskFlow.
/// Contém tipos fortes, validações e invariantes de domínio para relacionamentos.
/// Segue o padrão Entity do documento "Modelo DTO e Mapeamento".
class Comment {
  final String id;
  final String content;
  final String taskId; // FK para Task
  final String authorId; // FK para User (autor do comentário)
  final String? parentId; // FK para Comment (reply opcional)
  final bool isEdited; // Indica se o comentário foi editado
  final DateTime? editedAt; // Timestamp da última edição
  final bool isDeleted; // Soft delete
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    String? id,
    required String content,
    required String taskId,
    required String authorId,
    this.parentId,
    bool? isEdited,
    this.editedAt,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       content = _validateContent(content),
       taskId = _validateTaskId(taskId),
       authorId = _validateAuthorId(authorId),
       isEdited = isEdited ?? false,
       isDeleted = isDeleted ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now() {
    _validateEditState();
    _validateReplyState();
  }

  /// Validação de conteúdo - deve ser não vazio e ter tamanho razoável
  static String _validateContent(String content) {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw ArgumentError('Conteúdo do comentário não pode ser vazio');
    }
    if (trimmedContent.length < 2) {
      throw ArgumentError('Comentário deve ter pelo menos 2 caracteres');
    }
    if (trimmedContent.length > 5000) {
      throw ArgumentError('Comentário deve ter no máximo 5000 caracteres');
    }
    return trimmedContent;
  }

  /// Validação de task ID
  static String _validateTaskId(String taskId) {
    if (taskId.trim().isEmpty) {
      throw ArgumentError('ID da tarefa não pode ser vazio');
    }
    return taskId.trim();
  }

  /// Validação de author ID
  static String _validateAuthorId(String authorId) {
    if (authorId.trim().isEmpty) {
      throw ArgumentError('ID do autor não pode ser vazio');
    }
    return authorId.trim();
  }

  /// Validação de estado de edição
  void _validateEditState() {
    if (isEdited && editedAt == null) {
      throw ArgumentError('Comentário editado deve ter timestamp de edição');
    }
    if (!isEdited && editedAt != null) {
      throw ArgumentError(
        'Comentário não editado não deve ter timestamp de edição',
      );
    }
  }

  /// Validação de estado de reply
  void _validateReplyState() {
    // Não pode ser reply de si mesmo
    if (parentId == id) {
      throw ArgumentError('Comentário não pode ser reply de si mesmo');
    }
  }

  /// Conveniências para a UI
  String get displayContent => isDeleted ? '[Comentário removido]' : content;
  bool get isReply => parentId != null;
  bool get isTopLevel => parentId == null;
  int get characterCount => content.length;

  /// Helpers para conteúdo
  String get preview {
    const maxLength = 100;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Métodos de domínio
  Comment edit(String newContent) {
    if (isDeleted) {
      throw StateError('Não é possível editar comentário removido');
    }

    return copyWith(
      content: newContent,
      isEdited: true,
      editedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Comment softDelete() {
    return copyWith(isDeleted: true, updatedAt: DateTime.now());
  }

  Comment restore() {
    if (!isDeleted) {
      throw StateError('Comentário não está removido');
    }

    return copyWith(isDeleted: false, updatedAt: DateTime.now());
  }

  /// Criar reply para este comentário
  Comment createReply({required String content, required String authorId}) {
    return Comment(
      content: content,
      taskId: taskId, // Mesmo task
      authorId: authorId,
      parentId: id, // Este comentário como pai
    );
  }

  /// Validação de profundidade de replies (implementar no service)
  static const int maxReplyDepth = 3;

  /// Copy with para imutabilidade
  Comment copyWith({
    String? content,
    String? taskId,
    String? authorId,
    String? parentId,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id,
      content: content ?? this.content,
      taskId: taskId ?? this.taskId,
      authorId: authorId ?? this.authorId,
      parentId: parentId ?? this.parentId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Comment(id: $id, taskId: $taskId, authorId: $authorId, isReply: $isReply)';
  }
}
