# yasdd

> Yet Another Spec-Driven Development framework — uma pipeline SDD pragmática, apenas em markdown, para agentes de IA.

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

Cada feature percorre uma pipeline de 8 passos:

```
0. config          lê .yasdd/config.yml
1. DISCUSS         interroga o usuário até a feature estar sem lacunas  (sessão principal)  → DISCUSS.md
2. DESIGN          design pragmático a partir da discussão              (sessão principal)  → DESIGN.md
2b. TESTING        handoff da arquitetura de testes                     (sessão principal)  → TESTING.md
3. SPECS           decompõe o design em 1..maxSpecs specs                (sessão principal)  → specs/*.md + STATE.md
4. PLAN            escolhe quais specs implementar agora + computa batches paralelos a partir dos Refs
5. IMPLEMENT LOOP  por batch, paralelo (até maxParallelism): implementadores code-only → marca como feito (sem gate)
6. TEST            UM tester escreve testes unitários + e2e + roda o gate uma vez sobre a feature inteira
6b. FIX-LOOP       se houver bugs: orquestrador escreve fix-plan inline → implementador com "rode todos os checks" → re-testa (máx 3 rodadas)
7. FINAL VERIFY    UMA revisão a nível de feature + gate de testes verdes (rerun incondicional) sobre código + testes (máx 3 rodadas)
8. WRAP UP         atualiza o estado do projeto
```

DISCUSS/DESIGN/TESTING/SPECS rodam na sessão principal reutilizando o contexto de código carregado (zero re-exploração); IMPLEMENT/TEST/VERIFY rodam como subagentes isolados com contexto limpo.

Cinco ideias centrais fazem o yasdd funcionar:

- **Specs enxutas e auto-suficientes**: cada spec é uma página única (Refs / Goal / I/O / Data / Interfaces / Rules / Scenarios / **Acceptance** / Out of scope) — carrega as formas de dados concretas e as assinaturas de interface necessárias para implementá-lo, então o implementador nunca precisa do DESIGN.md. Sem enchimento de prosa.
- **Acceptance = Given/When/Then**: o caminho feliz + cada Cenário, cada um verificável por um teste. Isso torna a regra de "spec funcionando" verificável, e não autorreportada.
- **Reuso de contexto na sessão principal**: DESIGN, TESTING e SPECS rodam inline na sessão principal, reutilizando o contexto de código carregado durante o DISCUSS — sem subagentes de re-exploração, menor uso de tokens.
- **Implementação paralela via testes adiados**: o implementador é code-only (sem testes, sem gate) para que specs com conjuntos de arquivos disjuntos possam rodar em batches paralelos. O tester escreve todos os testes + roda o gate uma vez após todos os specs pousarem. O orquestrador computa batches paralelos a partir dos `Refs` dos specs + `Components` do DESIGN (julgamento da IA, inline — sem script).
- **Verificação única a nível de feature**: em vez de um verificador por spec, um único verificador roda após a fase TEST — ele executa o gate de testes verdes uma vez (rerun incondicional) sobre todos os arquivos alterados (código + testes) e revisa o diff inteiro da feature para conformidade + code review, depois atribui os achados aos specs para roteamento. Menor uso de tokens, contexto compartilhado.
- **Protocolo FINISHED/ISSUES**: o implementador (e o tester) terminam sua saída com um token de status. O orquestrador o analisa: `FINISHED` → marcar como feito; `ISSUES` → mostrar ao usuário (ou, em autoMode, marcar o spec como bloqueado com `- [~]` e continuar).

## Comandos

| Comando | O que faz |
| --- | --- |
| `/yasdd` | Inicia uma nova feature: discutir → projetar → specs → estado, depois oferece para implementar. |
| `/yasdd-quick-win` | Inicia um quick win em um único fluxo: discutir → spec única fusionada → implementação → revisão leve. |
| `/yasdd-implement <slug>` | Retoma a implementação dos specs de uma feature a partir do STATE.md. |
| `/yasdd-continue` | Retoma **todas** as features em andamento que ainda têm specs pendentes. |
| `/yasdd-status [slug]` | Mostra o status do projeto e dos specs da feature. |
| `/yasdd-goback <slug>` | Atualiza uma feature já implementada escrevendo UM novo spec. |
| `/yasdd-doubt <slug>` | Explica uma feature implementada de forma concisa (somente leitura). |
| `/yasdd-init` | Inicializa o yasdd em um projeto (scaffolding + AGENTS.md). |
| `/yasdd-clear` | Remove todas as features e reseta o PROJECT-STATE.md (destrutivo). |

## Skills (fases e subagentes)

| Skill | Papel |
| --- | --- |
| `yasdd-discuss` | Elicitação em lote; escreve DISCUSS.md. (sessão principal) |
| `yasdd-quick-discuss` | Elicitação em lote para quick win; escreve `.yasdd/quick-wins/<slug>/DISCUSS.md`. (sessão principal) |
| `yasdd-designer` | Escreve DESIGN.md; define componentes, dados, interfaces, riscos, **Non-functional** (NFRs); particiona specs por limites de módulo/arquivo. (sessão principal) |
| `yasdd-test-design` | Escreve TESTING.md (handoff da arquitetura de testes) logo após o DESIGN. (sessão principal) |
| `yasdd-specs` | Decompõe o DESIGN em specs; carrega NFRs para as Rules dos specs; cada `Refs` declara o escopo de arquivos para a computação de batches paralelos. (sessão principal) |
| `yasdd-quick-spec` | Fusiona design + um spec enxuto para quick win; escreve `.yasdd/quick-wins/<slug>/SPEC.md`. (sessão principal) |
| `yasdd-implementer` | Implementa UM spec: leituras focadas, **code-only** (sem testes, sem gate), tabela de conformidade dividida (spec-conformance auto-verificada; functioning DEFERRED) + manifesto de arquivos alterados, incrementa SUMMARY.md, retorna FINISHED/ISSUES. (subagente) |
| `yasdd-tester` | Escreve testes unitários + e2e após todos os specs pousarem; lê TESTING.md + tabelas de conformidade + manifesto; roda o gate uma vez; retorna FINISHED + manifesto de testes, ou ISSUES com achados classificados (test-bug vs impl-bug). (subagente) |
| `yasdd-verifier` | UMA revisão a nível de feature somente pesquisa de código **+ testes** + um **gate de testes verdes** (rerun incondicional; roda lint/typecheck/tests uma vez por feature, sobre todos os arquivos alterados). (subagente) |
| `yasdd-goback` | Atualiza uma feature implementada com um novo spec. (sessão principal) |
| `yasdd-doubt` | Explica uma feature (somente leitura). (sessão principal) |
| `yasdd-init` | Cria o `.yasdd/` e a config. (sessão principal) |
| `yasdd-clear` | Limpa as features (mantém a config). (sessão principal) |

### yasdd-spy (agente de exploração de codebase)

O yasdd inclui um subagente dedicado e **leve**, `yasdd-spy`, para toda exploração de codebase e rastreamento de features. Ele é configurado com um modelo rápido e barato (ex.: `anthropic/claude-haiku-4-5`) para que as fases de DISCUSS, GOBACK e VERIFY possam lançar múltiplos spies em paralelo sem custo significativo de tokens.

**Desenvolvedores devem usar o `yasdd-spy`** (não o agente genérico `explore` do harness) sempre que uma skill ou comando pedir investigação do codebase. O spy rastreia implementações de feature dos entry points até o armazenamento de dados, retornando referências `file:line` e listas de arquivos essenciais.

Para usar um modelo leve diferente, edite `agents/yasdd-spy.md` e altere o campo `model:` no frontmatter.

## Início rápido

1. Rode `/yasdd-init` uma vez no seu projeto (cria `.yasdd/`, `config.yml`, `PROJECT-STATE.md` e atualiza `AGENTS.md`).
2. Rode `/yasdd` e responda às perguntas em lote sobre sua feature.
3. A pipeline cria `DISCUSS.md → DESIGN.md → TESTING.md → specs/ → STATE.md` (tudo na sessão principal), e depois oferece para implementar.
4. O orquestrador computa batches paralelos a partir dos `Refs` dos specs + `Components` do DESIGN; implementadores rodam code-only em paralelo por batch (até `maxParallelism`). Depois UM tester escreve todos os testes + roda o gate uma vez. Depois UMA verificação a nível de feature roda sobre código + testes (corrigir → re-testar/re-verificar, até 3× cada).
5. Pronto? Um `SUMMARY.md` já cresceu com um bullet por implementação nas seções `## Business` (linguagem de PM), `## Implemented` (arquitetura) e `## Files` (arquivos alterados); o `PROJECT-STATE.md` é atualizado.

## Configuração

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = implementa todos os specs sem perguntar
maxParallelism: 3    # limite de chamadas de subagentes paralelos por passo
maxSpecs: 5          # limite de specs gerados a partir de um DESIGN
gate:                # detectado uma vez no init; reusado por tester/verifier/fix-loop
  testCmd: ""        # ex.: "npm test"; vazio = detectar em runtime
  lintCmd: ""        # ex.: "npm run lint"; vazio = detectar em runtime
  typecheckCmd: ""   # ex.: "npm run typecheck"; vazio = detectar em runtime
```

## Onde fica cada coisa

```
.yasdd/
  config.yml
  PROJECT-STATE.md                 # todas as features em um resumo
  features/<slug>/
    DISCUSS.md
    DESIGN.md
    TESTING.md                     # handoff da arquitetura de testes (framework, localizações, fixtures, mapeamento de aceitação)
    MANIFEST.md                    # índice leve de spec/arquivo/dependência para computação de batches paralelos
    STATE.md                        # checklist de specs: [ ] [x] [~]
    SUMMARY.md                      # Business / Implemented / Files (incrementado por implementação)
    specs/NN-<spec-slug>.md
  quick-wins/<slug>/
    DISCUSS.md
    SPEC.md                         # design fusionado + um spec enxuto
    SUMMARY.md                      # Business / Implemented / Files
```

Marcadores de status dos specs: `- [ ]` não implementado · `- [x]` concluído · `- [~]` bloqueado.

### Quick wins

`/yasdd-quick-win` colapsa a pipeline SDD completa em um fluxo stateless de um único disparo:

```
DISCUSS → SPEC (design + spec fusionados, sessão principal) → IMPLEMENTAÇÃO (code-only) → TEST → REVISÃO LEVE DE CÓDIGO
```

- Um `SPEC.md` por quick win — sem diretório `specs/`.
- Sem `TESTING.md` (spec única — o tester deriva a arquitetura de testes do framework existente do projeto).
- Sem `STATE.md`; inspecione a pasta diretamente.
- Sem atualizações no `PROJECT-STATE.md`.
