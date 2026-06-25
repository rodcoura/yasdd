# yasdd

> Yell At Specs, Design Directly — uma pipeline pragmática, apenas em markdown, para agentes de IA.

**Idiomas:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## Instalação

yasdd é puro markdown — sem build, sem dependências. Coloque `skills/` onde seu agent harness lê.

### Recomendado: script de instalação

O `install-to-agents.sh` copia as skills para os locais que cada tool escaneia:

```bash
# a partir de um checkout do repo
./install-to-agents.sh

# ou one-liner (baixa + instala)
curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash

# fixar uma versão específica
YASDD_REF=<tag> curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
```

Destinos:

| Diretório | Conteúdo |
| --- | --- |
| `~/.agents/` | skills (mirror cross-tool) |
| `~/.claude/` | skills (Claude Code nativo) |

### Manual: symlinks

Escolha um local:

- **Global (todos os projetos):** `~/.agents/` — dá a você `~/.agents/skills/yasdd-*/SKILL.md`.
- **Por projeto (um repositório):** `.agents/` na raiz do projeto — `.agents/skills/...`.
- **Personalizado:** qualquer pasta que seu agent harness carregue skills.

Faça symlink de cada skill (seguro se a pasta já tiver outras skills):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# instalação global
mkdir -p ~/.agents/skills
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
```

Para instalação por projeto, repita o loop com `.agents/` no lugar de `~/.agents/`.

---

## O que é o yasdd?

yasdd é um **framework specless de design e entrega** feito inteiramente de skills em markdown. Ele dá a um agente de IA uma pipeline repetível para transformar um pedido vago de feature em uma feature totalmente implementada e revisada — sem overthinking e sem pular as perguntas difíceis. Também possui uma pipeline de correção de bugs: investigar root cause → corrigir → verificar.

Não é código-fonte. Não há build system. Tudo vive em um diretório:

- `skills/` — uma pasta por skill (`<skill>/SKILL.md`); inclui os orquestradores de feature e bug, a skill de plan/grill, a skill de investigação, e as instruções dos subagentes.

## Como funciona

### Pipeline de feature

Cada feature percorre uma pipeline enxuta, com gate do usuário:

```
0. CONFIG     yasdd-feature lê .yasdd/config.yml (cria com defaults se faltar)
1. PLAN        grill + exploração → PLAN.md (incl. Test impact, anchors [M#], paralelismo inline)
2. GATE         usuário lê PLAN.md → aceita OU pede mudanças → loop até aceitar
3. IMPLEMENT    lê PLAN.md → lança subagentes implementadores por [M#], paralelo quando possível, sequencial em deps
4. GATE         se autoMode:true → pula. Se false → usuário testa manualmente → loop de correção vibe-coding até "no more issues"
5. TEST         UM tester escreve testes unitários + confirma testes impactados passam → retorna FINISHED/ISSUES
6. VERIFY       UM verifier roda checks + revisa diff + escreve SUMMARY.md (Business/Implemented/Files)
```

PLAN roda na sessão principal reutilizando o contexto de código carregado (zero re-exploração); IMPLEMENT/TEST/VERIFY rodam como subagentes isolados com contexto limpo.

### Pipeline de correção de bugs

Cada correção de bug percorre uma pipeline enxuta, com gate do usuário:

```
0. CONFIG       yasdd-bug lê .yasdd/config.yml (cria com defaults se faltar)
1. INVESTIGATE   rastrear root cause + git blame + blast radius → FIX.md (incl. fix steps [M#], Test impact)
2. GATE          usuário lê FIX.md → aceita root cause + abordagem de correção OU pede mudanças → loop até aceitar
3. FIX           lê FIX.md → lança subagentes implementadores por [M#], code-only, paralelo quando possível
4. GATE          se autoMode:true → pula. Se false → usuário testa manualmente → loop de correção vibe-coding até "no more issues"
5. TEST          UM tester escreve testes unitários de regressão + confirma testes impactados passam → retorna FINISHED/ISSUES
6. VERIFY        UM verifier roda checks + revisa diff + escreve SUMMARY.md (Business/Implemented/Files)
```

INVESTIGATE roda na sessão principal reutilizando o contexto de código carregado; FIX/TEST/VERIFY rodam como subagentes isolados com contexto limpo.

Ideias centrais que fazem o yasdd funcionar:

- **Um PLAN.md, sem decomposição de specs**: a skill de plan faz grill no usuário (uma pergunta por vez com resposta recomendada), lança yasdd-spy para investigação do codebase, e escreve um único PLAN.md carregando componentes `[M#]` + marcadores de paralelismo inline + Rules/Cases/Acceptance com anchors + Test impact. Sem artifacts separados de elicitation/architecture.
- **Marcadores de paralelismo inline**: os passos carregam `*parallel with N*` ou `*depends on N*` — sem seção separada de "Parallel batches". O orquestrador (feature ou bug) lê os marcadores para decidir o que roda em paralelo vs sequencial.
- **Acceptance = Given/When/Then**: o caminho feliz + cada Case, cada um verificável por um teste. Isso torna o plan verificável em vez de autorreportado.
- **Cobertura de testes impactados**: o PLAN.md lista testes NEW (para `[A#]`/`[C#]`/`[R#]`) E testes IMPACTED existentes (mapeamento arquivo fonte → arquivo de teste, devem ficar verde). O tester confirma ambos. Isso pega quebra de testes existentes na fase TEST, não defere para VERIFY.
- **Manual test gate = loop vibe-coding**: entre implementação e testes unitários, se `autoMode: false`, o usuário exercita manualmente o sistema e reporta problemas — o implementador corrige, o usuário re-testa, loop até "no more issues". Sem cap. Informal. Usuário dirige. Ignorado quando `autoMode: true`.
- **Implementador code-only + testes adiados**: o implementador é code-only (sem testes, sem checks) para que componentes com conjuntos de arquivos disjuntos possam rodar em paralelo. O tester escreve todos os testes unitários + roda os checks uma vez após todos os componentes pousarem.
- **Verificação única a nível de feature**: um único verifier roda após a fase TEST — ele executa os checks uma vez (rerun incondicional) sobre todos os arquivos alterados e revisa o diff inteiro da feature para conformidade + code review, depois escreve o SUMMARY.md.
- **Protocolo FINISHED/ISSUES**: o implementador e o tester terminam sua saída com um token de status. O orquestrador o analisa: `FINISHED` → prosseguir; `ISSUES` → fix-loop ou mostrar ao usuário.
- **Sem tracking de estado**: não há PROJECT-STATE.md ou STATE.md. O orquestrador detecta continuação inspecionando artifacts (presença de PLAN.md/FIX.md, presença de SUMMARY.md, git diff). Dois artifacts por feature ou bug: PLAN.md/FIX.md + SUMMARY.md.

## Skills

`yasdd-feature` (features) e `yasdd-bug` (correção de bugs) são os pontos de partida. O usuário também pode chamar skills específicas manualmente se quiser.

| Skill | Papel |
| --- | --- |
| `yasdd-feature` | Ponto de entrada da pipeline de feature. Bootstrap de config, detecção de continuação, driver da pipeline: plan → implement → manual test → test → verify. |
| `yasdd-bug` | Ponto de entrada da pipeline de correção de bugs. Bootstrap de config, detecção de continuação, driver da pipeline: investigate → fix → manual test → test → verify. |
| `yasdd-plan` | Grilling + exploração do codebase → um único PLAN.md. Uma pergunta por vez com resposta recomendada, desafia termos vagos, checa claims vs código. Detecta testes impactados existentes. (sessão principal) |
| `yasdd-investigator` | Investigação de bug + root cause analysis → um único FIX.md. Rastreia defeitos reverso dos sintomas, roda git blame para identificar os commits que introduziram o bug, avalia blast radius (nível 1–5), escreve fix steps `[M#]` + Rules/Cases/Acceptance + Test impact. (sessão principal) |
| `yasdd-implementer` | Implementa UM componente `[M#]`: leituras focadas, **code-only** (sem testes, sem checks), tabela de conformidade dividida (plan-conformance auto-verificada; functioning DEFERRED) + manifesto de arquivos alterados, retorna FINISHED/ISSUES. Funciona com PLAN.md (features) e FIX.md (bugs). (subagente) |
| `yasdd-tester` | Escreve APENAS TESTES UNITÁRIOS (sem e2e/integration; testes unitários encadeiam funções reais para cobrir o fluxo de negócio) após todos os componentes pousarem; lê CONVENTIONS.md (comandos) + artifact de plan (Acceptance `[A#]` + Test impact); confirma testes impactados ficam verde; roda checks uma vez; retorna FINISHED ou ISSUES com achados classificados (test-bug vs impl-bug vs impl-bug-impacted). (subagente) |
| `yasdd-verifier` | UMA revisão a nível de feature/bug somente pesquisa de código + testes unitários + um rerun de checks (incondicional; roda lint/typecheck/tests uma vez por feature/bug, sobre todos os arquivos alterados; comandos do CONVENTIONS.md). Checa Test impact. Atribui achados aos componentes `[M#]`. Escreve SUMMARY.md. (subagente) |
| `yasdd-spy` | Analista de código leve que rastreia implementações de feature dos entry points até o armazenamento de dados. Auto-invocado para investigação de codebase + detecção greenfield. Detecta testes impactados existentes. (auto-invocado; roda em modelo rápido e barato) |

### yasdd-spy (auto-invocado)

`yasdd-spy` é a única skill com `disable-model-invocation: false` — é auto-invocada sempre que uma skill pede investigação de codebase. Projetada para rodar em um modelo rápido e barato (ex.: `anthropic/claude-haiku-4-5`) para que a fase PLAN possa lançar múltiplos spies em paralelo sem custo significativo de tokens.

O spy rastreia implementações de feature dos entry points até o armazenamento de dados, retornando referências `file:line` e listas de arquivos essenciais. Ele também detecta repos **greenfield** (sem arquivos fonte) e retorna um sinal de greenfield para que a skill de plan semeie o `CONVENTIONS.md`. Quando pedido, mapeia arquivos fonte → arquivos de teste existentes para a seção Test impact.

Para configurar um modelo específico, edite `skills/yasdd-spy/SKILL.md` e adicione ou altere um campo `model:` no frontmatter (suporte depende do agent harness).

## Início rápido

### Implementação de feature

1. Carregue a skill `yasdd-feature` com seu pedido de feature como argumentos.
2. O orquestrador cria `.yasdd/config.yml` (se faltar), deriva um slug, e carrega `yasdd-plan`.
3. A skill de plan faz grill em você (uma pergunta por vez com respostas recomendadas), lança subagentes yasdd-spy para investigação do codebase, e escreve `PLAN.md`. Ela valida o plan e apresenta para você aceitar.
4. Ao aceitar, o orquestrador lê os passos do PLAN.md com anchors `[M#]` + marcadores de paralelismo inline. Implementadores rodam code-only em paralelo (até `maxParallelism`), um por componente `[M#]`.
5. Se `autoMode: false`, você testa manualmente o sistema rodando e reporta problemas (loop de correção vibe-coding até "no more issues"). Depois UM tester escreve testes unitários + confirma testes impactados + roda checks uma vez. Depois UMA verificação a nível de feature roda sobre código + testes (corrigir → re-verificar, até 3×) e escreve SUMMARY.md.
6. Pronto? `SUMMARY.md` tem `## Business` (linguagem de PM), `## Implemented` (arquitetura), `## Files` (arquivos alterados).

### Correção de bugs

1. Carregue a skill `yasdd-bug` com seu bug report como argumentos.
2. O orquestrador cria `.yasdd/config.yml` (se faltar), deriva um slug, e carrega `yasdd-investigator`.
3. O investigator analisa o bug report, rastreia o fluxo de dados reverso do entry point até o root cause, roda `git blame` para identificar os commits que introduziram o bug (Caused By), avalia o blast radius (nível 1–5), e escreve `FIX.md` com fix steps `[M#]` + Rules/Cases/Acceptance + Test impact. Ele apresenta a investigação para você aceitar.
4. Ao aceitar, o orquestrador lê os fix steps do FIX.md com anchors `[M#]`. Implementadores rodam code-only (até `maxParallelism`), um por componente `[M#]`.
5. Se `autoMode: false`, você testa manualmente o sistema rodando e confirma que o bug foi corrigido (loop de correção vibe-coding até "no more issues"). Depois UM tester escreve testes unitários de regressão + confirma testes impactados + roda checks uma vez. Depois UMA verificação a nível de bug roda sobre código + testes (corrigir → re-verificar, até 3×) e escreve SUMMARY.md.
6. Pronto? `SUMMARY.md` tem `## Business` (linguagem de PM), `## Implemented` (arquitetura), `## Files` (arquivos alterados).

## Configuração

`.yasdd/config.yml`:

```yaml
autoMode: false        # true = pula manual test gate, direto para TEST; false = pausa para teste manual
maxParallelism: 3      # limite de chamadas de subagentes paralelos por passo + tamanho do batch
```

Comandos de check (lint, typecheck, test) são **do projeto todo**, capturados uma vez no `.yasdd/CONVENTIONS.md` (semeado pela skill de plan na primeira feature). O tester + o verifier leem o CONVENTIONS.md diretamente. Correções de bugs herdam o mesmo CONVENTIONS.md.

## CONVENTIONS.md

Um arquivo a nível de projeto em `.yasdd/CONVENTIONS.md` captura as convenções técnicas do projeto **uma vez** para que o tester + o verifier herdem diretamente em vez de redescobrir:

```md
# Project Conventions

## Tech stack
Language: <ex., TypeScript 5.4>
Framework: <ex., Express 4, Next.js 14, FastAPI 0.110>
Runtime: <ex., Node 20, Python 3.12>

## Test
Framework: <ex., Vitest 1.6, pytest 8.2>
Runner cmd: <ex., npm test, pytest>
Test location: <ex., src/**/*.test.ts, tests/**/test_*.py>

## Quality gates
Lint cmd: <ex., npm run lint, ruff check>
Typecheck cmd: <ex., npm run typecheck, tsc --noEmit, mypy>

## Directory structure
Source: <ex., src/>
Tests: <ex., src/ (colocated), tests/ (separate)>
Config: <ex., .env, config/>
```

| Cenário | Quando o CONVENTIONS.md é criado |
|----------|--------------------------------|
| **Greenfield (primeira feature)** | O sub-passo "Technical environment decision" da skill de plan semeia antes da implementação rodar |
| **Brownfield (sem CONVENTIONS.md ainda)** | A skill de plan detecta do `package.json`/`Makefile`/`AGENTS.md` na primeira feature, escreve para que as subsequentes herdem |
| **Já existe** | A skill de plan herda (nunca re-decide) |

## Onde fica cada coisa

```
.yasdd/
  config.yml                         # autoMode + maxParallelism
  CONVENTIONS.md                     # convenções técnicas do projeto (semeado uma vez; tester + verifier leem diretamente)
  features/<slug>/
    PLAN.md                          # a fonte da verdade única (goal, steps [M#], data, interfaces, rules, cases, acceptance, test impact, critical files, verification)
    SUMMARY.md                       # Business / Implemented / Files (escrito pelo verifier)
  bugs/<bug-slug>/
    FIX.md                           # relatório de investigação + plan de correção (root cause, data flow trace, caused by, blast radius, fix steps [M#], rules, cases, acceptance, test impact)
    SUMMARY.md                       # Business / Implemented / Files (escrito pelo verifier)
```

Dois artifacts por feature: `PLAN.md` (escrito pela skill de plan, aceito pelo usuário) e `SUMMARY.md` (escrito pelo verifier no final). Dois artifacts por bug: `FIX.md` (escrito pelo investigator, aceito pelo usuário) e `SUMMARY.md` (escrito pelo verifier no final).

## Suporte a greenfield

O yasdd detecta repos greenfield (sem arquivos fonte) via `yasdd-spy` e lida com eles graciosamente:

- `yasdd-spy` retorna "greenfield — no existing source files found" em vez de falhar.
- A skill de plan injeta um sub-passo "Technical environment decision" (linguagem, framework, test runner, lint, estrutura de diretórios).
- Essas decisões semeiam o `CONVENTIONS.md` antes da implementação rodar.
- Features subsequentes herdam o `CONVENTIONS.md` — sem re-decidir.

Isso NÃO adiciona um passo separado de scaffolding — se dobra naturalmente no fluxo existente de plan.
