# 📋 TaskFlow - Gerenciador de Tarefas Inteligente

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Um aplicativo completo de gerenciamento de tarefas desenvolvido em Flutter com arquitetura limpa e padrões de design modernos.

[Características](#-características) • [Tecnologias](#-tecnologias) • [Instalação](#-instalação) • [Uso](#-uso) • [Arquitetura](#-arquitetura)

</div>

---

## ✨ Características

### 🏗️ Arquitetura Clean Architecture
- **Separação em camadas** (Domain, Infrastructure, Application, Presentation)
- **Independência de frameworks** - Lógica de negócio pura em Dart
- **Testabilidade** - Código organizado e facilmente testável
- **Independência de UI** - Interfaces podem ser alteradas sem impactar o domínio
- **Independência de BD** - Persistência intercambiável (SQLite, Supabase, Firebase)

### 📝 Feature 1: Sistema de DAOs e Persistência
- **5 DAOs implementados** seguindo padrões profissionais
- **Interface Repository Pattern** para abstração de dados
- **DTOs e Mappers** para transformação de dados (Entity ↔ DTO)
- **Cache offline-first** com sincronização incremental
- **Integração Supabase** para backend
- **Entidades de domínio**: Task, Category, Reminder, Provider, User

### 🏷️ Feature 2: Sistema de Categorização e Filtros
- **Categorias personalizadas** com cores e ícones
- **Gestão completa de categorias** (criar, editar, excluir)
- **Filtros avançados**: categoria, status, prioridade, data
- **Filtros compostos** (múltiplos filtros simultâneos)
- **Badge visual** indicando filtros ativos
- **Persistência de filtros** entre sessões

### 🔔 Feature 3: Sistema de Lembretes e Notificações
- **Notificações locais** com flutter_local_notifications
- **Agendamento preciso** com AndroidScheduleMode.alarmClock
- **Suporte Android 13+** com permissões completas
- **Notificações persistentes** que sobrevivem reinicializações
- **Gerenciamento de lembretes** (criar, editar, excluir)
- **Múltiplos lembretes** por tarefa
- **Timezone support** (America/Sao_Paulo)

### 📋 Sistema de Listagem com Interações (Prompts 08-11)
- ✅ **Listagem paginada** (Prompt 08) - ListView com pull-to-refresh
- ✅ **Seleção de item** (Prompt 09) - PopupMenu com ações (Editar/Remover)
- ✅ **Edição de itens** (Prompt 10) - Ícone de edição com formulário de diálogo
- ✅ **Remoção por swipe** (Prompt 11) - Dismissible com confirmação de exclusão
- **Diálogos não-dismissable** - Fechamento apenas por botões explícitos
- **Feedback visual** com SnackBar de sucesso/erro
- **Tratamento de erros** com try/catch em todas operações

### 🎨 Funcionalidades Gerais
- ✅ **CRUD completo** de tarefas com validações
- ✅ **Sistema de prioridades** (alta, média, baixa)
- ✅ **Datas de vencimento** com validações
- ✅ **Busca inteligente** por título e descrição
- ✅ **Estatísticas visuais** com progresso
- ✅ **Tutorial interativo** para novos usuários
- ✅ **Tema personalizado** Material Design 3
- ✅ **Consentimento LGPD** integrado
- ✅ **Animações de celebração** ao concluir tarefas

---

## 🛠️ Tecnologias

### Core
- **Flutter**: `3.9+`
- **Dart**: `3.0+`
- **Provider**: `^6.1.2` - Gerenciamento de estado

### Backend & Storage
- **Supabase Flutter**: `^2.7.0` - Backend as a Service
- **Shared Preferences**: `^2.2.0` - Cache local

### Notificações
- **Flutter Local Notifications**: `^17.2.4` - Sistema de notificações
- **Timezone**: `^0.9.4` - Suporte a timezones
- **Permission Handler**: `^11.0.1` - Gerenciamento de permissões

### UI/UX
- **Google Fonts**: `^6.1.0` - Tipografia personalizada
- **Material Design 3** - Design system moderno

### Qualidade
- **Flutter Lints**: `^4.0.0` - Análise estática de código
- **Flutter Test** - Testes unitários e de widgets

---

## 📦 Instalação

### Pré-requisitos
- Flutter SDK 3.9 ou superior
- Dart SDK 3.0 ou superior
- Android Studio / VS Code
- Dispositivo Android ou emulador

### Passos

1. **Clone o repositório**
```bash
git clone https://github.com/Murilo-A-Rodrigues/TaskFlow.git
cd TaskFlow/taskflow_app
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Configure o Supabase**
- Crie um projeto em [supabase.com](https://supabase.com)
- Execute o script SQL em `supabase_setup.sql`
- Configure as credenciais (veja `GUIA_SUPABASE.md`)

4. **Execute o app**
```bash
flutter run
```

---

## 🚀 Uso

### Primeira Execução
1. **Tutorial Inicial**: Conheça os recursos principais
2. **Consentimento**: Aceite os termos de uso e privacidade
3. **Criar Tarefa**: Toque no botão FAB pulsante
4. **Adicionar Categoria**: Vá em Configurações → Categorias
5. **Configurar Lembretes**: Abra uma tarefa e adicione lembretes

### Fluxo de Trabalho
```
📝 Criar Tarefa → 🏷️ Atribuir Categoria → 🔔 Adicionar Lembrete → ✅ Concluir
```

### Filtros Avançados
- **Toque no ícone de filtro** na HomeScreen
- **Combine múltiplos filtros**: categoria + status + prioridade
- **Filtros persistem** entre sessões
- **Limpe os filtros** tocando no chip de filtros ativos

### Notificações
- **Permissões**: Concedidas automaticamente na primeira execução
- **Teste**: Use o botão "Testar Notificação" nas configurações
- **Agendar**: Adicione lembretes com data/hora futura
- **Gerenciar**: Visualize todos os lembretes na tela de lembretes

---

## 🏗️ Arquitetura

### Clean Architecture - Camadas e Responsabilidades

O projeto segue **Clean Architecture** de Robert C. Martin com separação clara de camadas:

#### 1️⃣ Domain (Domínio) - `lib/features/*/domain/`
- **Entidades de negócio**: Task, Category, Reminder, Provider, User
- **Interfaces de repositórios**: Contratos para acesso a dados
- **Regras de negócio puras**: Código 100% Dart sem dependências do Flutter
- **Value Objects**: TaskPriority, enums, validators

#### 2️⃣ Infrastructure (Infraestrutura) - `lib/features/*/infrastructure/`
- **DTOs**: Objetos de transferência de dados (snake_case para APIs)
- **Mappers**: Conversão bidirecional Entity ↔ DTO
- **Repositórios**: Implementações concretas dos contratos do domínio
- **DAOs locais**: ProvidersLocalDaoShared, TasksLocalDao
- **APIs remotas**: Integração com Supabase

#### 3️⃣ Application (Aplicação) - `lib/features/*/application/`
- **Services**: TaskService, CategoryService, ReminderService
- **Casos de uso**: Lógica de orquestração entre camadas
- **Gerenciamento de estado**: Provider/ChangeNotifier

#### 4️⃣ Presentation (Apresentação) - `lib/features/*/pages|widgets/`
- **Pages**: TaskListPage, CategoryPage, SettingsPage
- **Widgets**: TaskCard, CategoryChip, FilterBottomSheet
- **Dialogs**: TaskFormDialog, ConfirmationDialog
- **UI/UX**: Material Design 3, animações, feedback visual

```
lib/
├── features/           # 🎯 Organização por funcionalidade
│   ├── app/
│   │   ├── domain/
│   │   │   ├── entities/       # Task, Category, Reminder, Provider, User
│   │   │   └── repositories/   # Interfaces (contratos)
│   │   └── infrastructure/
│   │       ├── dtos/           # TaskDto, CategoryDto, etc
│   │       ├── mappers/        # TaskMapper, CategoryMapper
│   │       └── repositories/   # Implementações dos contratos
│   ├── tasks/
│   │   ├── application/        # TaskService
│   │   ├── pages/              # TaskListPage, AddEditTaskScreen
│   │   └── widgets/            # TaskCard, TaskFormDialog
│   ├── categories/
│   │   ├── application/        # CategoryService
│   │   ├── pages/              # CategoryPage
│   │   └── widgets/            # CategoryChip, CategoryForm
│   ├── reminders/
│   │   ├── application/        # ReminderService
│   │   ├── pages/              # RemindersPage
│   │   └── widgets/            # ReminderCard, ReminderForm
│   ├── providers/
│   │   ├── domain/             # Provider entity + repository interface
│   │   └── infrastructure/     # ProviderDto, Mapper, DAO, API
│   ├── settings/               # Configurações
│   ├── home/                   # Tela principal
│   ├── auth/                   # Autenticação
│   ├── onboarding/             # Tutorial inicial
│   └── splashscreen/           # Splash
├── services/           # ⚙️ Serviços transversais
│   ├── storage/        # PreferencesService
│   └── notifications/  # NotificationHelper
├── shared/             # 🔗 Componentes compartilhados
│   ├── widgets/        # Botões, cards, inputs reutilizáveis
│   └── utils/          # Helpers, extensões, constantes
├── theme/              # 🎨 Tema e estilos
└── main.dart           # 🚀 Entry point
```

### Padrões de Design Implementados
- ✅ **Repository Pattern**: Abstração de acesso a dados
- ✅ **DTO Pattern**: Transformação segura entre camadas
- ✅ **Mapper Pattern**: Conversão Entity ↔ DTO
- ✅ **Singleton Pattern**: NotificationHelper, PreferencesService
- ✅ **Observer Pattern**: Provider/ChangeNotifier para estado reativo
- ✅ **Strategy Pattern**: Filtros compostos e ordenação
- ✅ **Factory Pattern**: Criação de DTOs e Entities
- ✅ **Dependency Injection**: Services injetados via Provider

### Fluxo de Dados (Clean Architecture)
```
┌─────────────┐
│ Presentation│ ← UI/Widgets
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Application │ ← Services/UseCases
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Domain    │ ← Entities + Repository Interfaces
└──────┬──────┘
       │
       ↓
┌──────────────┐
│Infrastructure│ ← DTOs, Mappers, DAOs, APIs
└──────────────┘
       │
       ↓
  [Supabase/SharedPreferences]
```

**Regra de Dependência**: Camadas internas nunca dependem de externas
- Domain não conhece Infrastructure
- Application usa Domain (interfaces)
- Infrastructure implementa contratos do Domain
- Presentation consome Application

---

## 📱 Permissões Android

### Obrigatórias
- `POST_NOTIFICATIONS` - Enviar notificações (Android 13+)
- `SCHEDULE_EXACT_ALARM` - Agendar alarmes exatos
- `USE_EXACT_ALARM` - Usar alarmes de alta prioridade

### Opcionais
- `WAKE_LOCK` - Manter dispositivo acordado
- `RECEIVE_BOOT_COMPLETED` - Restaurar lembretes após reinicialização
- `VIBRATE` - Vibração nas notificações
- `USE_FULL_SCREEN_INTENT` - Notificações em tela cheia

Todas as permissões são **solicitadas automaticamente** quando necessárias.

---

## 📊 Estatísticas do Projeto

- **Linhas de código**: ~6.500+ (Dart)
- **Arquivos criados**: 70+
- **Features implementadas**: 
  - ✅ 3 features principais completas (DAOs, Categorização, Lembretes)
  - ✅ Sistema de listagem com interações (Prompts 08-11)
  - ✅ Clean Architecture implementada
  - ✅ 5 entidades de domínio com DTOs e Mappers
- **Camadas arquiteturais**: Domain, Infrastructure, Application, Presentation
- **Padrões de design**: 7 padrões implementados
- **Testes**: Entity/DTO/Mapper com cobertura
- **Documentação**: 4.000+ linhas de documentação técnica

---

## 📚 Documentação

- **[PRD_TaskFlow.md](../PRD_TaskFlow.md)**: Product Requirements Document
- **[docs/apresentacao.md](../docs/apresentacao.md)**: Documentação completa (2.926 linhas)
- **[CLEAN_ARCHITECTURE_GUIDE.md](CLEAN_ARCHITECTURE_GUIDE.md)**: Guia completo de Clean Architecture (395 linhas)
- **[CLEAN_ARCHITECTURE_MIGRATION.md](CLEAN_ARCHITECTURE_MIGRATION.md)**: Histórico de migração para Clean Arch
- **[supabase_setup.sql](supabase_setup.sql)**: Script de setup do banco de dados Supabase
- **[Prompts/](Prompts/)**: Documentação dos prompts de implementação
  - `08_agent_list_prompt.md` - Especificação de listagem
  - `09_agent_list_selection.md` - Seleção com diálogo de ações
  - `10_agent_list_edit.md` - Edição com formulário
  - `11_agent_list_remove.md` - Remoção por swipe com confirmação
- **[Alterações por IA/](Alterações%20por%20IA/)**: Registros detalhados de refatorações e melhorias

---

## 🎨 Design System

### Cores
- **Primary (Indigo)**: `#4F46E5` - Ações principais
- **Secondary (Amber)**: `#F59E0B` - Destaques e ênfase
- **Surface**: Tons de cinza para backgrounds
- **Error/Success**: Vermelho/Verde semânticos

### Tipografia
- **Fonte**: SF Pro (iOS) / Roboto (Android)
- **Escala**: Display, Headline, Title, Body, Label

### Componentes
- **Cards elevados** com sombras suaves
- **FAB pulsante** com animação
- **Chips coloridos** para categorias
- **Badges** para indicadores visuais
- **Bottom sheets** para filtros e formulários

---

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Testes com cobertura
flutter test --coverage

# Teste específico de mapper
flutter test test/entity_dto_mapper_test.dart
```

**Cobertura Atual**:
- ✅ Entity/DTO/Mapper testados (TaskMapper)
- ✅ Testes unitários de conversão bidirecional
- ✅ Validações de campos obrigatórios
- 🔄 Testes de integração em desenvolvimento

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Murilo Andre Rodrigues**

- GitHub: [@Murilo-A-Rodrigues](https://github.com/Murilo-A-Rodrigues)
- Projeto: TaskFlow
- Instituição: UTFPR

