# yasdd

> Yell At Specs, Design Directly — uma pipeline pragmática, apenas em markdown, para agentes de IA.

**Idiomas:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## Instalação

yasdd é puro markdown — sem build, sem dependências. Coloque `skills/` e `commands/` onde seu agent harness lê. Escolha um local:

- **Global (todos os projetos):** `~/.agents/` — dá a você `~/.agents/skills/yasdd-*/SKILL.md` e `~/.agents/commands/yasdd*.md`.
- **Por projeto (um repositório):** `.agents/` na raiz do projeto — `.agents/skills/...` e `.agents/commands/...`.
- **Personalizado:** qualquer pasta que seu agent harness carregue skills/commands.

Faça symlink de cada skill + command (seguro se a pasta já tiver outras skills):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# instalação global
mkdir -p ~/.agents/skills ~/.agents/commands ~/.agents/prompts
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
for c in ~/projects/yasdd/commands/*.md; do ln -sf "$c" ~/.agents/commands/; done
for p in ~/projects/yasdd/prompts/*.md; do ln -sf "$p" ~/.agents/prompts/; done
```

Para instalação por projeto, repita os loops com `.agents/` no lugar de `~/.agents/`. Depois rode `/yasdd-init` no seu projeto para criar o `.yasdd/` e atualizar o `AGENTS.md`.

---

## O que é o yasdd?

yasdd é um **framework de desenvolvimento orientado a especificações** feito inteiramente de skills e comandos em markdown. Ele dá a um agente de IA uma pipeline repetível para transformar um pedido vago de feature em uma feature totalmente implementada e revisada — sem overthinking e sem pular as perguntas difíceis.

Não é código-fonte. Não há build system. Tudo vive em `commands/` (comandos do playbook visíveis ao usuário) e `skills/` (instruções dos subagentes).

## Como funciona

Cada feature percorre uma pipeline enxuta:

```
0. config              lê .yasdd/config.yml
0b. CONVENTIONS check  se .yasdd/CONVENTIONS.md ausente → architect vai semear
1. ELICITATION         elicitação em lote tierada (core 8 + extended 10 se complexo/greenfield)  (sessão principal)  → ELICITATION.md
2. ARCHITECTURE        componentes [M#] + batches paralelos + testing + rules/cases/acceptance + self-check 10 pontos  (sessão principal)  → ARCHITECTURE.md + STATE.md
3. GATE                autoMode? true → prosseguir; false → perguntar ao usuário
4. IMPLEMENT LOOP      por batch, paralelo (até maxParallelism): implementadores code-only por componente [M#] → marca como feito (sem checks)
5. TEST                UM tester escreve testes unitários + e2e + roda os checks uma vez (do ARCHITECTURE, herdado do CONVENTIONS.md) sobre a feature inteira
5b. FIX-LOOP           se houver bugs: orquestrador escreve fix-plan inline → implementador com "rode todos os checks" → re-testa (máx 3 rodadas)
6. FINAL VERIFY        UMA revisão a nível de feature + rerun de checks (incondicional) sobre código + testes (máx 3 rodadas)
7. WRAP UP             atualiza o estado do projeto
```

ELICITATION e ARCHITECTURE rodam na sessão principal reutilizando o contexto de código carregado (zero re-exploração); IMPLEMENT/TEST/VERIFY rodam como subagentes isolados com contexto limpo.

Cinco ideias centrais fazem o yasdd funcionar:

- **Implementação a nível de arquitetura, particionada por componente**: o ARCHITECTURE.md contém o conteúdo de specs (Rules/Cases/Acceptance com anchors) + arquitetura de testes + plano de batches paralelos. A implementação é guiada por `Components [M#]` — o todo-list natural do LLM se torna o plano. Sem passo de decomposição de specs.
- **Acceptance = Given/When/Then**: o caminho feliz + cada Case, cada um verificável por um teste. Isso torna a regra de "arquitetura funcionando" verificável, e não autorreportada.
- **Reuso de contexto na sessão principal**: ELICITATION e ARCHITECTURE rodam inline na sessão principal, reutilizando o contexto de código carregado durante a elicitação — sem subagentes de re-exploração, menor uso de tokens.
- **Implementação paralela via testes adiados**: o implementador é code-only (sem testes, sem checks) para que componentes com conjuntos de arquivos disjuntos possam rodar em batches paralelos (pré-computados na seção `Parallel batches` do ARCHITECTURE). O tester escreve todos os testes + roda os checks uma vez após todos os componentes pousarem. Mid-flight batch update (em memória) lida com conflitos de arquivo imprevistos.
- **Verificação única a nível de feature**: em vez de um verificador por spec, um único verificador roda após a fase TEST — ele executa os checks uma vez (rerun incondicional; comandos herdados do CONVENTIONS.md via ARCHITECTURE) sobre todos os arquivos alterados (código + testes) e revisa o diff inteiro da feature para conformidade + code review, depois atribui os achados aos componentes `[M#]` para roteamento. Menor uso de tokens, contexto compartilhado.
- **Protocolo FINISHED/ISSUES**: o implementador (e o tester) terminam sua saída com um token de status. O orquestrador o analisa: `FINISHED` → marcar como feito; `ISSUES` → mostrar ao usuário (ou, em autoMode, marcar o componente como bloqueado e continuar).

## Comandos

| Comando | O que faz |
| --- | --- |
| `/yasdd` | Inicia uma nova feature: elicitação → arquitetura (com self-check + batches + testing) → gate → implementar por componente → test → verify. |
| `/yasdd-quick-win` | Inicia um quick win em um único fluxo: elicitação → uma arquitetura fusionada → implementação → revisão leve. |
| `/yasdd-implement <slug>` | Retoma a implementação dos componentes de uma feature a partir do STATE.md. |
| `/yasdd-continue` | Retoma **todas** as features em andamento que ainda têm componentes pendentes. |
| `/yasdd-status [slug]` | Mostra o status do projeto e dos componentes da feature. |
| `/yasdd-goback <slug>` | Atualiza uma feature já implementada escrevendo UM novo delta CHANGES/NN. |
| `/yasdd-doubt <slug>` | Explica uma feature implementada de forma concisa (somente leitura). |
| `/yasdd-init` | Inicializa o yasdd em um projeto (scaffolding + AGENTS.md). |
| `/yasdd-clear` | Remove todas as features, quick-wins, CHANGES e CONVENTIONS.md; reseta o PROJECT-STATE.md (destrutivo). |

## Skills (fases e subagentes)

| Skill | Papel |
| --- | --- |
| `yasdd-elicitation` | Elicitação em lote tierada (core 8 + extended 10 se complexo/greenfield); detecção greenfield → semeia CONVENTIONS.md; watchlist Christel & Kang por rodada; escreve ELICITATION.md. (sessão principal) |
| `yasdd-quick-elicitation` | Elicitação em lote core-only para quick win (8 seções, sem extended); detecção greenfield; escreve `.yasdd/quick-wins/<slug>/ELICITATION.md`. (sessão principal) |
| `yasdd-architect` | Escreve ARCHITECTURE.md; absorve Rules/Cases/Acceptance + Testing + Parallel batches; self-check 10 pontos (cap 3 iterações); awareness de custo de tokens; herança CONVENTIONS.md. (sessão principal) |
| `yasdd-quick-architect` | Fusiona design + uma arquitetura enxuta para quick win; formato simplificado (sem Components/batches/[M#]); Testing herda CONVENTIONS.md; escreve `.yasdd/quick-wins/<slug>/ARCHITECTURE.md`. (sessão principal) |
| `yasdd-implementer` | Implementa UM componente `[M#]`: leituras focadas, **code-only** (sem testes, sem checks), tabela de conformidade dividida (architecture-conformance auto-verificada; functioning DEFERRED) + manifesto de arquivos alterados, incrementa SUMMARY.md, retorna FINISHED/ISSUES. (subagente) |
| `yasdd-tester` | Escreve testes unitários + e2e após todos os componentes pousarem; lê ARCHITECTURE.md (Testing + Acceptance `[A#]`); roda os checks uma vez (comandos herdados do CONVENTIONS.md via ARCHITECTURE); retorna FINISHED + manifesto de testes, ou ISSUES com achados classificados (test-bug vs impl-bug, atribuídos aos componentes `[M#]`). (subagente) |
| `yasdd-verifier` | UMA revisão a nível de feature somente pesquisa de código **+ testes** + um **rerun de checks** (incondicional; roda lint/typecheck/tests uma vez por feature, sobre todos os arquivos alterados; comandos herdados do CONVENTIONS.md via ARCHITECTURE). Atribui achados aos componentes `[M#]`. (subagente) |
| `yasdd-goback` | Atualiza uma feature implementada com um delta CHANGES/NN em formato ARCHITECTURE. (sessão principal) |
| `yasdd-doubt` | Explica uma feature (somente leitura). (sessão principal) |
| `yasdd-init` | Cria o `.yasdd/` e a config; NÃO cria CONVENTIONS.md. (sessão principal) |
| `yasdd-clear` | Limpa features, quick-wins, CHANGES e CONVENTIONS.md (mantém a config). (sessão principal) |

### yasdd-spy (agente de exploração de codebase)

O yasdd inclui um subagente dedicado e **leve**, `yasdd-spy`, para toda exploração de codebase e rastreamento de features. Ele é definido em `agents/yasdd-spy.md` (frontmatter: `name`, `description`, `mode: subagent`) e projetado para rodar em um modelo rápido e barato (ex.: `anthropic/claude-haiku-4-5`) para que as fases de ELICITATION, GOBACK e VERIFY possam lançar múltiplos spies em paralelo sem custo significativo de tokens.

**Desenvolvedores devem usar o `yasdd-spy`** (não o agente genérico `explore` do harness) sempre que uma skill ou comando pedir investigação do codebase. O spy rastreia implementações de feature dos entry points até o armazenamento de dados, retornando referências `file:line` e listas de arquivos essenciais. Ele também detecta repos **greenfield** (sem arquivos fonte) e retorna um sinal de greenfield para que a skill de elicitação semeie o `CONVENTIONS.md`.

Para configurar um modelo específico, edite `agents/yasdd-spy.md` e adicione ou altere um campo `model:` no frontmatter (suporte depende do agent harness).

## Início rápido

1. Rode `/yasdd-init` uma vez no seu projeto (cria `.yasdd/`, `config.yml`, `PROJECT-STATE.md` e atualiza `AGENTS.md`).
2. Rode `/yasdd` e responda às perguntas em lote sobre sua feature.
3. A pipeline cria `ELICITATION.md → ARCHITECTURE.md → STATE.md` (tudo na sessão principal), e depois pede para prosseguir (a menos que `autoMode: true`).
4. O orquestrador lê os `Parallel batches` do ARCHITECTURE; implementadores rodam code-only em paralelo por batch (até `maxParallelism`), um por componente `[M#]`. Depois UM tester escreve todos os testes + roda os checks uma vez (comandos herdados do CONVENTIONS.md via ARCHITECTURE). Depois UMA verificação a nível de feature roda sobre código + testes (corrigir → re-testar/re-verificar, até 3× cada).
5. Pronto? Um `SUMMARY.md` já cresceu com um bullet por implementação nas seções `## Business` (linguagem de PM), `## Implemented` (arquitetura) e `## Files` (arquivos alterados); o `PROJECT-STATE.md` é atualizado.

## Configuração

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = arquitetura → direto para implementação (sem pausa no gate)
maxParallelism: 3    # limite de chamadas de subagentes paralelos por passo + tamanho do batch
```

Comandos de check (lint, typecheck, test) são **do projeto todo**, capturados uma vez no `.yasdd/CONVENTIONS.md` (semeado pela elicitação em greenfield, ou pelo architect no brownfield na primeira feature). Cada ARCHITECTURE.md herda eles. Isso elimina a redescoberta de framework de testes por feature.

## CONVENTIONS.md

Um arquivo a nível de projeto em `.yasdd/CONVENTIONS.md` captura as convenções técnicas do projeto **uma vez** para que cada ARCHITECTURE.md herde em vez de redescobrir:

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
| **Greenfield (primeira feature)** | O sub-passo "Technical environment decision" da elicitação semeia antes da arquitetura rodar |
| **Brownfield (sem CONVENTIONS.md ainda)** | O architect detecta do `package.json`/`Makefile`/`AGENTS.md` na primeira feature, escreve para que as subsequentes herdem |
| **Já existe** | O architect herda (nunca re-decide); a elicitação pula o sub-passo de technical-environment |

`/yasdd-init` NÃO cria CONVENTIONS.md — é semeado pela elicitação/architect na primeira feature, não no tempo de init (init não sabe a tech stack ainda).

## Onde fica cada coisa

```
.yasdd/
  config.yml
  CONVENTIONS.md                     # convenções técnicas do projeto (semeado uma vez, herdado por todas as features)
  PROJECT-STATE.md                   # todas as features em um resumo
  features/<slug>/
    ELICITATION.md                   # tierada: core 8 + extended 10 (se complexo/greenfield)
    ARCHITECTURE.md                  # componentes [M#] + batches + testing + rules/cases/acceptance
    STATE.md                         # status por componente impl/test/verify
    SUMMARY.md                       # Business / Implemented / Files (incrementado por implementação)
    CHANGES/NN-<change-slug>.md      # deltas do goback em formato ARCHITECTURE
  quick-wins/<slug>/
    ELICITATION.md                   # core-only (8 seções)
    ARCHITECTURE.md                  # formato simplificado (sem Components/batches/[M#])
    SUMMARY.md                       # Business / Implemented / Files
```

Marcadores de status dos componentes no STATE.md: `- [ ]` não iniciado · `- [~]` bloqueado (falhou teste ou verify) · `- [x]` totalmente feito (impl + test + verify). Cada componente tem sub-markers `impl`/`test`/`verify` para roteamento preciso do fix-loop.

### Quick wins

`/yasdd-quick-win` colapsa a pipeline SDD completa em um fluxo stateless de um único disparo:

```
ELICITATION (core-only) → ARCHITECTURE (simplificado, sessão principal) → IMPLEMENTAÇÃO (code-only) → TEST → REVISÃO LEVE DE CÓDIGO
```

- Um `ARCHITECTURE.md` por quick win — sem diretório `specs/`, sem `Components` com `[M#]`, sem `Parallel batches`.
- Sem `STATE.md`; inspecione a pasta diretamente.
- Sem atualizações no `PROJECT-STATE.md`.
- A seção Testing herda do CONVENTIONS.md (ou detecta em runtime se ausente).

## Suporte a greenfield

O yasdd detecta repos greenfield (sem arquivos fonte) via `yasdd-spy` e lida com eles graciosamente:

- `yasdd-spy` retorna "greenfield — no existing source files found" em vez de falhar.
- A skill de elicitação injeta um sub-passo "Technical environment decision" (linguagem, framework, test runner, lint, estrutura de diretórios).
- Essas decisões semeiam o `CONVENTIONS.md` antes da arquitetura rodar.
- A primeira feature é tratada como **definidora de arquitetura** — o architect escreve a estrutura fundacional (layout de diretórios, utilitários compartilhados, configuração base).
- Features subsequentes herdam o `CONVENTIONS.md` — sem re-decidir.

Isso NÃO adiciona um passo separado de scaffolding — se dobra naturalmente no fluxo existente elicitação → arquitetura.
