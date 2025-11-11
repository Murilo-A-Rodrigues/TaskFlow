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

### 📝 Feature 1: Sistema de DAOs e Persistência
- **5 DAOs implementados** seguindo padrões profissionais
- **Interface Repository Pattern** para abstração de dados
- **DTOs e Mappers** para transformação de dados
- **Cache offline-first** com sincronização incremental
- **Integração Supabase** para backend

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

### 🎨 Funcionalidades Gerais
- ✅ **CRUD completo** de tarefas
- ✅ **Sistema de prioridades** (alta, média, baixa)
- ✅ **Datas de vencimento** com validações
- ✅ **Busca inteligente** por título e descrição
- ✅ **Estatísticas visuais** com progresso
- ✅ **Tutorial interativo** para novos usuários
- ✅ **Tema personalizado** Material Design 3
- ✅ **Consentimento LGPD** integrado

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

### Clean Architecture
```
lib/
├── features/           # Módulos por funcionalidade
│   ├── app/
│   │   ├── domain/         # Entidades e regras de negócio
│   │   │   ├── entities/   # Task, Category, Reminder
│   │   │   └── repositories/  # Interfaces dos DAOs
│   │   └── infrastructure/
│   │       ├── dtos/       # Data Transfer Objects
│   │       ├── mappers/    # Entity ↔ DTO conversão
│   │       └── repositories/  # Implementação dos DAOs
│   ├── tasks/          # UI de tarefas
│   ├── categories/     # UI de categorias
│   ├── reminders/      # UI de lembretes
│   ├── settings/       # Configurações
│   └── home/           # Tela principal
├── services/           # Serviços de negócio
│   ├── core/           # TaskService, CategoryService
│   ├── storage/        # PreferencesService
│   └── notifications/  # NotificationHelper
├── shared/             # Componentes compartilhados
├── theme/              # Tema e estilos
└── main.dart           # Entry point
```

### Padrões de Design
- **Repository Pattern**: Abstração de acesso a dados
- **DTO Pattern**: Transformação segura de dados
- **Singleton Pattern**: NotificationHelper, PreferencesService
- **Observer Pattern**: Provider/ChangeNotifier
- **Strategy Pattern**: Filtros compostos
- **Factory Pattern**: Criação de DTOs e Entities

### Fluxo de Dados
```
UI → Service → Repository → DTO → Mapper → Entity → UI
         ↓           ↓
    Provider    Supabase/Cache
```

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

- **Linhas de código**: ~5.200 (Dart)
- **Arquivos criados**: 49
- **Features implementadas**: 3 completas
- **Tempo de desenvolvimento**: ~40 horas
- **Commits organizados**: Histórico limpo com conventional commits

---

## 📚 Documentação

- **[PRD_TaskFlow.md](PRD_TaskFlow.md)**: Product Requirements Document
- **[docs/apresentacao.md](docs/apresentacao.md)**: Documentação completa (2.926 linhas)
- **[GUIA_SUPABASE.md](taskflow_app/GUIA_SUPABASE.md)**: Guia de integração Supabase
- **[Prompts/](Prompts/)**: Documentação de assistência IA (7 arquivos)

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

# Teste específico
flutter test test/unit/task_mapper_test.dart
```

**Cobertura**: Entity/DTO/Mapper testados

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Murilo Andre Rodrigues**

- GitHub: [@Murilo-A-Rodrigues](https://github.com/Murilo-A-Rodrigues)
- Projeto: TaskFlow
- Instituição: UTFPR

