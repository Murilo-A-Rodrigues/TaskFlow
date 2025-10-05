# PRD — TaskFlow: Primeira Execução, Consentimento e Identidade

**Objetivo:** Aplicar o modelo PRD Base ao projeto TaskFlow, focando na primeira execução com onboarding claro, identidade visual e consentimento (LGPD). Tema escolhido: TaskFlow, um app de tarefas pessoais com priorização simples.

## 0) Metadados do Projeto

**Nome do Produto/Projeto:** TaskFlow — Tarefas Pessoais  
**Responsável:** Murilo Andre Rodrigues  
**Curso/Disciplina:** Desenvolvimento de Aplicações para Dispositivos Móveis  
**Versão do PRD:** v1.0  
**Data:** 2025-10-05

## 1) Visão Geral

**Resumo:** O TaskFlow ajuda as pessoas a gerenciarem tarefas de forma eficiente, focando em to-dos com priorização simples. Na primeira execução o app guiará o usuário por um onboarding curto, leitura de políticas e consentimento explícito, conduzindo-o com clareza até a tela inicial, apresentando também uma lista de exemplo para que o usuário compreenda bem o funcionamento do app.

**Problemas que ataca:** desorientação inicial, escolhas legais não persistidas e sobrecarga de interface.

**Resultado desejado:** primeira experiência curta, guiada e memorável; decisões legais persistidas e revisáveis.

## 2) Personas e Cenários de Primeiro Acesso

**Persona principal:** Estudante multitarefa. Busca priorização simples, clareza e previsibilidade na gestão de seus afazeres.

**Cenário (happy path):** abrir app → splash (decisão de rota) → onboarding (2–3 telas) → visualizar políticas (markdown) → consentimento → home com dicas de primeiros passos.

**Cenários alternativos:**
- Pular para consentimento a partir da tela 1–2 do onboarding.
- Revogar consentimento na Home (configurações) com confirmação + Desfazer.

## 3) Identidade do Tema (Design)

### 3.1 Paleta e Direção Visual

**Primária:** Indigo #4F46E5  
**Secundária:** Gray #475569  
**Acento:** Amber #F59E0B  
**Superfície:** #FFFFFF (claro) / #0B1220 (escuro)  
**Texto:** #0F172A (claro) / #E2E8F0 (escuro)

**Direção:** flat minimalista, alto contraste WCAG AA, useMaterial3: true; ColorScheme derivada (sem cores mágicas em widgets).

### 3.2 Tipografia

**Títulos:** headlineSmall (peso 600)  
**Corpo:** bodyLarge / bodyMedium  
**Escalabilidade:** suportar text scaling (≥ 1.3) sem quebras

### 3.3 Iconografia & Ilustrações

Ícones simples (Lucide/Material), traço consistente; sem texto embutido.  
Ilustrações em estados vazios (tarefas, metas) com áreas negativas generosas.

### 3.4 Prompts (Imagens/Ícone)

**Ícone do app:** "Insígnia vetorial circular, fundo transparente, estilo flat com leve sombreamento; no centro, uma lista de tarefas com um checkmark proeminente; paleta Indigo/Amber/Gray; bordas limpas, alto contraste, sem textos, 1024×1024."

**Hero/empty:** "Ilustração flat minimalista de uma pessoa organizando cartões ou limpando uma lista de tarefas (relacionado ao domínio de to-dos), atmosfera calma, cores da paleta, sem texto."

**Entrega de identidade:** grade de cores (hex), 2–3 referências (moodboard) e 1 prompt aprovado

## 4) Jornada de Primeira Execução (Fluxo Base)

### 4.1 Splash

Exibe logomarca; decide rota por flags/versão de aceite

### 4.2 Onboarding (3 telas)

**Bem‑vindo** (benefício central: to-dos com priorização simples) — botão Avançar + Pular.  
**Como funciona** (gestão de tarefas e foco) — Avançar/Voltar + Pular.  
**Consentimento** (porta de entrada para políticas) — sem Pular; dots ocultos.

DotsIndicator sincronizado; ocultar na última página.

### 4.3 Políticas e Consentimento

Leitura de Privacidade e Termos (Markdown) com barra de progresso até o fim.  
Botão "Marcar como lido" habilita somente após 100% de scroll.  
Checkbox de aceite habilita após ambos os docs lidos; botão Concordo libera navegação para Home e persiste versão.

### 4.4 Home & Revogação

Home com card "Primeiros Passos" (crie 3 tarefas do dia).  
Revogar em Configurações → AlertDialog + SnackBar com Desfazer.

## 5) Requisitos Funcionais (RF)

• **RF‑1** Dots sincronizados; ocultos na última tela do onboarding.  
• **RF‑2** Navegação contextual: Pular vai ao consentimento; Voltar/Avançar onde fizer sentido.  
• **RF‑3** Visualizador de políticas em Markdown com progresso de leitura e "Marcar como lido".  
• **RF‑4** Consentimento opt‑in: habilitar somente após leitura dos dois docs.  
• **RF‑5** Decisão de rota no Splash por flags/versão aceita.  
• **RF‑6** Revogação com confirmação + Desfazer (SnackBar); sem desfazer → retorna ao fluxo legal.  
• **RF‑7** Versão de políticas persistida (ex.: v1) + accepted_at ISO8601; forçar releitura em nova versão.  
• **RF‑8** Ícone gerado via flutter_launcher_icons (PNG 1024×1024).

## 6) Requisitos Não Funcionais (RNF)

• **A11Y:** alvos ≥ 48dp, foco visível, Semantics, contraste AA; botões desabilitados visíveis.  
• **Privacidade (LGPD):** transparência nos textos, registro de aceite, revogação simples.  
• **Arquitetura:** UI → Service → Storage; sem uso direto de SharedPreferences na UI.  
• **Performance:** animações ~300ms; evitar rebuilds excessivos.  
• **Testabilidade:** serviço de preferências mockável; chaves centralizadas.

## 7) Dados & Persistência (chaves)

• **privacy_read_v1:** bool  
• **terms_read_v1:** bool  
• **policies_version_accepted:** string (ex.: v1)  
• **accepted_at:** string (ISO8601)  
• **onboarding_completed:** bool  
• **(Opcional) tips_enabled:** bool

**Serviço:** PrefsService com get/set/clear; isFullyAccepted(), migratePolicyVersion(from, to).

## 8) Roteamento

• **/** → Splash (decide)  
• **/onboarding** → PageView (3 telas)  
• **/policy-viewer** → viewer markdown reutilizável  
• **/home** → tela inicial

## 9) Critérios de Aceite

1. Dots sincronizados e ocultos na última tela.
2. Pular direciona ao consentimento; Voltar/Avançar contextuais.
3. Viewer de políticas com barra de progresso e "Marcar como lido" apenas no fim.
4. Checkbox/ação final habilitam somente após leitura dupla + aceite.
5. Splash leva corretamente à Home quando versão aceita existe.
6. Revogação com confirmação + Desfazer (SnackBar); sem desfazer → fluxo legal.
7. UI não usa SharedPreferences diretamente; tudo via serviço.
8. Ícones gerados e aplicados a pelo menos uma plataforma.

## 10) Protocolo de QA (testes manuais)

• Execução limpa: onboarding completo → viewer → aceite → Home.  
• Leitura parcial: um doc lido não habilita checkbox.  
• Leitura dupla + aceite: habilita conclusão e navega para Home.  
• Reabertura: vai direto à Home.  
• Revogação com Desfazer: restaura aceite; permanece na Home.  
• Revogação sem Desfazer: retorna ao fluxo legal.  
• A11Y: text scaling 1.3+, foco visível, contraste.

## 11) Riscos & Decisões

• **Risco:** esquecer versionamento do aceite → **Mitigação:** chave policies_version_accepted + checagem no Splash.  
• **Risco:** UI acoplada ao storage → **Mitigação:** PrefsService único.  
• **Decisão:** desabilitar > esconder (descobribilidade/A11Y).  
• **Decisão:** políticas como assets (offline, previsível, fácil versionar).

## 12) Entregáveis

1. PRD preenchido + identidade (paleta, moodboard, prompt).
2. Implementação funcional do fluxo base + PrefsService.
3. Evidências (prints) dos estados de onboarding/consentimento/revogação.
4. Ícone gerado (comando e resultado visível em uma plataforma).

## 13) Backlog de Evolução

• Tela Configurações/Privacidade (reabrir políticas, granularidade de consentimentos).  
• Hash por arquivo de política (expira aceite quando mudar).  
• Telemetria consciente do funil de primeira execução (com consentimento).  
• Criptografia seletiva de preferências sensíveis.

## 14) Referências Internas

• DotsIndicator paramétrico e animado.  
• Onboarding com visibilidade inteligente (Pular/Voltar/Avançar).  
• PolicyViewerPage com progresso e "Marcar como lido".  
• PrefsService + chaves centralizadas.  
• Splash com decisão de rota por flags/versão de aceite.  
• Revogação com confirmação + SnackBar (Desfazer).  
• Geração de ícone com flutter_launcher_icons.

---

## Checklist de Conformidade

- [x] Dots sincronizados e ocultos na última tela
- [x] Pular → consentimento; Voltar/Avançar contextuais
- [x] Viewer com progresso + "Marcar como lido"
- [x] Aceite habilita somente após leitura dos 2 docs
- [x] Splash decide rota por versão aceita
- [x] Revogação com confirmação + Desfazer
- [x] Sem SharedPreferences direto na UI
- [x] Ícones gerados
- [x] A11Y (48dp, contraste, Semantics, text scaling)