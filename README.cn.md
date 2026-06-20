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

每个功能都经过 6 步流水线:

```
0. config          读取 .yasdd/config.yml
1. DISCUSS         追问用户直到功能无遗漏        → DISCUSS.md
2. DESIGN          从讨论中得出务实的设计          → DESIGN.md
3. SPECS           把设计拆成 1..maxSpecs 个规范   → specs/*.md + STATE.md
4. PLAN            选择现在实现哪些规范(autoMode 下全部实现)
5. IMPLEMENT LOOP  逐个规范、串行:实现者 → 评审者 → 重新循环(最多 3 次)
6. WRAP UP         更新项目状态
```

三个核心理念使 yasdd 有效:

- **精简规范**: 每个规范只有一页(Refs / Goal / I/O / Rules / Scenarios / **Acceptance** / Out of scope)。没有冗余散文。
- **Acceptance = Given/When/Then**: 快乐路径 + 每个场景, 每条都可用测试检验。这让"功能完整规范"规则可验证, 而非自我报告。
- **FINISHED/ISSUES 协议**: 实现者以状态令牌结束输出。编排器解析它: `FINISHED` → 评审; `ISSUES` → 呈现给用户(或在 autoMode 下用 `- [~]` 标记该规范为阻塞并继续)。

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

## 技能(子代理)

| 技能 | 角色 |
| --- | --- |
| `yasdd-discuss` | 批量需求引导; 编写 DISCUSS.md。 |
| `yasdd-quick-discuss` | quick win 批量需求引导; 编写 `.yasdd/quick-wins/<slug>/DISCUSS.md`。 |
| `yasdd-designer` | 编写 DESIGN.md; 定义组件、数据、接口、风险、**Non-functional** 非功能需求。 |
| `yasdd-specs` | 将 DESIGN 拆解为规范; 将 NFR 带入规范的 Rules。 |
| `yasdd-quick-spec` | 融合设计 + 一个精简规范供 quick win 使用; 编写 `.yasdd/quick-wins/<slug>/SPEC.md`。 |
| `yasdd-implementer` | 实现一个规范: 范围化读取、代码 + 最小测试、一致性表、增量写入 SUMMARY.md (Business/Implemented/Files), 返回 FINISHED/ISSUES。quick win 通过路径覆盖重用。 |
| `yasdd-verifier` | 多轨道仅研究评审 + 一个**测试通过闸门**(在轨道前运行 lint/typecheck/tests)。quick win 通过轻量单轨道覆盖重用它。 |
| `yasdd-goback` | 用一个新规范更新已实现的功能。 |
| `yasdd-doubt` | 解释功能(只读)。 |
| `yasdd-init` | 创建 `.yasdd/` 与配置。 |
| `yasdd-clear` | 清除功能(保留配置)。 |

## 快速开始

1. 在项目中运行一次 `/yasdd-init`(创建 `.yasdd/`、`config.yml`、`PROJECT-STATE.md` 并更新 `AGENTS.md`)。
2. 运行 `/yasdd` 并回答关于你功能的批量提问。
3. 流水线编写 `DISCUSS.md → DESIGN.md → specs/ → STATE.md`, 然后提供实现。
4. 规范按顺序实现: 实现者 → 评审者 → (修复 → 重新评审, 最多 3 次)。
5. 完成? `SUMMARY.md` 已随每次实现分别在 `## Business`(PM 语言)、`## Implemented`(架构)、`## Files`(变更文件) 下新增一条要点; `PROJECT-STATE.md` 已更新。

## 配置

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = 不询问直接实现所有规范
maxParallelism: 3    # 每步并行子代理调用上限
maxSpecs: 5          # 一个 DESIGN 生成的规范上限
```

## 目录结构

```
.yasdd/
  config.yml
  PROJECT-STATE.md                 # 所有功能一览
  features/<slug>/
    DISCUSS.md
    DESIGN.md
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
DISCUSS → SPEC (融合设计 + 规范) → IMPLEMENTATION → 轻量代码评审
```

- 每个 quick win 只有一个 `SPEC.md` —— 没有 `specs/` 目录。
- 没有 `STATE.md`; 直接查看对应文件夹。
- 不更新 `PROJECT-STATE.md`。
