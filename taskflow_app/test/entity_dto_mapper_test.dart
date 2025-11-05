import 'package:flutter_test/flutter_test.dart';

// Imports das entidades
import '../lib/features/app/domain/entities/user.dart';
import '../lib/features/app/domain/entities/project.dart';
import '../lib/features/app/domain/entities/project_status.dart';
import '../lib/features/app/domain/entities/category.dart';
import '../lib/features/app/domain/entities/comment.dart';

// Imports dos DTOs
import '../lib/features/app/infrastructure/dtos/user_dto.dart';
import '../lib/features/app/infrastructure/dtos/project_dto.dart';
import '../lib/features/app/infrastructure/dtos/category_dto.dart';
import '../lib/features/app/infrastructure/dtos/comment_dto.dart';

// Imports dos Mappers
import '../lib/features/app/infrastructure/mappers/user_mapper.dart';
import '../lib/features/app/infrastructure/mappers/project_mapper.dart';
import '../lib/features/app/infrastructure/mappers/category_mapper.dart';
import '../lib/features/app/infrastructure/mappers/comment_mapper.dart';

void main() {
  group('Entity/DTO/Mapper Tests - TaskFlow', () {
    
    // ========================================================================
    // 1. USER ENTITY TESTS
    // ========================================================================
    group('User Entity/DTO/Mapper', () {
      
      test('User: Entity -> DTO -> Entity conversion', () {
        // Arrange - Criar User Entity com dados válidos
        final originalEntity = User(
          id: 'user_123',
          name: 'João Silva',
          email: 'joao.silva@email.com',
          phone: '+5511999887766',
          avatarUrl: 'https://example.com/avatar.jpg',
          isActive: true,
          createdAt: DateTime.parse('2025-11-04T10:00:00Z'),
          updatedAt: DateTime.parse('2025-11-04T10:30:00Z'),
          lastLoginAt: DateTime.parse('2025-11-04T09:00:00Z'),
        );

        // Act - Conversão Entity -> DTO -> Entity
        final dto = UserMapper.toDto(originalEntity);
        final convertedEntity = UserMapper.toEntity(dto);

        // Assert - Validar que os dados foram preservados
        expect(convertedEntity.id, originalEntity.id);
        expect(convertedEntity.name, originalEntity.name);
        expect(convertedEntity.email, originalEntity.email);
        expect(convertedEntity.phone, originalEntity.phone);
        expect(convertedEntity.avatarUrl, originalEntity.avatarUrl);
        expect(convertedEntity.isActive, originalEntity.isActive);
        expect(convertedEntity.createdAt, originalEntity.createdAt);
        expect(convertedEntity.updatedAt, originalEntity.updatedAt);
        expect(convertedEntity.lastLoginAt, originalEntity.lastLoginAt);
      });

      test('User: DTO -> Entity -> DTO conversion', () {
        // Arrange - Criar UserDto com dados do Supabase
        final originalDto = UserDto(
          id: 'user_456',
          name: 'Maria Santos',
          email: 'maria.santos@email.com',
          phone: null, // Campo opcional
          avatar_url: null, // Campo opcional
          is_active: true,
          created_at: '2025-11-04T11:00:00Z',
          updated_at: '2025-11-04T11:15:00Z',
          last_login_at: null, // Campo opcional
        );

        // Act - Conversão DTO -> Entity -> DTO
        final entity = UserMapper.toEntity(originalDto);
        final convertedDto = UserMapper.toDto(entity);

        // Assert - Validar que os dados foram preservados
        expect(convertedDto.id, originalDto.id);
        expect(convertedDto.name, originalDto.name);
        expect(convertedDto.email, originalDto.email);
        expect(convertedDto.phone, originalDto.phone);
        expect(convertedDto.avatar_url, originalDto.avatar_url);
        expect(convertedDto.is_active, originalDto.is_active);
        // Para datas, verificar se são equivalentes (ISO pode ter milissegundos)
        expect(DateTime.parse(convertedDto.created_at), DateTime.parse(originalDto.created_at));
        expect(DateTime.parse(convertedDto.updated_at), DateTime.parse(originalDto.updated_at));
        expect(convertedDto.last_login_at, originalDto.last_login_at);
      });

      test('User: Validações de domínio funcionam', () {
        // Test 1: Email inválido
        expect(() => User(name: 'Teste', email: 'email_inválido'), throwsArgumentError);
        
        // Test 2: Nome vazio
        expect(() => User(name: '', email: 'teste@email.com'), throwsArgumentError);
        
        // Test 3: Nome muito curto
        expect(() => User(name: 'A', email: 'teste@email.com'), throwsArgumentError);
      });

      test('User: Métodos de domínio funcionam', () {
        // Arrange
        final user = User(name: 'Teste', email: 'teste@email.com');

        // Act & Assert - Ativação/Desativação
        final deactivated = user.deactivate();
        expect(deactivated.isActive, false);
        
        final activated = deactivated.activate();
        expect(activated.isActive, true);

        // Act & Assert - Update login
        final withLogin = user.updateLastLogin();
        expect(withLogin.lastLoginAt, isNotNull);
        expect(withLogin.lastLoginAt!.isAfter(user.createdAt) || 
               withLogin.lastLoginAt!.isAtSameMomentAs(user.createdAt), true);
      });
    });

    // ========================================================================
    // 2. PROJECT ENTITY TESTS
    // ========================================================================
    group('Project Entity/DTO/Mapper', () {
      
      test('Project: Entity -> DTO -> Entity conversion', () {
        // Arrange - Criar Project Entity com dados completos
        final originalEntity = Project(
          id: 'project_123',
          name: 'TaskFlow Mobile App',
          description: 'Aplicativo móvel para gerenciamento de tarefas',
          ownerId: 'user_123',
          status: ProjectStatus.active,
          startDate: DateTime.parse('2025-11-01T08:00:00Z'),
          endDate: DateTime.parse('2025-12-31T18:00:00Z'),
          deadline: DateTime.parse('2025-12-25T23:59:59Z'),
          color: '#FF5722',
          isArchived: false,
          createdAt: DateTime.parse('2025-10-28T10:00:00Z'),
          updatedAt: DateTime.parse('2025-11-04T14:30:00Z'),
        );

        // Act - Conversão Entity -> DTO -> Entity
        final dto = ProjectMapper.toDto(originalEntity);
        final convertedEntity = ProjectMapper.toEntity(dto);

        // Assert - Validar que os dados foram preservados
        expect(convertedEntity.id, originalEntity.id);
        expect(convertedEntity.name, originalEntity.name);
        expect(convertedEntity.description, originalEntity.description);
        expect(convertedEntity.ownerId, originalEntity.ownerId);
        expect(convertedEntity.status, originalEntity.status);
        expect(convertedEntity.startDate, originalEntity.startDate);
        expect(convertedEntity.endDate, originalEntity.endDate);
        expect(convertedEntity.deadline, originalEntity.deadline);
        expect(convertedEntity.color, originalEntity.color);
        expect(convertedEntity.isArchived, originalEntity.isArchived);
        expect(convertedEntity.createdAt, originalEntity.createdAt);
        expect(convertedEntity.updatedAt, originalEntity.updatedAt);
      });

      test('Project: Validações de domínio funcionam', () {
        // Test 1: Nome vazio
        expect(() => Project(name: '', ownerId: 'user_123'), throwsArgumentError);
        
        // Test 2: Owner ID vazio
        expect(() => Project(name: 'Projeto', ownerId: ''), throwsArgumentError);
        
        // Test 3: Data início posterior à data fim
        expect(() => Project(
          name: 'Projeto',
          ownerId: 'user_123',
          startDate: DateTime.parse('2025-12-31T00:00:00Z'),
          endDate: DateTime.parse('2025-01-01T00:00:00Z'),
        ), throwsArgumentError);
      });

      test('Project: Métodos de domínio funcionam', () {
        // Arrange
        final project = Project(name: 'Teste', ownerId: 'user_123');

        // Act & Assert - Start project
        final started = project.start(startDate: DateTime.parse('2025-11-04T08:00:00Z'));
        expect(started.status, ProjectStatus.active);
        expect(started.startDate, isNotNull);

        // Act & Assert - Complete project
        final completed = started.complete(endDate: DateTime.parse('2025-11-04T18:00:00Z'));
        expect(completed.status, ProjectStatus.completed);
        expect(completed.endDate, isNotNull);

        // Act & Assert - Archive project
        final archived = completed.archive();
        expect(archived.isArchived, true);
      });

      test('Project: Cálculo de progresso funciona', () {
        // Arrange - Projeto com datas definidas
        final project = Project(
          name: 'Teste',
          ownerId: 'user_123',
          status: ProjectStatus.active,
          startDate: DateTime.parse('2025-11-01T00:00:00Z'),
          endDate: DateTime.parse('2025-11-30T00:00:00Z'),
        );

        // Act & Assert
        expect(project.hasDateRange, true);
        expect(project.progress, greaterThanOrEqualTo(0.0));
        expect(project.progress, lessThanOrEqualTo(1.0));
        expect(project.duration!.inDays, 29);
      });
    });

    // ========================================================================
    // 3. CATEGORY ENTITY TESTS
    // ========================================================================
    group('Category Entity/DTO/Mapper', () {
      
      test('Category: Entity -> DTO -> Entity conversion', () {
        // Arrange - Criar Category Entity com hierarquia
        final originalEntity = Category(
          id: 'category_123',
          name: 'Trabalho',
          description: 'Tarefas relacionadas ao trabalho',
          userId: 'user_123',
          parentId: null, // Categoria raiz
          color: '#4CAF50',
          icon: 'work_outline',
          sortOrder: 1,
          isActive: true,
          createdAt: DateTime.parse('2025-11-04T08:00:00Z'),
          updatedAt: DateTime.parse('2025-11-04T08:30:00Z'),
        );

        // Act - Conversão Entity -> DTO -> Entity
        final dto = CategoryMapper.toDto(originalEntity);
        final convertedEntity = CategoryMapper.toEntity(dto);

        // Assert - Validar que os dados foram preservados
        expect(convertedEntity.id, originalEntity.id);
        expect(convertedEntity.name, originalEntity.name);
        expect(convertedEntity.description, originalEntity.description);
        expect(convertedEntity.userId, originalEntity.userId);
        expect(convertedEntity.parentId, originalEntity.parentId);
        expect(convertedEntity.color, originalEntity.color);
        expect(convertedEntity.icon, originalEntity.icon);
        expect(convertedEntity.sortOrder, originalEntity.sortOrder);
        expect(convertedEntity.isActive, originalEntity.isActive);
        expect(convertedEntity.createdAt, originalEntity.createdAt);
        expect(convertedEntity.updatedAt, originalEntity.updatedAt);
      });

      test('Category: Validações de domínio funcionam', () {
        // Test 1: Nome vazio
        expect(() => Category(name: '', userId: 'user_123'), throwsArgumentError);
        
        // Test 2: User ID vazio
        expect(() => Category(name: 'Categoria', userId: ''), throwsArgumentError);
        
        // Test 3: Cor inválida
        expect(() => Category(name: 'Categoria', userId: 'user_123', color: 'cor_inválida'), throwsArgumentError);
        
        // Test 4: Cores válidas passam
        expect(() => Category(name: 'Categoria', userId: 'user_123', color: '#FF5722'), isNot(throwsArgumentError));
      });

      test('Category: Validação de cor funciona', () {
        // Arrange & Act - Cores válidas
        final cat1 = Category(name: 'Teste', userId: 'user_123', color: '#FF5722');
        final cat2 = Category(name: 'Teste', userId: 'user_123', color: 'FF5722'); // Sem #
        final cat3 = Category(name: 'Teste', userId: 'user_123', color: '#F57'); // Formato curto

        // Assert
        expect(cat1.color, '#FF5722');
        expect(cat2.color, '#FF5722');
        expect(cat3.color, '#F57');
        expect(cat1.colorValue, 0xFF5722);
      });

      test('Category: Hierarquia funciona', () {
        // Arrange - Criar categorias com hierarquia
        final parent = Category(name: 'Trabalho', userId: 'user_123');
        final child = Category(name: 'Reuniões', userId: 'user_123', parentId: parent.id);

        // Act & Assert
        expect(parent.hasParent, false);
        expect(child.hasParent, true);
        expect(child.parentId, parent.id);

        // Mover categoria
        final moved = child.moveTo(newParentId: null);
        expect(moved.parentId, isNull);
      });
    });

    // ========================================================================
    // 4. COMMENT ENTITY TESTS
    // ========================================================================
    group('Comment Entity/DTO/Mapper', () {
      
      test('Comment: Entity -> DTO -> Entity conversion', () {
        // Arrange - Criar Comment Entity completo
        final originalEntity = Comment(
          id: 'comment_123',
          content: 'Este é um comentário de teste com conteúdo válido.',
          taskId: 'task_123',
          authorId: 'user_123',
          parentId: null, // Comentário top-level
          isEdited: true,
          editedAt: DateTime.parse('2025-11-04T10:30:00Z'),
          isDeleted: false,
          createdAt: DateTime.parse('2025-11-04T10:00:00Z'),
          updatedAt: DateTime.parse('2025-11-04T10:30:00Z'),
        );

        // Act - Conversão Entity -> DTO -> Entity
        final dto = CommentMapper.toDto(originalEntity);
        final convertedEntity = CommentMapper.toEntity(dto);

        // Assert - Validar que os dados foram preservados
        expect(convertedEntity.id, originalEntity.id);
        expect(convertedEntity.content, originalEntity.content);
        expect(convertedEntity.taskId, originalEntity.taskId);
        expect(convertedEntity.authorId, originalEntity.authorId);
        expect(convertedEntity.parentId, originalEntity.parentId);
        expect(convertedEntity.isEdited, originalEntity.isEdited);
        expect(convertedEntity.editedAt, originalEntity.editedAt);
        expect(convertedEntity.isDeleted, originalEntity.isDeleted);
        expect(convertedEntity.createdAt, originalEntity.createdAt);
        expect(convertedEntity.updatedAt, originalEntity.updatedAt);
      });

      test('Comment: Validações de domínio funcionam', () {
        // Test 1: Conteúdo vazio
        expect(() => Comment(
          content: '',
          taskId: 'task_123',
          authorId: 'user_123',
        ), throwsArgumentError);
        
        // Test 2: Task ID vazio
        expect(() => Comment(
          content: 'Conteúdo válido',
          taskId: '',
          authorId: 'user_123',
        ), throwsArgumentError);
        
        // Test 3: Author ID vazio
        expect(() => Comment(
          content: 'Conteúdo válido',
          taskId: 'task_123',
          authorId: '',
        ), throwsArgumentError);
        
        // Test 4: Conteúdo muito longo
        final longContent = 'A' * 5001; // Mais que o limite
        expect(() => Comment(
          content: longContent,
          taskId: 'task_123',
          authorId: 'user_123',
        ), throwsArgumentError);
      });

      test('Comment: Métodos de domínio funcionam', () {
        // Arrange
        final comment = Comment(
          content: 'Comentário original',
          taskId: 'task_123',
          authorId: 'user_123',
        );

        // Act & Assert - Edição
        final edited = comment.edit('Comentário editado');
        expect(edited.content, 'Comentário editado');
        expect(edited.isEdited, true);
        expect(edited.editedAt, isNotNull);

        // Act & Assert - Soft delete
        final deleted = comment.softDelete();
        expect(deleted.isDeleted, true);
        expect(deleted.displayContent, '[Comentário removido]');

        // Act & Assert - Restore
        final restored = deleted.restore();
        expect(restored.isDeleted, false);

        // Act & Assert - Create reply
        final reply = comment.createReply(
          content: 'Esta é uma resposta',
          authorId: 'user_456',
        );
        expect(reply.isReply, true);
        expect(reply.parentId, comment.id);
        expect(reply.taskId, comment.taskId);
      });

      test('Comment: Threading funciona', () {
        // Arrange - Criar comments com replies
        final mainComment = Comment(
          id: 'comment_1',
          content: 'Comentário principal',
          taskId: 'task_123',
          authorId: 'user_123',
        );

        final reply1 = Comment(
          id: 'comment_2',
          content: 'Primeira resposta',
          taskId: 'task_123',
          authorId: 'user_456',
          parentId: mainComment.id,
        );

        final reply2 = Comment(
          id: 'comment_3',
          content: 'Segunda resposta',
          taskId: 'task_123',
          authorId: 'user_789',
          parentId: mainComment.id,
        );

        final comments = [mainComment, reply1, reply2];

        // Act - Construir threads
        final threads = CommentMapper.buildThreads(comments);

        // Assert
        expect(threads.length, 1); // Um thread principal
        expect(threads[0].comment.id, mainComment.id);
        expect(threads[0].hasReplies, true);
        expect(threads[0].totalReplies, 2);
        expect(threads[0].replies.length, 2);
      });
    });

    // ========================================================================
    // 5. TESTES INTEGRADOS
    // ========================================================================
    group('Testes Integrados - Múltiplas Entidades', () {
      
      test('Cenário completo: User -> Project -> Category -> Task -> Comment', () {
        // 1. Criar usuário
        final user = User(
          id: 'user_integration_test',
          name: 'Desenvolvedor TaskFlow',
          email: 'dev@taskflow.com',
        );

        // 2. Criar projeto do usuário
        final project = Project(
          id: 'project_integration_test',
          name: 'Projeto de Integração',
          ownerId: user.id,
        );

        // 3. Criar categoria para o usuário
        final category = Category(
          id: 'category_integration_test',
          name: 'Desenvolvimento',
          userId: user.id,
          color: '#2196F3',
        );

        // 4. Simular comentário em uma tarefa
        final comment = Comment(
          id: 'comment_integration_test',
          content: 'Comentário de integração funcionando perfeitamente!',
          taskId: 'task_integration_test',
          authorId: user.id,
        );

        // Validar relacionamentos
        expect(project.ownerId, user.id);
        expect(category.userId, user.id);
        expect(comment.authorId, user.id);

        // Testar conversões DTO para todas as entidades
        final userDto = UserMapper.toDto(user);
        final projectDto = ProjectMapper.toDto(project);
        final categoryDto = CategoryMapper.toDto(category);
        final commentDto = CommentMapper.toDto(comment);

        // Validar que as conversões não perderam dados
        expect(UserMapper.toEntity(userDto).id, user.id);
        expect(ProjectMapper.toEntity(projectDto).id, project.id);
        expect(CategoryMapper.toEntity(categoryDto).id, category.id);
        expect(CommentMapper.toEntity(commentDto).id, comment.id);
      });

      test('Serialização JSON funciona para todas as entidades', () {
        // Arrange - Criar entidades
        final user = User(name: 'JSON Test', email: 'json@test.com');
        final project = Project(name: 'JSON Project', ownerId: user.id);
        final category = Category(name: 'JSON Category', userId: user.id);
        final comment = Comment(
          content: 'JSON Comment',
          taskId: 'task_json',
          authorId: user.id,
        );

        // Act - Converter para DTO -> JSON -> DTO -> Entity
        final userJson = UserMapper.toDto(user).toJson();
        final projectJson = ProjectMapper.toDto(project).toJson();
        final categoryJson = CategoryMapper.toDto(category).toJson();
        final commentJson = CommentMapper.toDto(comment).toJson();

        final userFromJson = UserMapper.toEntity(UserDto.fromJson(userJson));
        final projectFromJson = ProjectMapper.toEntity(ProjectDto.fromJson(projectJson));
        final categoryFromJson = CategoryMapper.toEntity(CategoryDto.fromJson(categoryJson));
        final commentFromJson = CommentMapper.toEntity(CommentDto.fromJson(commentJson));

        // Assert - Validar que os dados foram preservados
        expect(userFromJson.id, user.id);
        expect(userFromJson.name, user.name);
        expect(projectFromJson.id, project.id);
        expect(projectFromJson.name, project.name);
        expect(categoryFromJson.id, category.id);
        expect(categoryFromJson.name, category.name);
        expect(commentFromJson.id, comment.id);
        expect(commentFromJson.content, comment.content);
      });
    });
  });
}