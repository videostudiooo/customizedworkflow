# AI Video Studio 工作流接入架构设计与现状审计

- 项目根目录：`F:\AI-Video-Studio`
- 审计日期：2026-11-26
- 当前主平台：Agentcut `0.2.33`
- Codex CLI：`0.147.0`
- 审计性质：只读研究与架构设计
- 审计结论：**PASS WITH LIMITATIONS**
- 实施门槛：**BLOCKED**

本报告中的“BLOCKED”只表示尚不能进入有写操作的实施阶段，原因有两个：

1. 当前 GitHub 连接账号无法访问所给 `videostudiooo/customizedworkflow` 仓库，远端仓库状态无法核实。
2. 按任务要求，全局 Skill、全局 MCP、路由规则和独立新 Thread 验证都尚未实施。

## 一、当前架构真实状态

### 1.1 已存在

| 能力 | 当前状态 | 证据 |
|---|---|---|
| Agentcut 0.2.33 | 已安装 | npm 包版本为 `0.2.33`，完整性匹配官方发布 |
| Helper | 当前运行 | `127.0.0.1:32118` 正常监听 |
| Studio | 当前运行 | 本地 Studio `127.0.0.1:3000` 正常监听 |
| 工作区 | 已固定 | `F:\AI-Video-Studio` |
| Codex 调用 Agentcut | 已在当前 Agentcut 会话验证 | 创建、编辑、预览、渲染、重开均已通过 |
| Agentcut 项目 Skill | 已生成 | `F:\AI-Video-Studio\.agents\skills\agentcut\SKILL.md` |
| Agentcut 项目指令 | 已生成 | `F:\AI-Video-Studio\AGENTS.md` |
| Agentcut MCP 配置模板 | 已生成 | `F:\AI-Video-Studio\.agentcut\mcp.json` |
| Claude 对应副本 | 已生成 | `F:\AI-Video-Studio\.claude\skills\agentcut` |
| 固定根信任 | 已配置 | `F:\CodexHome\config.toml` 中存在 `f:\ai-video-studio` 的 trust 记录 |

### 1.2 尚不存在

| 能力 | 当前状态 |
|---|---|
| AI Video Studio 专属 Skill | 不存在 |
| 用户级视频任务路由 | 不存在 |
| 用户级全局 `AGENTS.md` | 不存在 |
| 项目级 `.codex/config.toml` | 不存在 |
| 用户级 Agentcut MCP 注册 | 不存在 |
| 跨工作目录自动使用 Agentcut MCP | 不存在 |
| 自定义 `skills/`、`workflows/`、`templates/` 源文件 | 不存在 |
| `customizedworkflow` 本地 Git 工作副本 | 未发现 |
| 对新 Thread 的自动行为验收 | 未执行，按任务要求留到实施后 |

### 1.3 重要现状

`F:\AI-Video-Studio\AGENTS.md` 不是用户长期可编辑源文件。其内容明确写着：

```text
Managed by `agentcut` (rewritten on every start)
```

Agentcut helper 每次启动都会重写根目录 `AGENTS.md`、`.agents/skills/agentcut` 和 `.claude/skills/agentcut`。因此：

- 不应把 AI Video Studio 长期规则直接写进根 `AGENTS.md`。
- 不应修改生成的项目 `agentcut` Skill。
- 若要加入不会随 Agentcut 启动被覆盖的根级自定义规则，应使用 `AGENTS.override.md`，并让它显式引用由 Agentcut 管理的 `AGENTS.md` 和 `agentcut` Skill，或采用下方的全局 Skill + 独立工作流文件方案。

## 二、Agentcut 调用方式与依赖

### 2.1 当前 MCP 注册位置

当前 Agentcut MCP 只写在：

```text
F:\AI-Video-Studio\.agentcut\mcp.json
```

实际内容语义：

```text
server name: agentcut
command: F:\AI-Video-Studio\software\node\node.exe
entry:   F:\AI-Video-Studio\cache\npm\_npx\<hash>\node_modules\agentcut\dist\index.js
env:
  AGENTCUT_WORKSPACE=F:\AI-Video-Studio
  AGENTCUT_PORT=32118
```

但这不是 Codex 用户级配置，也不是项目级 `.codex/config.toml`。它是 Agentcut helper 生成并交给其内部启动的 Codex agent 使用的临时 MCP 配置。

### 2.2 配置范围判断

| 范围 | 当前是否存在 Agentcut MCP | 结论 |
|---|---|---|
| 用户级 `F:\CodexHome\config.toml` | 否 | `mcp_servers` 中只有 `node_repl` 等内建/连接器配置 |
| 项目级 `F:\AI-Video-Studio\.codex\config.toml` | 文件不存在 | 无项目 MCP 配置 |
| Agentcut 生成 `.agentcut\mcp.json` | 是 | 仅供 Agentcut 自己的 agent 启动流程使用 |
| 当前 Thread | 当前调用成功 | 因为请求是在 Agentcut 管理的 Codex 子进程中执行 |

### 2.3 跨工作目录实测

从 `F:\AI-Video-Studio` 和从当前其他工作目录分别执行只读 `codex mcp list`，两者结果一致：都没有 `agentcut` MCP。

因此：

- 普通新 Thread 不会仅因为 `.agentcut/mcp.json` 存在而自动发现 Agentcut MCP。
- 从其他目录启动 Codex 也不会自动发现。
- 当前验证成功依赖 Agentcut helper 启动 Codex 时临时注入的 MCP 参数，不证明跨 Thread 能用。
- 不能把原 Thread 的成功当成跨 Thread 已经通过。

### 2.4 Helper、Studio、MCP 的职责

| 组件 | 职责 | 是否必须 |
|---|---|---|
| Helper | 固定工作区、项目文件、MCP 服务端点、工具桥接、媒体/模型设置 | MCP 调用必须 |
| Studio 页面 | 时间线、实时预览、抓帧、进行中的编辑状态、浏览器导出 | 文件级操作可部分不需要；视觉、预览、检查、导出需要 |
| MCP | 让 Codex 发现并调用 `agentcut_*` 工具 | Vibe Editing 必需 |
| Codex agent | 理解意图、规划、调用 MCP、写场景和时间线 | 必需 |

Agentcut 0.2.33 的源码把 `studio.local.*` 文件操作路由给 helper；抓帧、联系表、预览性能、色彩检查、人物处理、音频检查、浏览器导出等操作通过已连接的 Studio 页面完成。页面未连接时，相关工具会返回“Studio page must be open”错误。

这意味着：

- **Helper 必须常驻运行。**
- **Studio 不一定需要用户每次都手动打开并盯着，但完整视觉工作流需要某个 Studio 页面保持连接。**
- 可设计后台受控 Studio 页面供 MCP 使用；用户需要审片时再打开可见页面。
- 当前版本没有一个已验证的纯 CLI 完整编辑器接口；CLI 的主要职责仍是启动 helper。

### 2.5 可直接通过 MCP 完成的能力

实际已确认存在并有明确工具定义的能力包括：

- 工具能力发现和指南读取
- Helper 状态、工作区状态
- 新建/切换项目
- Canvas、独立 clip 和版本
- 项目/资源库/工具包文本文件列出、读取、写入、复制
- 素材导入、下载
- 转写及转写选项
- 配音及声音选项
- 组件库查询
- 音乐、音效、B-roll 搜索和添加
- 媒体信息
- 音频节拍、响度和效果分析

### 2.6 依赖 Studio 页面的能力

需要连接页面的主要能力包括：

- 帧/联系表抓取
- 实时预览播放和 scrub 性能检查
- 浏览器导出
- 颜色检查和匹配
- 人物跟随和人物抠像
- 可视音频分析和最终混音审查
- 用户的播放头/片段聚焦与实时画面审阅

未来后台 Studio 若使用 headless 浏览器，必须验证 WebGL、媒体解码、WebAudio、图像捕获和导出能力；不能先假定 headless 与可见 Chrome 完全等价。

## 三、跨 Thread 的 Skill、指令和 MCP 能力

### 3.1 实际验证结果

使用本机 Codex `debug prompt-input` 做只读检查：

| 启动目录 | Agentcut 项目 `AGENTS.md` | `agentcut` Skill 元数据 | Agentcut MCP | AI Video Studio Skill |
|---|---:|---:|---:|---:|
| `F:\AI-Video-Studio` | 是 | 是 | 否 | 否 |
| 其他工作目录 | 否 | 否 | 否 | 否 |

在 F 根目录的 prompt input 中，可以实际看到：

```text
agentcut: Create and edit videos in an Agentcut workspace...
(file: F:/AI-Video-Studio/.agents/skills/agentcut/SKILL.md)
```

也实际注入了 Agentcut 工作区 `AGENTS.md`。这说明只要新 Thread 的主工作目录是 F 根，Agentcut 自带 Skill 能被发现。

但同样检查没有出现 `agentcut_*` MCP 工具，也没有出现 `ai-video-studio` Skill。

### 3.2 明确回答

1. **普通新 Thread 当前能否自动发现 Agentcut MCP？**

   **不能。** MCP 未注册到用户级或项目级 Codex 配置。

2. **新 Thread 当前能否自动发现 Agentcut 自带 Skill？**

   只有以 `F:\AI-Video-Studio` 或其子目录为工作根时才能。以其他目录启动时不能。

3. **新 Thread 当前能否自动发现 AI Video Studio 全局 Skill？**

   不能。该 Skill 尚不存在。

4. **新 Thread 当前能否自动进入视频工作流？**

   不能。当前只有 Agentcut 工作区内部的视频指令，没有跨目录任务识别和分流。

5. **是否依赖当前 Thread 的上下文？**

   MCP 和 Skill 本身不依赖聊天记忆，但当前成功路径依赖 Agentcut 在启动 Codex 时临时注入的 MCP 配置。普通 Codex Thread 没有这个注入。

6. **Helper 是否必须运行？**

   是。除少数不依赖 helper 的打包指南目录内容外，实际 MCP 调用需要 helper。

7. **Studio 是否必须打开？**

   文件级工作可以只依赖 helper；预览、抓帧、视觉检查和导出需要连接 Studio 的页面。为避免用户每次手动打开，后续应提供后台页面守护，但此机制尚待验收。

### 3.3 用户级 Skill 路径的产品差异

当前文档中的标准个人 Skill 路径是：

```text
$HOME/.agents/skills
```

但本机 Codex 桌面实例当前实际发现的用户 Skill 位于：

```text
F:\CodexHome\skills
```

当前存在：

- `codex-context-lifecycle`
- `ppt-master`
- `.system`

`C:\Users\29405\.agents\skills` 当前不存在。

因此实施时不能只按理论路径安装一次就宣布完成。应：

1. 将仓库中的 `skills/ai-video-studio` 作为唯一源。
2. 用目录 junction/受支持链接把它接入实际被当前桌面版发现的用户 Skill 目录。
3. 若 CLI 新 Thread 仍不能发现，再验证官方 `$HOME/.agents/skills` 路径。
4. 不使用两份真实副本，避免后续内容漂移。

## 四、开源 Skill 项目调研

### 4.1 总览

| 项目 | 真实性 | Codex 明示支持 | 标准 `SKILL.md` | 许可证 | 最近活动 | 与 Agentcut 适配 |
|---|---|---|---|---|---|---|
| `iamaanahmad/agents-video-editing-skills` | 存在 | 是 | 是 | MIT | 2026-11-23 | 无 Agentcut 集成 |
| `gitethanwoo/video-editing` | 存在 | 通过 Skills CLI 支持 | 是 | MIT | 2026-11-12 | 无 Agentcut 集成；技术可借鉴性高 |
| `albertpikkop/remotion-ffmpeg-video-skill` | 存在 | 是 | 是 | MIT | 2026-09-05 | 无 Agentcut 集成；QA 可借鉴 |
| `remotion-dev/skills` | 存在，官方 | 是 | 是 | 插件 manifest 标 MIT；Remotion 使用另受 Remotion 许可约束 | 2026-11-24 | API 权威，但版本需匹配 |

三个候选仓库均未发现 Agentcut 或 `agentcut_*` 字样，因此都不能直接替代 Agentcut 自带 Skill。

### 4.2 `iamaanahmad/agents-video-editing-skills`

事实：

- 仓库创建于 2026-11-11，已有 3 次提交，7 stars、1 fork。
- 14 个 Skill，包括路由器、规划、FFmpeg、平台导出、Remotion、MoviePy、字幕、语音、混音、录屏、竖屏、运动设计、封面和 QA。
- README 明确说明支持 Codex 的 `.agents/skills`。
- 核心不要求付费 API；可选语音和云服务使用用户自己的 Key。
- 依赖 FFmpeg、Python、Node，部分 Skill 另需 Whisper、MoviePy、Pillow 或 Playwright。

值得吸收：

- 轻量入口路由器。
- 5 行 brief、镜头表、资产清单和帧数计算公式。
- 预览优先、最终交付后置的分阶段思路。
- 运动时长、缓动、文字可读时间与反“AI 感”检查。
- 音频层级、自动 ducking、LUFS 目标。
- 字幕行长、阅读速度、换行和安全区规则。
- 视频 QA 检查维度和失败修复表。

不适合直接安装：

- 未适配 Agentcut MCP、`layers.json` 或 Agentcut 组件。
- 与 Agentcut 已有字幕、配音、音乐、B-roll 和导出能力大量重叠。
- 安装器直接对目标 Skill 目录执行递归删除，然后复制或建链；虽然这是安装器更新自身目标，但会破坏用户对该目标目录所做的本地修改。当前共享 Skill 区不应直接执行。
- 会把一个很长的 managed block 追加到 `AGENTS.md`；但 Agentcut 下次启动会重写该文件，导致安装结果失效。

结论：**借鉴内容，不整体安装。**

### 4.3 `gitethanwoo/video-editing`

事实：

- 创建于 2026-07-24，最近提交 2026-11-12，6 stars、2 forks。
- 5 个 Skill：任意素材剪辑、参考片反向分析、B-roll、产品视频、网页产品演示录制。
- 具备实际 Python 工作台和确定性媒体处理逻辑。
- 核心脚本会检查真实媒体、生成 source report、检查 contact sheet/transition strip、使用候选输出、完整解码、检查分辨率/帧率/时长/音频采样率/LUFS/checksum，验证通过后才替换正式输出。
- 需要 Python 3.11+、FFmpeg/ffprobe、`uv`；Remotion 可选，但某些产品视频流程需要 ElevenLabs CLI，音频分析可选 Gemini。

值得吸收：

- 将“分析”和“生产”拆成不同 Skill。
- 将 measured / observed / interpreted 三类证据明确分开。
- 每段素材先 probe、hash、抽帧和音频扫描，不以文件名推断素材属性。
- 来源、版权、授权和 B-roll 锚点写进 manifest。
- 渲染先出低分辨率或局部审查版本，再出 master。
- 候选文件验证通过后才提升为正式输出。
- 最终 QA 使用真实 payload、完整解码和校验和。

不适合直接使用：

- 不调用 Agentcut MCP，也不理解 Agentcut 的 `project.json`/`layers.json`。
- 自带工作台会创建另一套编辑项目结构，与 Agentcut 工程格式重叠。
- 其 `uv`、Gemini、ElevenLabs、Agent Browser 依赖会扩大当前最小部署。
- B-roll 和参考片下载必须单独核验授权及隐私。

结论：**当前三个候选中技术价值最高，适合作为分析、B-roll 和 QA 方法参考；不直接替代 Agentcut。**

### 4.4 `albertpikkop/remotion-ffmpeg-video-skill`

事实：

- 创建于 2026-09-03，最近提交 2026-09-05，当前 0 stars、0 forks。
- 一个窄范围 Skill，目标是从零制作并验证 Remotion + FFmpeg 视频。
- 包含 `media_audit.py`，执行 ffprobe、完整解码、SHA-256 和 JSON 回执。
- 默认面向新手：竖屏 1080×1920、30 fps、H.264、本地审阅。
- 需要 Node、FFmpeg、Python；无额外 API Key。

值得吸收：

- 先做环境预检。
- 使用明确、可标注的默认值，最多问三个关键问题。
- “检查文件，而不是检查命令退出码”。
- 先看代表帧，再完整渲染。
- 用完整解码和 SHA-256 生成可追踪回执。
- 不把本地渲染当成上传、发布或付费授权。

不适合直接使用：

- 明确说“不用于纯故事或创意指导”，覆盖面较窄。
- 会建议新建独立 Remotion 项目，和 Agentcut 已有 Remotion runtime 重叠。
- README 给出的手工 Codex 安装目录体现出与当前 Codex Skill 路径之间可能存在版本漂移。
- 年轻项目、低采用量，不应作为主流程基础设施。

结论：**吸收其交付审计原则；不作为主 Skill。**

### 4.5 官方 `remotion-dev/skills`

事实：

- 官方 Remotion 团队维护，8049 stars、892 forks，最近更新 2026-11-24。
- 覆盖创建、React markup、Studio、渲染、字幕、互动编辑、Elements、地图、多媒体、SaaS、升级和许可证。
- 当前缓存副本中存在 Remotion Skill 插件，但 **未在 `config.toml` 启用**。

本地版本不一致：

| 来源 | 版本 |
|---|---|
| Agentcut 0.2.33 工作区 Remotion | `4.0.536` |
| 本机缓存 Remotion 插件 Skill | `4.0.506` |
| 当前 GitHub `remotion-dev/skills` | `4.0.547` |

因此不能直接启用现有缓存插件并假定其 API 指导与 Agentcut 工作区兼容。

结论：**Remotion API 的权威来源，但必须在版本对齐后再启用；Agentcut 自身的 `agentcut_guide` 仍是当前编辑主指南。**

### 4.6 推荐吸收组合

| 目标能力 | 首选借鉴来源 | 使用方式 |
|---|---|---|
| 任务路由和否定条件 | 自研轻量路由 + repo1 | 只保留短分类表 |
| Brief、脚本、镜头表 | repo1 + repo2 | 改写为项目模板 |
| 素材探测和镜头分析 | repo2 | 方法吸收；未来适配 Agentcut 素材路径 |
| B-roll 来源与授权记录 | repo2 | manifest 和审批状态写入本地工作流 |
| 运动与可读性 | repo1 | 作为制作参考，写入自有 Skill |
| 音频与字幕规则 | Agentcut 官方 Skill + repo1 | Agentcut 工具优先 |
| 渲染和完整 QA | repo2 + repo3 + Agentcut | 双层验证：Agentcut 预览/导出 + 本地文件解码 |
| Remotion API | `remotion-dev/skills` | 版本对齐后可选安装 |

不直接安装任何候选 Skill。全部候选均需改写后才能与 Agentcut 的固定根、工具和项目模型协同。

## 五、推荐架构

### 5.1 分层职责

```text
用户：“帮我剪一个视频”
        │
        ▼
全局 AGENTS.md
  └─ 只做识别：实际视频制作/修改/QA/渲染 → 使用 ai-video-studio
        │
        ▼
ai-video-studio Skill
  ├─ 理解需求
  ├─ 选择简单直改或复杂先规划
  ├─ 加载项目生命周期和 QA 参考
  └─ 调用 Agentcut MCP
        │
        ├─ Helper：项目、文件、素材、转写、配音、库
        └─ Studio 页面：预览、抓帧、可视检查、导出
                │
                ▼
projects/<slug>/
```

### 5.2 全局路由

建议文件：

```text
F:\CodexHome\AGENTS.md
```

只保留约 8–12 行：

```md
## AI Video Studio

- 当请求的实际结果是创建、剪辑、重构、加字幕/音乐/配音、镜头编排、
  预览检查、渲染或交付视频时，先调用 `ai-video-studio` Skill。
- 仅讨论视频软件、分析技术、编写视频处理脚本，或用户明确说不要使用
  AI Video Studio 时，不进入该工作流。
- 视频工程固定在 `F:\AI-Video-Studio`；不要根据当前目录另建工作区。
- 一个视频一个独立 `projects/<slug>`，不要把不同作品写入同一工程。
```

该文件适合未来保存为仓库内模板，再由很小的实现脚本安装。不要把完整剪辑方法写入这里。

### 5.3 专属 Skill

建议源目录：

```text
F:\AI-Video-Studio\skills\ai-video-studio\
├─ SKILL.md
├─ references\
│  ├─ project-lifecycle.md
│  ├─ editorial-planning.md
│  ├─ footage-and-broll.md
│  ├─ audio-captions-motion.md
│  └─ qa-delivery.md
└─ assets\
   └─ templates\
```

`SKILL.md` 建议职责：

1. 判断是简单直改还是复杂创作。
2. 先调用 `agentcut_capabilities`、`agentcut_guide` 和 `agentcut_status`。
3. 复杂任务先写 brief、镜头表和验收标准；简单修改直接做。
4. 必须用 Agentcut MCP 编辑项目，不绕开项目格式手工生成不可编辑成片。
5. 复杂任务先低分辨率预览，用户确认后再完整渲染。
6. 用 Agentcut 抓帧/联系表/预览/音频检查，再用文件级完整解码做交付 QA。
7. 用户未明确要求时不导出、不上传、不启用付费服务。
8. 用户可随时说“不要用 AI Video Studio”，立即按普通 Codex 任务处理。

Skill 描述必须包含中英文触发词，但排除纯研究、软件评测和代码任务：

```text
description: Create, edit, restructure, caption, score, voice, storyboard,
preview, quality-check, render, or deliver an actual video through AI Video
Studio and Agentcut. Use for 剪辑、混剪、镜头编排、字幕、配乐、配音、渲染和成片 QA.
Do not use for video-software research, mere technical discussion, or code-only work.
```

### 5.4 Skill 自动发现

建议：

1. 仓库只保留一份真实 Skill：`F:\AI-Video-Studio\skills\ai-video-studio`。
2. 用目录 junction/受支持符号链接安装到当前桌面版实际识别的用户 Skill 目录：

   `F:\CodexHome\skills\ai-video-studio`

3. 如果独立 Codex CLI 新 Thread仍看不到，再链接到官方个人路径：

   `C:\Users\29405\.agents\skills\ai-video-studio`

4. 不复制两份正文，避免内容漂移。
5. Codex 通常会自动发现 Skill 变化；不生效时重启 Codex。

### 5.5 Agentcut MCP 跨 Thread

要达到“任意目录的新 Thread 都可用”，建议使用用户级 MCP：

```toml
[mcp_servers.agentcut]
enabled = true
required = false
command = 'F:\AI-Video-Studio\software\node\node.exe'
args = ['F:\AI-Video-Studio\software\agentcut-helper\node_modules\agentcut\dist\index.js']
env = { AGENTCUT_WORKSPACE = 'F:\AI-Video-Studio', AGENTCUT_PORT = '32118' }
cwd = 'F:\AI-Video-Studio'
startup_timeout_sec = 60
tool_timeout_sec = 1800
supports_parallel_tool_calls = false
```

该配置目前尚未写入。路径中的稳定 helper 安装也尚未创建。

不建议直接使用当前 `_npx\<hash>\...` 路径作为长期全局 MCP 入口。npx 缓存会更新、重排或被重新获取，路径可能失效。实施时应把 `agentcut@0.2.33` 安装到一个明确的稳定软件目录，并保留当前 npx 安装作为现有运行实例。

更保守的替代方案是只用项目级：

```text
F:\AI-Video-Studio\.codex\config.toml
```

这不会把 Agentcut 工具暴露给所有项目，但要求每个视频 Thread 的主目录选择 F。若“任何合适 Thread”是硬要求，应使用用户级 MCP。

### 5.6 Helper 与 Studio 常驻方式

推荐两个用户可见目标：

1. **后台服务脚本**
   - 检查端口和 PID。
   - 启动 Helper。
   - 启动一个受控 Studio 页面并保持连接。
   - 等待 `/agentcut` WebSocket ready。
   - 写健康状态到 `F:\AI-Video-Studio\logs\agentcut\service-status.json`。

2. **用户查看入口**
   - 只在用户要审片时打开 `http://localhost:3000/studio`。
   - 不需要每个 Thread 手动重新打开网页。

后台页面可以使用普通 Chrome 的独立 profile 或经验证的 headless Chrome。必须测试：

- WebGL/Remotion 预览
- `<video>` seek
- 抓帧
- WebAudio
- 浏览器导出
- Helper 重启后的自动重连

在这些测试完成前，只能把“后台页面”列为待验证设计，不能写成已实现。

### 5.7 固定根和项目创建

MCP 的 `AGENTCUT_WORKSPACE` 固定为：

```text
F:\AI-Video-Studio
```

Skill 规范：

1. 每个新视频调用 `agentcut_create_project`。
2. slug 使用稳定、语义化的小写名称。
3. 在后续工具调用中传递显式 `project`，不依赖 Studio 当前打开的工程。
4. 一个 Thread 只绑定一个主视频工程；多个成片使用 Canvas 独立 clip/version。
5. 需要后续变体时用 `agentcut_create_cut`，不复制素材目录。
6. 项目内 `notes.md` 保存决策；`.studio` 保存聊天、附件和恢复状态，不提交 Git。

### 5.8 项目隔离

```text
workspace: F:\AI-Video-Studio
project A: projects\project-a
project B: projects\project-b
```

不同工程不得共享以下状态：

- `layers.json`
- `project.json`
- 项目 chat/session
- 项目 renders
- 项目专用 voice/music/b-roll

共享资产可放 `library`，源素材采集可放 `assets`。Agentcut 项目实际引用的工作副本应放 `projects/<slug>/assets`；不要用目录链接绕过 Agentcut 的路径安全检查。

## 六、建议目录结构

本轮不创建。建议在现有结构上增加：

```text
F:\AI-Video-Studio\
├─ .github\
├─ AGENTS.override.md               # 若选择项目覆盖层
├─ .gitignore
├─ config\
│  ├─ agentcut-launch.ps1
│  ├─ agentcut-local-studio.ps1
│  └─ paths.md
├─ skills\
│  └─ ai-video-studio\
│     ├─ SKILL.md
│     └─ references\
├─ workflows\
│  ├─ global-router.md
│  ├─ project-lifecycle.md
│  ├─ editorial-planning.md
│  └─ qa-delivery.md
├─ templates\
│  ├─ project-brief.md
│  ├─ shot-plan.md
│  └─ qa-checklist.md
├─ scripts\
│  ├─ ensure-agentcut-services.ps1
│  ├─ install-codex-integration.ps1
│  └─ verify-workflow.ps1
├─ projects\
├─ assets\
├─ library\
├─ cache\
├─ renders_temp\
├─ output\
├─ logs\
├─ reports\
├─ docs\
└─ .agentcut\                      # 生成，不手改
```

`.agents/skills/agentcut`、`.claude/skills/agentcut`、根 `AGENTS.md`、`package.json`、`package-lock.json`、`tsconfig.json`、`remotion.config.ts`、`node_modules` 和 `.agentcut` 都是 Agentcut 管理/运行时文件，不应作为用户 Skill 源提交。

## 七、GitHub 规划

### 7.1 当前仓库状态

对 `videostudiooo/customizedworkflow` 的只读检查返回 GitHub API 404：

- 分支无法列出。
- 提交无法列出。
- 根目录无法读取。
- 通过当前连接的 GitHub 身份 `orson0414` 无法确认仓库存在、私有可见性或权限。
- 无法验证“仓库为空”这一前提。

本地在 F 盘前四层目录中未发现 `customizedworkflow` 克隆或对应 `.git`。`F:\AI-Video-Studio` 本身也不是 Git 工作树。

因此 GitHub 项标记 **BLOCKED**，不是 FAIL；需要用户确认正确 URL，或者给当前 GitHub 连接账号授权。

### 7.2 推荐单一工作副本

一旦仓库可访问，推荐把 `F:\AI-Video-Studio` 本身作为唯一 Git 工作树，而不是另建第二个仓库副本。

原因：

- Skill 源、工作流模板、启动脚本和项目定义都围绕固定根组织。
- 便于让 Codex 把 F 根识别为项目根。
- 不产生两套路径和同步歧义。

### 7.3 未来放入 GitHub

- `skills/ai-video-studio/`
- `workflows/`
- `templates/`
- `AGENTS.override.md` 或路由模板
- `.codex/config.toml` 的安全模板
- 启动、健康检查、安装和验证脚本
- QA 规范
- 文档、设计决策、版本记录
- 小型项目定义：`project.json`、`layers.json`、`scenes/`、`notes.md`、QA 记录
- 素材来源和授权 manifest

### 7.4 只留本地

- `assets`
- `projects/*/assets`
- `projects/*/renders`
- `output`
- `.agentcut`
- `.agents/skills/agentcut`
- `.claude/skills/agentcut`
- `node_modules`
- `cache`
- `library` 中的媒体和大资源
- `logs`
- 浏览器 profile
- API Key、Cookie、Token、登录状态
- 原始聊天和大型审片附件

### 7.5 Git LFS

默认不启用。媒体文件不进入普通 Git，也不进入 LFS；用本地受保护目录和外置备份管理。

### 7.6 提交策略

实施时按阶段提交：

1. 规范、模板和路由。
2. Skill 与引用。
3. 启动/健康检查脚本。
4. 项目模板与 QA 规范。

本轮不得 Commit 或 Push。

## 八、实施路线

### 阶段 0：解锁前置条件

1. 确认 GitHub 仓库正确 URL、所有者和当前连接账号权限。
2. 决定是否将 F 根作为唯一 Git 工作树。
3. 确认允许写入 `F:\CodexHome\AGENTS.md` 和 `F:\CodexHome\config.toml`，并先备份。
4. 确认当前 `AGENTS.md`、`.agents`、`.agentcut` 都是 Agentcut 管理文件，后续不手工编辑。

### 阶段 1：创建规则和 Skill 源

1. 创建 `skills/ai-video-studio`。
2. 创建 workflows 和 templates。
3. 先写窄范围 router 和项目生命周期。
4. 不安装第三方 Skill。

### 阶段 2：稳定工具入口

1. 在当前 npx 安装之外建立稳定的 Agentcut helper 软件目录。
2. 记录 package version、tarball integrity 和路径。
3. 修改启动脚本指向稳定版本。
4. 保留原验收工程，不重装、不清理。

### 阶段 3：接入 Codex

1. 将 Skill 源链接到当前实际被发现的用户 Skill 目录。
2. 安装短小的全局 `AGENTS.md` 路由。
3. 在 `F:\CodexHome\config.toml` 增加用户级 Agentcut MCP。
4. 如果选择更保守方案，则改为项目级 `.codex/config.toml`，并把 F 作为视频 Thread 的主目录。

### 阶段 4：服务运行方式

1. 实现 Helper 健康检查和幂等启动。
2. 实现 Studio 页面连接检查。
3. 验证后台 Chrome 是否满足预览、抓帧、音频和导出。
4. 决定是否使用用户登录启动脚本；不修改系统级环境变量。

### 阶段 5：独立新 Thread 验收

必须从没有历史上下文的新 Thread 开始，至少验证：

1. 普通目录下的“剪一个短视频”自动选中 AI Video Studio。
2. Skill 元数据中可以发现 `ai-video-studio`。
3. Agentcut MCP 工具可以看到并成功调用。
4. 工具自动找到 F 工作区。
5. 新建独立测试项目。
6. 修改项目、抓帧并显示预览。
7. 项目重开后状态保持。
8. “研究某 video editor”不进入 Agentcut。
9. “写一个 FFmpeg Python 脚本”按编程任务处理。
10. 用户明确说“不要使用 AI Video Studio”时可以完全绕开。
11. 测试结束后不清理测试工程，提交脱敏报告。

未完成该独立新 Thread 验收前，不认定目标架构已实现。

## 九、风险与未决问题

### 9.1 高优先级

1. **GitHub 仓库 404**
   - 状态：BLOCKED。
   - 需要确认 URL 或授权当前 GitHub 身份。

2. **全局 MCP 的常驻依赖**
   - 全局配置会让 Agentcut 工具出现在所有 Thread。
   - Helper 未启动时工具会失败。
   - 需要清晰的健康检查和失败提示，避免普通任务被无关错误打扰。

3. **Studio 页面连接机制**
   - 没有页面时，预览、抓帧、音频分析和导出不可用。
   - 后台页面是否完全等价于可见 Chrome 尚未验证。

4. **Agentcut 生成文件覆盖**
   - 根 `AGENTS.md`、`.agents/skills/agentcut` 和 `.claude/skills/agentcut` 每次启动都会刷新。
   - 自定义内容必须放在独立 Skill、workflow、override 或 `.codex` 配置中。

5. **npx 缓存路径不稳定**
   - 当前 MCP entry 位于 `_npx\<hash>`。
   - 若直接全局引用，可能在 npm 缓存变化后失效。
   - 必须先建立稳定 helper 安装入口。

6. **多 Thread 并发**
   - 多个 Thread 共享同一个 Helper 和 Studio。
   - `AGENTCUT_PROJECT` 可用于绑定各 agent 自己的项目，但跨 Thread 并发写入仍需独立验收。
   - 不允许两个 Thread 同时写同一个 project slug。

### 9.2 中等风险

7. **Skill 路径产品差异**
   - 官方文档个人 Skill 目录与本机桌面版当前发现目录不同。
   - 必须用真实新 Thread 验收实际安装位置。

8. **自动路由不是硬保证**
   - Skill 隐式匹配受 description、上下文和模型判断影响。
   - 短全局 AGENTS 规则能提高稳定性，但仍需正反例测试。
   - 本轮不引入 hook 强制执行，避免把所有编辑请求硬绑定到某个工具。

9. **第三方 Skill 安全**
   - repo1 安装器会递归删除目标 Skill 目录。
   - repo2 可选使用 Gemini、ElevenLabs、Agent Browser、`uv` 和下载器。
   - 不应直接运行。

10. **Remotion Skill 版本漂移**
    - Agentcut 当前 Remotion `4.0.536`。
    - 本机缓存官方插件 `4.0.506`。
    - GitHub 最新技能 `4.0.547`。
    - 版本未对齐前不启用对应 Skill。

11. **FFmpeg 调用路径**
    - Agentcut 的 FFmpeg 是受管按需工具，不在系统 PATH。
    - 借鉴的 Python QA/分析脚本默认查找 PATH 中的 ffmpeg/ffprobe。
    - 实施时必须显式传入受管工具路径，不能假定系统 FFmpeg 已安装。

12. **商业和素材权利**
    - 候选 Skill 本身多为 MIT。
    - Remotion 有独立的商业许可条件。
    - 候选 Skill 中引用的音乐、B-roll、字体、模型和第三方 API 均有独立条款。

## 十、建议的最终接入方式

### 推荐方案

**全局路由 + 全局专属 Skill + 用户级 Agentcut MCP + F 盘固定工作区 + 后台 Studio 服务。**

职责拆分：

| 层 | 位置 | 内容 |
|---|---|---|
| 全局路由 | `F:\CodexHome\AGENTS.md` | 只识别任务、明确否定条件、固定工作区 |
| Skill 源 | `F:\AI-Video-Studio\skills\ai-video-studio` | 制作方法、项目生命周期和按需引用 |
| Skill 安装入口 | 当前 Codex 实际用户 Skill 目录 | 使用链接，不复制正文 |
| 项目层 | `F:\AI-Video-Studio\AGENTS.override.md`，可选 | 仅放固定根、项目保护和加载顺序 |
| 工具层 | `F:\CodexHome\config.toml` 的 `mcp_servers.agentcut` | 新 Thread 默认可见 |
| 辅助页面 | 后台 Studio 页面 | 预览、抓帧、音频检查、导出 |
| 版本管理 | F 根单一 Git 工作树 | Skill、workflow、templates、脚本和报告 |

### 为什么不是单一巨大 AGENTS.md

- 全局 AGENTS 过大，会增加所有非视频任务的上下文成本。
- 详细视频方法应按需加载。
- Agentcut 根 AGENTS 由程序重写，不能作为持久源。
- Skill 保存完整方法，CLI/桌面版可以自动发现，并支持 references 和 scripts。
- MCP 与 Skill 分工明确：Skill 决定怎么做，MCP 提供可执行工具。

## 十一、实施所需的新授权

以下动作本轮均未执行，后续需要用户逐项确认：

1. 更正或授权访问 `videostudiooo/customizedworkflow`。
2. 在 F 根或指定的单一工作副本初始化/关联 Git。
3. 创建 `skills/`、`workflows/`、`templates/`、`scripts/` 和所需模板。
4. 创建 `ai-video-studio` Skill 及其 references。
5. 创建短小的全局 `AGENTS.md` 路由。
6. 创建/修改 `F:\CodexHome\config.toml`，先备份原文件。
7. 创建 Skill 目录链接。
8. 建立稳定 Agentcut helper 软件目录和后台服务脚本。
9. 选择项目级 MCP 或用户级全局 MCP。
10. 选择可见 Chrome、最小化 Chrome 或 headless Chrome 的 Studio 运行方式。
11. 验证后单独批准 Commit 和 Push。

在获得这些授权前，不安装新 Skill、不注册新的全局 MCP、不修改 Codex 配置、不建立 Git 仓库或工作副本。

## 十二、审计结论

- 当前本地 Agentcut 工具链可用。
- 当前跨 Thread 自动接入尚未实现。
- Agentcut 自带 Skill 只在 F 工作根自动被发现。
- Agentcut MCP 当前只通过 Agentcut 子进程临时注入，不是普通新 Thread 的全局能力。
- 三个候选开源项目均有可借鉴价值，但没有一个适配 Agentcut；不适合整体安装。
- `gitethanwoo/video-editing` 最值得吸收素材分析、B-roll 来源管理、候选渲染和完整 QA。
- 官方 Remotion Skill 是 API 权威来源，但需与 Agentcut 的 Remotion 版本对齐。
- GitHub 专用仓库当前无法访问，是实施前的主要 BLOCKED 项。

**审计与设计：PASS WITH LIMITATIONS**

**进入写操作实施：BLOCKED，等待仓库访问确认和新一轮明确授权。**

## 十三、官方 Codex 配置依据

- [AGENTS.md 指令发现](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Skills 的发现位置与隐式调用](https://learn.chatgpt.com/docs/build-skills)
- [Codex config.toml 与项目级 `.codex/config.toml`](https://learn.chatgpt.com/docs/config-file/config-basic)
- [MCP 配置与工具连接](https://learn.chatgpt.com/docs/extend/mcp)

## 十四、开源项目来源

- [iamaanahmad/agents-video-editing-skills](https://github.com/iamaanahmad/agents-video-editing-skills)
- [gitethanwoo/video-editing](https://github.com/gitethanwoo/video-editing)
- [albertpikkop/remotion-ffmpeg-video-skill](https://github.com/albertpikkop/remotion-ffmpeg-video-skill)
- [remotion-dev/skills](https://github.com/remotion-dev/skills)
