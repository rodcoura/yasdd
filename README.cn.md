# yasdd

> Yell At Specs, Design Directly — 为 AI 编程代理打造的精简、纯 markdown 流水线。

**语言:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## 安装

yasdd 是纯 markdown — 无构建步骤、无依赖。将 `skills/` 放在 agent harness 读取的位置即可。

### 推荐: 安装脚本

`install-to-agents.sh` 脚本将 skills 复制到各工具实际扫描的位置:

```bash
# 从仓库检出运行
./install-to-agents.sh

# 或一行命令(下载 + 安装)
curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash

# 固定特定版本
YASDD_REF=<tag> curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
```

目标位置:

| 目录 | 内容 |
| --- | --- |
| `~/.agents/` | skills(跨工具镜像) |
| `~/.claude/` | skills(Claude Code 原生) |

### 手动: 符号链接

选择一个位置:

- **全局(所有项目):** `~/.agents/` — 得到 `~/.agents/skills/yasdd-*/SKILL.md`。
- **项目内(单个仓库):** 项目根目录的 `.agents/` — `.agents/skills/...`。
- **自定义:** agent harness 加载 skills 的任意文件夹。

为每个目录建立符号链接(若文件夹已有其他 skills 也安全):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# 全局安装
mkdir -p ~/.agents/skills
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
```

项目内安装则把循环中的 `~/.agents/` 换成 `.agents/`。

---

## yasdd 是什么?

yasdd 是一个**无规范的设计与交付框架**, 完全由 markdown 技能构成。它为 AI 编程代理提供一条可重复的流水线, 把模糊的功能需求转化为完全实现并经过评审的功能——既不过度思考, 也不跳过棘手的问题。它也有 bug 修复流水线: 调查根因 → 修复 → 验证。

它不是源代码, 也没有构建系统。一切都在一个目录中:

- `skills/` — 每个技能一个文件夹 (`<skill>/SKILL.md`); 包含 feature 和 bug 编排器、plan/grill 技能、investigator 技能和子代理指令。

## 工作原理

### Feature 流水线

每个功能都经过一条精简的、用户门控的流水线:

```
0. CONFIG     yasdd-feature 读取 .yasdd/config.yml(缺失则用默认值创建)
1. PLAN        grill + 探索 → PLAN.md(含 Test impact、[M#] anchors、内联并行标记)
2. GATE         用户阅读 PLAN.md → 接受 OR 要求修改 → 循环直到接受
3. IMPLEMENT    读取 PLAN.md → 按 [M#] 启动实现者子代理, 可并行处并行, 有依赖处顺序
4. GATE         若 autoMode:true → 跳过。若 false → 用户手动测试 → vibe-coding 修复循环直到 "no more issues"
5. TEST         一个测试者编写单元测试 + 确认受影响的测试通过 → 返回 FINISHED/ISSUES
6. VERIFY       一个验证者运行检查 + 评审 diff + 编写 SUMMARY.md(Business/Implemented/Files)
```

PLAN 在主会话中运行, 复用已加载的代码上下文(零重复探索); IMPLEMENT/TEST/VERIFY 作为隔离子代理运行, 拥有干净上下文。

### Bug 修复流水线

每个 bug 修复经过一条精简的、用户门控的流水线:

```
0. CONFIG       yasdd-bug 读取 .yasdd/config.yml(缺失则用默认值创建)
1. INVESTIGATE   追踪根因 + git blame + blast radius → FIX.md(含 fix steps [M#]、Test impact)
2. GATE          用户阅读 FIX.md → 接受根因 + 修复方案 OR 要求修改 → 循环直到接受
3. FIX           读取 FIX.md → 按 [M#] 启动实现者子代理, 纯代码, 可并行处并行
4. GATE          若 autoMode:true → 跳过。若 false → 用户手动测试 → vibe-coding 修复循环直到 "no more issues"
5. TEST          一个测试者编写回归单元测试 + 确认受影响的测试通过 → 返回 FINISHED/ISSUES
6. VERIFY        一个验证者运行检查 + 评审 diff + 编写 SUMMARY.md(Business/Implemented/Files)
```

INVESTIGATE 在主会话中运行, 复用已加载的代码上下文; FIX/TEST/VERIFY 作为隔离子代理运行, 拥有干净上下文。

使 yasdd 有效的核心理念:

- **一个 PLAN.md, 无规范拆分**: plan 技能对用户进行 grill(每次一个问题并附推荐答案), 启动 yasdd-spy 进行代码库调查, 编写唯一的 PLAN.md, 包含组件 `[M#]` + 内联并行标记 + Rules/Cases/Acceptance 带 anchors + Test impact。无单独的 elicitation/architecture 产物。
- **内联并行标记**: 步骤携带 `*parallel with N*` 或 `*depends on N*` 标记 — 无单独的 "Parallel batches" 节。编排器(feature 或 bug)读取标记决定并行 vs 顺序。
- **Acceptance = Given/When/Then**: 快乐路径 + 每个 Case, 每条都可用测试检验。这让 plan 可验证而非自我报告。
- **测试影响覆盖**: PLAN.md 列出 NEW 测试(针对 `[A#]`/`[C#]`/`[R#]`)和 IMPACTED 既有测试(源文件 → 测试文件映射, 必须保持绿色)。测试者确认两者。这在 TEST 阶段而非 VERIFY 阶段捕获既有测试的破坏。
- **手动测试门控 = vibe-coding 循环**: 在实现和单元测试之间, 若 `autoMode: false`, 用户手动操作系统并报告问题 — 实现者修复, 用户重测, 循环直到 "no more issues"。无上限。非正式。用户驱动。`autoMode: true` 时跳过。
- **纯代码实现者 + 延迟测试**: 实现者是纯代码(无测试、无检查), 因此文件集不相交的组件可并行运行。测试者在所有组件落地后编写所有单元测试 + 运行一次检查。
- **一次功能级验证**: 在 TEST 阶段后运行唯一验证者 — 它对所有变更文件(代码 + 测试)一次性运行检查(无条件重跑), 评审整个功能 diff 的合规性与代码审查, 然后编写 SUMMARY.md。
- **FINISHED/ISSUES 协议**: 实现者和测试者以状态令牌结束输出。编排器解析: `FINISHED` → 继续; `ISSUES` → 修复循环或呈现给用户。
- **无状态跟踪**: 没有 PROJECT-STATE.md 或 STATE.md。编排器通过检查产物(PLAN.md/FIX.md 是否存在、SUMMARY.md 是否存在、git diff)检测续接。每功能或 bug 两个产物: PLAN.md/FIX.md + SUMMARY.md。

## 技能

`yasdd-feature`(功能)和 `yasdd-bug`(bug 修复)是入口点。用户也可手动调用特定技能。

| 技能 | 角色 |
| --- | --- |
| `yasdd-feature` | Feature 流水线入口点。配置引导、续接检测、流水线驱动: plan → implement → manual test → test → verify。 |
| `yasdd-bug` | Bug 修复流水线入口点。配置引导、续接检测、流水线驱动: investigate → fix → manual test → test → verify。 |
| `yasdd-plan` | grill + 代码库探索 → 唯一 PLAN.md。每次一个问题并附推荐答案, 挑战模糊术语, 对照实际代码交叉检查用户声明。检测受影响的既有测试。(主会话) |
| `yasdd-investigator` | Bug 调查 + 根因分析 → 唯一 FIX.md。从症状反向追踪缺陷, 运行 git blame 识别引入 bug 的提交, 评估 blast radius(1–5 级), 编写 fix steps `[M#]` + Rules/Cases/Acceptance + Test impact。(主会话) |
| `yasdd-implementer` | 实现一个组件 `[M#]`: 范围化读取、**纯代码**(无测试、无检查)、拆分一致性表(plan-conformance 自验证; functioning 延迟) + 变更文件清单, 返回 FINISHED/ISSUES。兼容 PLAN.md(feature)和 FIX.md(bug)。(子代理) |
| `yasdd-tester` | 在所有组件落地后仅编写单元测试(无 e2e/集成;单元测试串联真实函数覆盖业务流程); 读取 CONVENTIONS.md(命令) + plan artifact(Acceptance `[A#]` + Test impact); 确认受影响测试保持绿色; 运行一次检查; 返回 FINISHED 或 ISSUES 带分类发现(test-bug vs impl-bug vs impl-bug-impacted)。(子代理) |
| `yasdd-verifier` | 一次功能/bug 级仅研究评审代码 + 单元测试 + 一次检查重跑(无条件; 每个功能/bug 对所有变更文件运行一次 lint/typecheck/tests; 命令来自 CONVENTIONS.md)。交叉引用 Test impact。将发现归属到组件 `[M#]`。编写 SUMMARY.md。(子代理) |
| `yasdd-spy` | 轻量级代码分析师, 从入口点到数据存储追踪功能实现。自动调用以进行代码库调查 + greenfield 检测。检测受影响的既有测试。(自动调用; 运行于快速低成本模型) |

### yasdd-spy(自动调用)

`yasdd-spy` 是唯一 `disable-model-invocation: false` 的技能 — 当任何技能要求代码库调查时自动调用。设计用于快速、低成本的模型(如 `anthropic/claude-haiku-4-5`), 使 PLAN 阶段可并行启动多个 spy 而无显著 token 开销。

spy 从入口点到数据存储追踪功能实现, 返回 `file:line` 引用和关键文件列表。它还检测 **greenfield** 仓库(无源文件)并返回 greenfield 信号, 以便 plan 技能播种 `CONVENTIONS.md`。被要求时, 它将源文件映射到既有测试文件以填充 Test impact 节。

要配置特定模型, 请编辑 `skills/yasdd-spy/SKILL.md` 并添加或更改 frontmatter 中的 `model:` 字段(支持取决于你的 agent harness)。

## 快速开始

### Feature 实现

1. 加载 `yasdd-feature` 技能, 以你的功能请求作为参数。
2. 编排器创建 `.yasdd/config.yml`(若缺失), 推导 slug, 并加载 `yasdd-plan`。
3. plan 技能对你进行 grill(每次一个问题并附推荐答案), 启动 yasdd-spy 子代理进行代码库调查, 编写 `PLAN.md`。它验证计划并呈现给你接受。
4. 接受后, 编排器读取 PLAN.md 中带 `[M#]` anchors + 内联并行标记的步骤。实现者纯代码并行(至 `maxParallelism`), 每组件 `[M#]` 一个。
5. 若 `autoMode: false`, 你手动测试运行中的系统并报告问题(vibe-coding 修复循环直到 "no more issues")。然后一个测试者编写单元测试 + 确认受影响测试通过 + 运行一次检查。然后对代码 + 测试运行一次功能级验证(修复 → 重新验证, 最多 3 次)并编写 SUMMARY.md。
6. 完成? `SUMMARY.md` 含 `## Business`(PM 语言)、`## Implemented`(架构)、`## Files`(变更文件)。

### Bug 修复

1. 加载 `yasdd-bug` 技能, 以你的 bug 报告作为参数。
2. 编排器创建 `.yasdd/config.yml`(若缺失), 推导 slug, 并加载 `yasdd-investigator`。
3. investigator 分析 bug 报告, 从入口点反向追踪数据流到根因, 运行 `git blame` 识别引入 bug 的提交(Caused By), 评估 blast radius(1–5 级), 编写 `FIX.md`(含 fix steps `[M#]` + Rules/Cases/Acceptance + Test impact)。它呈现调查结果给你接受。
4. 接受后, 编排器读取 FIX.md 中带 `[M#]` anchors 的 fix steps。实现者纯代码运行(至 `maxParallelism`), 每组件 `[M#]` 一个。
5. 若 `autoMode: false`, 你手动测试运行中的系统并确认 bug 已修复(vibe-coding 修复循环直到 "no more issues")。然后一个测试者编写回归单元测试 + 确认受影响测试通过 + 运行一次检查。然后对代码 + 测试运行一次 bug 级验证(修复 → 重新验证, 最多 3 次)并编写 SUMMARY.md。
6. 完成? `SUMMARY.md` 含 `## Business`(PM 语言)、`## Implemented`(架构)、`## Files`(变更文件)。

## 配置

`.yasdd/config.yml`:

```yaml
autoMode: false        # true = 跳过手动测试门控, 直接进入 TEST; false = 暂停以进行手动测试
maxParallelism: 3      # 每步并行子代理调用上限 + 批次大小
```

检查命令(lint、typecheck、test)是**项目级**的, 一次性捕获在 `.yasdd/CONVENTIONS.md` 中(由 plan 技能在首个功能播种)。测试者 + 验证者直接读取 CONVENTIONS.md。Bug 修复继承同一个 CONVENTIONS.md。

## CONVENTIONS.md

一个项目级文件 `.yasdd/CONVENTIONS.md` 一次性捕获项目的技术约定, 以便测试者 + 验证者直接继承而非重新发现:

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
| **Greenfield(首个功能)** | plan 技能的 "Technical environment decision" 子步骤在实现运行前播种 |
| **Brownfield(尚无 CONVENTIONS.md)** | plan 技能在首个功能从 `package.json`/`Makefile`/`AGENTS.md` 检测, 写入以便后续继承 |
| **已存在** | plan 技能继承(从不重新决定) |

## 目录结构

```
.yasdd/
  config.yml                         # autoMode + maxParallelism
  CONVENTIONS.md                     # 项目级技术约定(播种一次; 测试者 + 验证者直接读取)
  features/<slug>/
    PLAN.md                          # 唯一真实来源(goal, steps [M#], data, interfaces, rules, cases, acceptance, test impact, critical files, verification)
    SUMMARY.md                       # Business / Implemented / Files(由验证者编写)
  bugs/<bug-slug>/
    FIX.md                           # 调查报告 + 修复计划(root cause, data flow trace, caused by, blast radius, fix steps [M#], rules, cases, acceptance, test impact)
    SUMMARY.md                       # Business / Implemented / Files(由验证者编写)
```

每功能两个产物: `PLAN.md`(由 plan 技能编写, 用户接受)和 `SUMMARY.md`(由验证者在结束时编写)。每 bug 两个产物: `FIX.md`(由 investigator 编写, 用户接受)和 `SUMMARY.md`(由验证者在结束时编写)。

## Greenfield 支持

yasdd 通过 `yasdd-spy` 检测 greenfield 仓库(无源文件)并优雅处理:

- `yasdd-spy` 返回 "greenfield — no existing source files found" 而非失败。
- plan 技能注入 "Technical environment decision" 子步骤(语言、框架、测试运行器、lint、目录结构)。
- 这些决策在实现运行前播种 `CONVENTIONS.md`。
- 后续功能继承 `CONVENTIONS.md` — 无需重新决定。

这不增加单独的脚手架步骤 — 自然融入现有的 plan 流程。
