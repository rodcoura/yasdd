# yasdd

> Yell At Specs, Design Directly — 一条务实的、纯 markdown 的流水线, 专为 AI 编程代理设计。

**语言:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## 安装

yasdd 是纯 markdown —— 无构建步骤, 无依赖。把 `skills/` 和 `commands/` 放到你的 agent harness 读取的位置。任选其一:

- **全局(所有项目):** `~/.agents/` —— 即 `~/.agents/skills/yasdd-*/SKILL.md` 与 `~/.agents/commands/yasdd*.md`。
- **项目内(单个仓库):** 项目根目录的 `.agents/` —— `.agents/skills/...` 与 `.agents/commands/...`。
- **自定义:** 你的 agent harness 加载 skills/commands 的任何文件夹。

为每个 skill + command 建立软链接(若该文件夹已存有其他 skills, 此操作安全):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# 全局安装
mkdir -p ~/.agents/skills ~/.agents/commands ~/.agents/prompts
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
for c in ~/projects/yasdd/commands/*.md; do ln -sf "$c" ~/.agents/commands/; done
for p in ~/projects/yasdd/prompts/*.md; do ln -sf "$p" ~/.agents/prompts/; done
```

项目内安装则把循环中的 `~/.agents/` 换成 `.agents/`。然后在项目中运行 `/yasdd-init` 创建 `.yasdd/` 并更新 `AGENTS.md`。

---

## yasdd 是什么?

yasdd 是一个**规范驱动开发框架**, 完全由 markdown 技能和命令构成。它为 AI 编程代理提供了一条可重复的流水线, 把模糊的功能需求转化为完全实现并经过评审的功能——既不过度思考, 也不跳过棘手的问题。

它不是源代码, 也没有构建系统。一切都在 `commands/`(用户可见的 playbook 命令)和 `skills/`(子代理指令)中。

## 工作原理

每个功能都经过一条精简流水线:

```
0. config              读取 .yasdd/config.yml
0b. CONVENTIONS check  若 .yasdd/CONVENTIONS.md 缺失 → architect 将播种
1. ELICITATION         分层批量引导 (core 8 + extended 10 若复杂/greenfield)  (主会话)  → ELICITATION.md
2. ARCHITECTURE        组件 [M#] + 并行批次 + 测试 + rules/cases/acceptance + 10 点自检  (主会话)  → ARCHITECTURE.md + STATE.md
3. GATE                autoMode? true → 继续; false → 询问用户
4. IMPLEMENT LOOP      按批次并行(至 maxParallelism): 每组件 [M#] 纯代码实现者 → 标记完成(无检查)
5. TEST                一个测试者编写单元 + e2e 测试 + 运行一次检查(来自 ARCHITECTURE, 继承自 CONVENTIONS.md)覆盖整个功能
5b. FIX-LOOP           若有 bug: 编排器内联写修复计划 → 实现者带"运行所有检查" → 重新测试(最多 3 轮)
6. FINAL VERIFY        一次功能级评审 + 检查重跑(无条件)覆盖代码 + 测试(最多 3 轮)
7. WRAP UP             更新项目状态
```

ELICITATION 和 ARCHITECTURE 在主会话中运行, 复用已加载的代码上下文(零重复探索); IMPLEMENT/TEST/VERIFY 作为隔离子代理运行, 拥有干净上下文。

五个核心理念使 yasdd 有效:

- **架构级、组件分区实现**: ARCHITECTURE.md 包含规范内容(Rules/Cases/Acceptance 带 anchors) + 测试架构 + 并行批次计划。实现由 `Components [M#]` 驱动——LLM 的自然 todo-list 构建即成为计划。无需规范拆分步骤。
- **Acceptance = Given/When/Then**: 快乐路径 + 每个 Case, 每条都可用测试检验。这让"功能完整架构"规则可验证, 而非自我报告。
- **主会话上下文复用**: ELICITATION 和 ARCHITECTURE 在主会话中内联运行, 复用引导期间加载的代码上下文——无需重新探索子代理, 更低 token 用量。
- **通过延迟测试实现并行**: 实现者是纯代码(无测试、无检查), 因此文件集不相交的组件可按批次并行运行(在 ARCHITECTURE 的 `Parallel batches` 中预计算)。测试者在所有组件落地后编写所有测试 + 运行一次检查。Mid-flight 批次更新(内存中)处理未预见的文件冲突。
- **一次功能级验证**: 而非每个规范一个评审者, 在 TEST 阶段后运行唯一的评审者——它对所有变更文件(代码 + 测试)一次性运行检查(无条件重跑; 命令继承自 CONVENTIONS.md 经由 ARCHITECTURE), 并评审整个功能 diff 的合规性与代码审查, 然后将发现归属到组件 `[M#]` 以便路由。更低的 token 用量, 共享上下文。
- **FINISHED/ISSUES 协议**: 实现者(和测试者)以状态令牌结束输出。编排器解析它: `FINISHED` → 标记完成; `ISSUES` → 呈现给用户(或在 autoMode 下标记组件为阻塞并继续)。

## 命令

| 命令 | 作用 |
| --- | --- |
| `/yasdd` | 开启新功能: 引导 → 架构(含自检 + 批次 + 测试) → 门控 → 按组件实现 → 测试 → 验证。 |
| `/yasdd-quick-win` | 启动一次性的 quick win 流程: 引导 → 融合架构 → 实现 → 轻量评审。 |
| `/yasdd-implement <slug>` | 从 STATE.md 恢复实现单个功能的组件。 |
| `/yasdd-continue` | 恢复**所有**仍有待实现组件的功能。 |
| `/yasdd-status [slug]` | 打印项目与功能组件状态。 |
| `/yasdd-goback <slug>` | 通过编写一个 CHANGES/NN delta 来更新已实现的功能。 |
| `/yasdd-doubt <slug>` | 简洁解释已实现的功能(只读)。 |
| `/yasdd-init` | 为项目初始化 yasdd(脚手架 + AGENTS.md)。 |
| `/yasdd-clear` | 删除所有功能、quick-wins、CHANGES 和 CONVENTIONS.md; 重置 PROJECT-STATE.md(破坏性)。 |

## 技能(阶段与子代理)

| 技能 | 角色 |
| --- | --- |
| `yasdd-elicitation` | 分层批量引导(core 8 + extended 10 若复杂/greenfield); greenfield 检测 → 播种 CONVENTIONS.md; 每轮 Christel & Kang 监视清单; 编写 ELICITATION.md。(主会话) |
| `yasdd-quick-elicitation` | quick win core-only 引导(8 节, 无 extended); greenfield 检测; 编写 `.yasdd/quick-wins/<slug>/ELICITATION.md`。(主会话) |
| `yasdd-architect` | 编写 ARCHITECTURE.md; 吸收 Rules/Cases/Acceptance + Testing + Parallel batches; 10 点自检(cap 3 迭代); token 成本感知; CONVENTIONS.md 继承。(主会话) |
| `yasdd-quick-architect` | 融合设计 + 一个精简架构供 quick win; 简化格式(无 Components/batches/[M#]); Testing 继承 CONVENTIONS.md; 编写 `.yasdd/quick-wins/<slug>/ARCHITECTURE.md`。(主会话) |
| `yasdd-implementer` | 实现一个组件 `[M#]`: 范围化读取、**纯代码**(无测试、无检查)、拆分一致性表(架构一致性自验证; functioning 延迟) + 变更文件清单, 增量写入 SUMMARY.md, 返回 FINISHED/ISSUES。(子代理) |
| `yasdd-tester` | 在所有组件落地后编写单元 + e2e 测试; 读取 ARCHITECTURE.md(Testing + Acceptance `[A#]`); 运行一次检查(命令继承自 CONVENTIONS.md 经由 ARCHITECTURE); 返回 FINISHED + 测试清单, 或 ISSUES 带分类发现(测试 bug vs 实现 bug, 归属到组件 `[M#]`)。(子代理) |
| `yasdd-verifier` | 一次功能级仅研究评审代码 **+ 测试** + 一次**检查重跑**(无条件; 每个功能对所有变更文件运行一次 lint/typecheck/tests; 命令继承自 CONVENTIONS.md 经由 ARCHITECTURE)。将发现归属到组件 `[M#]`。(子代理) |
| `yasdd-goback` | 用一个 CHANGES/NN delta(ARCHITECTURE 格式)更新已实现的功能。(主会话) |
| `yasdd-doubt` | 解释功能(只读)。(主会话) |
| `yasdd-init` | 创建 `.yasdd/` 与配置; 不创建 CONVENTIONS.md。(主会话) |
| `yasdd-clear` | 清除功能、quick-wins、CHANGES 和 CONVENTIONS.md(保留配置)。(主会话) |

### yasdd-spy(代码库探索代理)

yasdd 附带一个专用的**轻量级**子代理 `yasdd-spy`,用于所有代码库探索和功能追踪任务。它定义在 `agents/yasdd-spy.md` 中(frontmatter: `name`、`description`、`mode: subagent`),设计用于快速、低成本的模型(如 `anthropic/claude-haiku-4-5`),使 ELICITATION、GOBACK 和 VERIFY 阶段可以并行启动多个 spy 而不会产生显著的 token 开销。

**开发者应使用 `yasdd-spy`**(而非 harness 的通用 `explore` 代理)来进行技能或命令要求的代码库调查。spy 从入口点到数据存储追踪功能实现,返回 `file:line` 引用和关键文件列表。它还检测 **greenfield** 仓库(无源文件)并返回 greenfield 信号,以便引导技能播种 `CONVENTIONS.md`。

要配置特定模型,请编辑 `agents/yasdd-spy.md` 并添加或更改 frontmatter 中的 `model:` 字段(支持取决于你的 agent harness)。

## 快速开始

1. 在项目中运行一次 `/yasdd-init`(创建 `.yasdd/`、`config.yml`、`PROJECT-STATE.md` 并更新 `AGENTS.md`)。
2. 运行 `/yasdd` 并回答关于你功能的批量提问。
3. 流水线编写 `ELICITATION.md → ARCHITECTURE.md → STATE.md`(全部在主会话中), 然后请求继续(除非 `autoMode: true`)。
4. 编排器读取 ARCHITECTURE 的 `Parallel batches`; 实现者按批次纯代码并行(至 `maxParallelism`), 每组件 `[M#]` 一个。然后一个测试者编写所有测试 + 运行一次检查(命令继承自 CONVENTIONS.md 经由 ARCHITECTURE)。然后对整个功能运行一次功能级验证(代码 + 测试)(修复 → 重新测试/重新验证, 各最多 3 次)。
5. 完成? `SUMMARY.md` 已随每次实现分别在 `## Business`(PM 语言)、`## Implemented`(架构)、`## Files`(变更文件) 下新增一条要点; `PROJECT-STATE.md` 已更新。

## 配置

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = 架构 → 直接实现(无门控暂停)
maxParallelism: 3    # 每步并行子代理调用上限 + 批次大小
```

检查命令(lint、typecheck、test)是**项目级**的, 一次性捕获在 `.yasdd/CONVENTIONS.md` 中(greenfield 由引导播种, 或 brownfield 首个功能由 architect 检测)。每个 ARCHITECTURE.md 继承它们。这消除了每功能的测试框架重新发现。

## CONVENTIONS.md

一个项目级文件 `.yasdd/CONVENTIONS.md` 一次性捕获项目的技术约定, 以便每个 ARCHITECTURE.md 继承而非重新发现:

```md
# Project Conventions

## Tech stack
Language: <如 TypeScript 5.4>
Framework: <如 Express 4, Next.js 14, FastAPI 0.110>
Runtime: <如 Node 20, Python 3.12>

## Test
Framework: <如 Vitest 1.6, pytest 8.2>
Runner cmd: <如 npm test, pytest>
Test location: <如 src/**/*.test.ts, tests/**/test_*.py>

## Quality gates
Lint cmd: <如 npm run lint, ruff check>
Typecheck cmd: <如 npm run typecheck, tsc --noEmit, mypy>

## Directory structure
Source: <如 src/>
Tests: <如 src/ (colocated), tests/ (separate)>
Config: <如 .env, config/>
```

| 场景 | CONVENTIONS.md 何时创建 |
|----------|--------------------------------|
| **Greenfield(首个功能)** | 引导的"Technical environment decision"子步骤在架构运行前播种 |
| **Brownfield(尚无 CONVENTIONS.md)** | architect 在首个功能从 `package.json`/`Makefile`/`AGENTS.md` 检测, 写入以便后续继承 |
| **已存在** | architect 继承(从不重新决定); 引导跳过 technical-environment 子步骤 |

`/yasdd-init` 不创建 CONVENTIONS.md — 由引导/architect 在首个功能播种, 非 init 时(init 还不知道技术栈)。

## 目录结构

```
.yasdd/
  config.yml
  CONVENTIONS.md                     # 项目级技术约定(播种一次, 所有功能继承)
  PROJECT-STATE.md                   # 所有功能一览
  features/<slug>/
    ELICITATION.md                   # 分层: core 8 + extended 10(若复杂/greenfield)
    ARCHITECTURE.md                  # 组件 [M#] + 批次 + 测试 + rules/cases/acceptance
    STATE.md                         # 每组件 impl/test/verify 状态
    SUMMARY.md                       # Business / Implemented / Files (每次实现追加)
    CHANGES/NN-<change-slug>.md      # goback delta(ARCHITECTURE 格式)
  quick-wins/<slug>/
    ELICITATION.md                   # core-only(8 节)
    ARCHITECTURE.md                  # 简化格式(无 Components/batches/[M#])
    SUMMARY.md                       # Business / Implemented / Files
```

STATE.md 中的组件状态标记: `- [ ]` 未开始 · `- [~]` 阻塞(测试或验证失败) · `- [x]` 完全完成(impl + test + verify)。每个组件有 `impl`/`test`/`verify` 子标记, 用于精确的 fix-loop 路由。

### Quick wins

`/yasdd-quick-win` 把完整 SDD 流水线折叠成单次、无状态的流程:

```
ELICITATION (core-only) → ARCHITECTURE (简化, 主会话) → 实现纯代码 → TEST → 轻量代码评审
```

- 每个 quick win 只有一个 `ARCHITECTURE.md` —— 没有 `specs/` 目录, 没有 `Components` `[M#]`, 没有 `Parallel batches`。
- 没有 `STATE.md`; 直接查看对应文件夹。
- 不更新 `PROJECT-STATE.md`。
- Testing 节继承自 CONVENTIONS.md(或缺失时运行时检测)。

## Greenfield 支持

yasdd 通过 `yasdd-spy` 检测 greenfield 仓库(无源文件)并优雅处理:

- `yasdd-spy` 返回 "greenfield — no existing source files found" 而非失败。
- 引导技能注入"Technical environment decision"子步骤(语言、框架、测试运行器、lint、目录结构)。
- 这些决策在架构运行前播种 `CONVENTIONS.md`。
- 首个功能被视为**架构定义性**的 — architect 编写基础结构(目录布局、共享工具、基础配置)。
- 后续功能继承 `CONVENTIONS.md` — 无需重新决定。

这不增加单独的脚手架步骤 — 自然融入现有的引导 → 架构流程。
