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

Cada feature percorre uma pipeline de 6 passos:

```
0. config          lê .yasdd/config.yml
1. DISCUSS         interroga o usuário até a feature estar sem lacunas  → DISCUSS.md
2. DESIGN          design pragmático a partir da discussão                → DESIGN.md
3. SPECS           decompõe o design em 1..maxSpecs specs                 → specs/*.md + STATE.md
4. PLAN            escolhe quais specs implementar agora (ou todos em autoMode)
5. IMPLEMENT LOOP  por spec, sequencial: implementador → verificador → re-loop (máx 3)
6. WRAP UP         atualiza o estado do projeto
```

Três ideias centrais fazem o yasdd funcionar:

- **Specs enxutas**: cada spec é uma página única (Refs / Goal / I/O / Rules / Scenarios / **Acceptance** / Out of scope). Sem enchimento de prosa.
- **Acceptance = Given/When/Then**: o caminho feliz + cada Cenário, cada um verificável por um teste. Isso torna a regra de "spec funcionando" verificável, e não autorreportada.
- **Protocolo FINISHED/ISSUES**: o implementador termina sua saída com um token de status. O orquestrador o analisa: `FINISHED` → verificar; `ISSUES` → mostrar ao usuário (ou, em autoMode, marcar o spec como bloqueado com `- [~]` e continuar).

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

## Skills (subagentes)

| Skill | Papel |
| --- | --- |
| `yasdd-discuss` | Elicitação em lote; escreve DISCUSS.md. |
| `yasdd-quick-discuss` | Elicitação em lote para quick win; escreve `.yasdd/quick-wins/<slug>/DISCUSS.md`. |
| `yasdd-designer` | Escreve DESIGN.md; define componentes, dados, interfaces, riscos, **Non-functional** (NFRs). |
| `yasdd-specs` | Decompõe o DESIGN em specs; carrega NFRs para as Rules dos specs. |
| `yasdd-quick-spec` | Fusiona design + um spec enxuto para quick win; escreve `.yasdd/quick-wins/<slug>/SPEC.md`. |
| `yasdd-implementer` | Implementa UM spec: leituras focadas, código + testes mínimos, tabela de conformidade, incrementa SUMMARY.md (Business/Implemented/Files), retorna FINISHED/ISSUES. Reutilizado por quick wins com override de caminho. |
| `yasdd-verifier` | Revisão multi-track somente pesquisa + um **gate de testes verdes** (roda lint/typecheck/tests antes das tracks). Reutilizado por quick wins com override mais leve de uma única track. |
| `yasdd-goback` | Atualiza uma feature implementada com um novo spec. |
| `yasdd-doubt` | Explica uma feature (somente leitura). |
| `yasdd-init` | Cria o `.yasdd/` e a config. |
| `yasdd-clear` | Limpa as features (mantém a config). |

## Início rápido

1. Rode `/yasdd-init` uma vez no seu projeto (cria `.yasdd/`, `config.yml`, `PROJECT-STATE.md` e atualiza `AGENTS.md`).
2. Rode `/yasdd` e responda às perguntas em lote sobre sua feature.
3. A pipeline cria `DISCUSS.md → DESIGN.md → specs/ → STATE.md`, e depois oferece para implementar.
4. Os specs são implementados sequencialmente: implementador → verificador → (corrigir → reverificar, até 3×).
5. Pronto? Um `SUMMARY.md` já cresceu com um bullet por implementação nas seções `## Business` (linguagem de PM), `## Implemented` (arquitetura) e `## Files` (arquivos alterados); o `PROJECT-STATE.md` é atualizado.

## Configuração

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = implementa todos os specs sem perguntar
maxParallelism: 3    # limite de chamadas de subagentes paralelos por passo
maxSpecs: 5          # limite de specs gerados a partir de um DESIGN
```

## Onde fica cada coisa

```
.yasdd/
  config.yml
  PROJECT-STATE.md                 # todas as features em um resumo
  features/<slug>/
    DISCUSS.md
    DESIGN.md
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
DISCUSS → SPEC (design + spec fusionados) → IMPLEMENTAÇÃO → REVISÃO LEVE DE CÓDIGO
```

- Um `SPEC.md` por quick win — sem diretório `specs/`.
- Sem `STATE.md`; inspecione a pasta diretamente.
- Sem atualizações no `PROJECT-STATE.md`.
