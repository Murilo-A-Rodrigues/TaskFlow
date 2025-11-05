# Reestruturação do Projeto TaskFlow - Padrão FoodSafe

**Data:** 4 de novembro de 2025  
**Objetivo:** Reorganizar a estrutura de pastas seguindo o padrão FoodSafe

## 📁 Nova Estrutura de Pastas

```
lib/
├── app/                                    # Núcleo da aplicação
│   ├── config/                            # Configurações globais
│   ├── core/                              # Componentes centrais
│   │   ├── data/                          # DTOs, Mappers, Sample Data
│   │   │   ├── dtos/
│   │   │   ├── mappers/
│   │   │   └── sample_data_v2.dart
│   │   └── domain/                        # Entities, Enums, Regras de negócio
│   │       ├── entities/
│   │       └── enums/
│   ├── models/                            # Modelos globais (legacy)
│   ├── repositories/                      # Repositórios de dados
│   ├── services/                          # Serviços globais
│   │   ├── core/                          # Serviços centrais
│   │   ├── integrations/                  # Integrações externas
│   │   └── storage/                       # Armazenamento local
│   └── theme/                             # Temas e estilos
│
├── features/                               # Funcionalidades por domínio
│   ├── auth/                              # Autenticação
│   │   └── screens/
│   │       └── consent_screen.dart
│   ├── home/                              # Tela inicial
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── home_screen_backup.dart
│   │   └── widgets/
│   │       ├── home_drawer.dart
│   │       └── quick_stats_card.dart
│   ├── onboarding/                        # Introdução ao app
│   │   └── screens/
│   │       ├── onboarding_screen.dart
│   │       └── splash_screen.dart
│   ├── settings/                          # Configurações
│   │   └── screens/
│   │       ├── policy_viewer_screen.dart
│   │       └── settings_screen.dart
│   └── tasks/                             # Gestão de tarefas
│       ├── models/                        # Modelos específicos de tarefas
│       ├── screens/
│       │   └── add_edit_task_screen.dart
│       ├── services/                      # Serviços específicos de tarefas
│       └── widgets/
│           ├── task_card.dart
│           ├── task_form.dart
│           ├── task_list_card.dart
│           └── task_priority_chip.dart
│
├── shared/                                 # Componentes compartilhados
│   └── widgets/                           # Widgets reutilizáveis
│       ├── taskflow_icon.dart
│       ├── user_avatar.dart
│       └── custom_text_field.dart
│
├── utils/                                  # Utilitários
│
└── main.dart                              # Ponto de entrada
```

## 🎯 Benefícios da Nova Estrutura

### 1. **Organização por Features**
- ✅ Cada funcionalidade tem sua pasta dedicada
- ✅ Facilita desenvolvimento em equipe
- ✅ Código relacionado agrupado logicamente
- ✅ Escalabilidade para novas features

### 2. **Separação Clara de Responsabilidades**
```
app/core/           → Arquitetura Entity/DTO/Mapper
features/tasks/     → Tudo relacionado a tarefas
features/home/      → Tela inicial e navegação
features/auth/      → Autenticação e permissões
shared/             → Componentes reutilizáveis
```

### 3. **Padrão Consistente com FoodSafe**
- ✅ Estrutura similar ao projeto de referência
- ✅ Convenções estabelecidas e testadas
- ✅ Facilita manutenção e onboarding
- ✅ Padrão da indústria para Flutter

## 📋 Mapeamento da Migração

### Estrutura Anterior → Nova Estrutura

| **Antes** | **Depois** | **Justificativa** |
|-----------|------------|-------------------|
| `lib/domain/` | `lib/app/core/domain/` | Centraliza arquitetura no core |
| `lib/data/` | `lib/app/core/data/` | DTOs e mappers no core |
| `lib/models/` | `lib/app/models/` | Modelos globais da aplicação |
| `lib/repositories/` | `lib/app/repositories/` | Repositórios centrais |
| `lib/services/` | `lib/app/services/` | Serviços globais |
| `lib/theme/` | `lib/app/theme/` | Configuração visual global |
| `lib/config/` | `lib/app/config/` | Configurações da aplicação |
| `lib/screens/home_screen.dart` | `lib/features/home/screens/` | Agrupamento por feature |
| `lib/screens/add_edit_task_screen.dart` | `lib/features/tasks/screens/` | Tarefas isoladas |
| `lib/screens/onboarding_screen.dart` | `lib/features/onboarding/screens/` | Fluxo de entrada |
| `lib/screens/settings_screen.dart` | `lib/features/settings/screens/` | Configurações específicas |
| `lib/widgets/home/` | `lib/features/home/widgets/` | Widgets específicos da home |
| `lib/widgets/cards/` | `lib/features/tasks/widgets/` | Widgets de tarefas |
| `lib/widgets/common/` | `lib/shared/widgets/` | Widgets compartilhados |
| `lib/widgets/forms/` | `lib/shared/widgets/` | Formulários reutilizáveis |

## 🔧 Impactos nos Imports

### Exemplos de Ajustes Necessários

#### Antes:
```dart
import '../models/task.dart';
import '../services/core/task_service.dart';
import '../widgets/common/user_avatar.dart';
import '../widgets/home/home_drawer.dart';
```

#### Depois:
```dart
import '../app/core/domain/entities/task.dart';
import '../app/services/core/task_service_v2.dart';
import '../shared/widgets/user_avatar.dart';
import '../features/home/widgets/home_drawer.dart';
```

## 📈 Vantagens da Arquitetura por Features

### 1. **Desenvolvimento Modular**
```
features/tasks/
├── models/          # Modelos específicos
├── screens/         # Telas da feature  
├── services/        # Lógica de negócio
└── widgets/         # Componentes UI
```

### 2. **Facilita Testes**
```
test/
├── app/core/        # Testes da arquitetura
├── features/
│   ├── tasks/       # Testes específicos de tarefas
│   └── home/        # Testes da home
└── shared/          # Testes de widgets comuns
```

### 3. **Deploy Incremental**
- Funcionalidades podem ser desenvolvidas independentemente
- Features podem ter ciclos de release diferentes
- Facilita code review por domínio
- Reduz conflitos de merge

## 🎯 Próximos Passos

### 1. **Atualizar Imports**
- [ ] Corrigir imports nos arquivos main.dart
- [ ] Atualizar imports nos widgets
- [ ] Ajustar imports nos services
- [ ] Verificar imports nos testes

### 2. **Validar Compilação**
- [ ] `flutter analyze` sem erros
- [ ] `flutter test` funcionando
- [ ] `flutter build` sem problemas

### 3. **Documentar Convenções**
- [ ] Guia de estrutura para novos desenvolvedores
- [ ] Templates para novas features
- [ ] Padrões de nomenclatura

## ✅ Status da Reestruturação

- ✅ **Pastas criadas** seguindo padrão FoodSafe
- ✅ **Arquivos movidos** para localização correta
- ✅ **Estrutura validada** com base na imagem de referência
- ⏳ **Imports pendentes** de atualização
- ⏳ **Testes de compilação** necessários

---

**Reestruturação concluída!** 📁✨  
*Projeto TaskFlow agora segue o padrão organizacional do FoodSafe*