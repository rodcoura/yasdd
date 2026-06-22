# yasdd

> Yet Another Spec-Driven Development framework — 一条务实的、纯 markdown 的 SDD 流水线, 专为 AI 编程代理设计。

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

每个功能都经过 8 步流水线:

```
0. config          读取 .yasdd/config.yml
1. DISCUSS         追问用户直到功能无遗漏        (主会话)  → DISCUSS.md
2. DESIGN          从讨论中得出务实的设计          (主会话)  → DESIGN.md
2b. TESTING        测试架构交接                   (主会话)  → TESTING.md
3. SPECS           把设计拆成 1..maxSpecs 个规范   (主会话)  → specs/*.md + STATE.md
4. PLAN            选择现在实现哪些规范 + 从 Refs 计算并行批次
5. IMPLEMENT LOOP  按批次并行(至 maxParallelism): 纯代码实现者 → 标记完成(无闸门)
6. TEST            一个测试者编写单元 + e2e 测试 + 对整个功能运行一次闸门
6b. FIX-LOOP      若有 bug: 编排器内联写修复计划 → 实现者带"运行所有检查" → 重新测试(最多 3 轮)
7. FINAL VERIFY    一次功能级评审 + 测试通过闸门(无条件重跑)覆盖代码 + 测试(最多 3 轮)
8. WRAP UP         更新项目状态
```

DISCUSS/DESIGN/TESTING/SPECS 在主会话中运行, 复用已加载的代码上下文(零重复探索); IMPLEMENT/TEST/VERIFY 作为隔离子代理运行, 拥有干净上下文。

五个核心理念使 yasdd 有效:

- **精简且自足的规范**: 每个规范只有一页(Refs / Goal / I/O / Data / Interfaces / Rules / Scenarios / **Acceptance** / Out of scope)——它携带实现所需的具象数据形状与接口签名, 因此实现者无需 DESIGN.md。没有冗余散文。
- **Acceptance = Given/When/Then**: 快乐路径 + 每个场景, 每条都可用测试检验。这让"功能完整规范"规则可验证, 而非自我报告。
- **主会话上下文复用**: DESIGN、TESTING 和 SPECS 在主会话中内联运行, 复用 DISCUSS 期间加载的代码上下文——无需重新探索子代理, 更低 token 用量。
- **通过延迟测试实现并行**: 实现者是纯代码(无测试、无闸门), 因此文件集不相交的规范可按批次并行运行。测试者在所有规范落地后编写所有测试 + 运行一次闸门。编排器从规范 `Refs` + DESIGN 的 `Components` 计算并行批次(AI 判断, 内联——无脚本)。
- **一次功能级验证**: 而非每个规范一个评审者, 在 TEST 阶段后运行唯一的评审者——它对所有变更文件(代码 + 测试)一次性运行测试通过闸门(无条件重跑), 并评审整个功能 diff 的合规性与代码审查, 然后将发现归属到具体规范以便路由。更低的 token 用量, 共享上下文。
- **FINISHED/ISSUES 协议**: 实现者(和测试者)以状态令牌结束输出。编排器解析它: `FINISHED` → 标记完成; `ISSUES` → 呈现给用户(或在 autoMode 下用 `- [~]` 标记该规范为阻塞并继续)。

## 命令

| 命令 | 作用 |
| --- | --- |
| `/yasdd` | 开启新功能: 讨论 → 设计 → 规范 → 状态, 然后提供实现。 |
| `/yasdd-quick-win` | 启动一次性的 quick win 流程: 讨论 → 融合规范 → 实现 → 轻量评审。 |
| `/yasdd-implement <slug>` | 从 STATE.md 恢复实现单个功能的规范。 |
| `/yasdd-continue` | 恢复**所有**仍有待实现规范的功能。 |
| `/yasdd-status [slug]` | 打印项目与功能规范状态。 |
| `/yasdd-goback <slug>` | 通过编写一个新规范来更新已实现的功能。 |
| `/yasdd-doubt <slug>` | 简洁解释已实现的功能(只读)。 |
| `/yasdd-init` | 为项目初始化 yasdd(脚手架 + AGENTS.md)。 |
| `/yasdd-clear` | 删除所有功能并重置 PROJECT-STATE.md(破坏性)。 |

## 技能(阶段与子代理)

| 技能 | 角色 |
| --- | --- |
| `yasdd-discuss` | 批量需求引导; 编写 DISCUSS.md。(主会话) |
| `yasdd-quick-discuss` | quick win 批量需求引导; 编写 `.yasdd/quick-wins/<slug>/DISCUSS.md`。(主会话) |
| `yasdd-designer` | 编写 DESIGN.md; 定义组件、数据、接口、风险、**Non-functional** 非功能需求; 按模块/文件边界划分规范。(主会话) |
| `yasdd-test-design` | 在 DESIGN 之后立即编写 TESTING.md(测试架构交接)。(主会话) |
| `yasdd-specs` | 将 DESIGN 拆解为规范; 将 NFR 带入规范的 Rules; 每个规范的 `Refs` 声明文件范围以用于并行批次计算。(主会话) |
| `yasdd-quick-spec` | 融合设计 + 一个精简规范供 quick win 使用; 编写 `.yasdd/quick-wins/<slug>/SPEC.md`。(主会话) |
| `yasdd-implementer` | 实现一个规范: 范围化读取、**纯代码**(无测试、无闸门)、拆分一致性表(规范一致性自验证; functioning 延迟) + 变更文件清单, 增量写入 SUMMARY.md, 返回 FINISHED/ISSUES。(子代理) |
| `yasdd-tester` | 在所有规范落地后编写单元 + e2e 测试; 读取 TESTING.md + 一致性表 + 清单; 运行一次闸门; 返回 FINISHED + 测试清单, 或 ISSUES 带分类发现(测试 bug vs 实现 bug)。(子代理) |
| `yasdd-verifier` | 一次功能级仅研究评审代码 **+ 测试** + 一个**测试通过闸门**(无条件重跑; 每个功能对所有变更文件运行一次 lint/typecheck/tests)。(子代理) |
| `yasdd-goback` | 用一个新规范更新已实现的功能。(主会话) |
| `yasdd-doubt` | 解释功能(只读)。(主会话) |
| `yasdd-init` | 创建 `.yasdd/` 与配置。(主会话) |
| `yasdd-clear` | 清除功能(保留配置)。(主会话) |

### yasdd-spy(代码库探索代理)

yasdd 附带一个专用的**轻量级**子代理 `yasdd-spy`,用于所有代码库探索和功能追踪任务。它配置了快速、低成本的模型(如 `anthropic/claude-haiku-4-5`),使 DISCUSS、GOBACK 和 VERIFY 阶段可以并行启动多个 spy 而不会产生显著的 token 开销。

**开发者应使用 `yasdd-spy`**(而非 harness 的通用 `explore` 代理)来进行技能或命令要求的代码库调查。spy 从入口点到数据存储追踪功能实现,返回 `file:line` 引用和关键文件列表。

要使用不同的轻量级模型,请编辑 `agents/yasdd-spy.md` 并更改 frontmatter 中的 `model:` 字段。

## 快速开始

1. 在项目中运行一次 `/yasdd-init`(创建 `.yasdd/`、`config.yml`、`PROJECT-STATE.md` 并更新 `AGENTS.md`)。
2. 运行 `/yasdd` 并回答关于你功能的批量提问。
3. 流水线编写 `DISCUSS.md → DESIGN.md → TESTING.md → specs/ → STATE.md`(全部在主会话中), 然后提供实现。
4. 编排器从规范 `Refs` + DESIGN 的 `Components` 计算并行批次; 实现者按批次纯代码并行(至 `maxParallelism`)。然后一个测试者编写所有测试 + 运行一次闸门。然后对整个功能运行一次功能级验证(代码 + 测试)(修复 → 重新测试/重新验证, 各最多 3 次)。
5. 完成? `SUMMARY.md` 已随每次实现分别在 `## Business`(PM 语言)、`## Implemented`(架构)、`## Files`(变更文件) 下新增一条要点; `PROJECT-STATE.md` 已更新。

## 配置

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = 不询问直接实现所有规范
maxParallelism: 3    # 每步并行子代理调用上限
maxSpecs: 5          # 一个 DESIGN 生成的规范上限
gate:                # 在 init 时检测一次; 由 tester/verifier/fix-loop 复用
  testCmd: ""        # 如 "npm test"; 空 = 运行时检测
  lintCmd: ""        # 如 "npm run lint"; 空 = 运行时检测
  typecheckCmd: ""   # 如 "npm run typecheck"; 空 = 运行时检测
```

## 目录结构

```
.yasdd/
  config.yml
  PROJECT-STATE.md                 # 所有功能一览
  features/<slug>/
    DISCUSS.md
    DESIGN.md
    TESTING.md                     # 测试架构交接(框架、位置、夹具、验收映射)
    MANIFEST.md                    # 轻量级 spec/文件/依赖索引, 用于并行批次计算
    STATE.md                        # 规范清单: [ ] [x] [~]
    SUMMARY.md                      # Business / Implemented / Files (每次实现追加)
    specs/NN-<spec-slug>.md
  quick-wins/<slug>/
    DISCUSS.md
    SPEC.md                         # 融合设计 + 一个精简规范
    SUMMARY.md                      # Business / Implemented / Files
```

规范状态标记: `- [ ]` 未实现 · `- [x]` 完成 · `- [~]` 阻塞。

### Quick wins

`/yasdd-quick-win` 把完整 SDD 流水线折叠成单次、无状态的流程:

```
DISCUSS → SPEC (融合设计 + 规范, 主会话) → 实现纯代码 → TEST → 轻量代码评审
```

- 每个 quick win 只有一个 `SPEC.md` —— 没有 `specs/` 目录。
- 没有 `TESTING.md`(单一规范——测试者从项目现有框架推导测试架构)。
- 没有 `STATE.md`; 直接查看对应文件夹。
- 不更新 `PROJECT-STATE.md`。
