# AI Video Studio 工作流实施与验收报告

- 项目：AI Video Studio
- 根目录：`F:\AI-Video-Studio`
- 实施日期：2026-11-27
- Agentcut：`0.2.33`
- Codex CLI：`0.147.0`
- 最终结论：**PASS WITH LIMITATIONS**

## 1. 实施摘要

已完成：

- 全局长视频任务路由。
- 专属 `ai-video-studio` Codex Skill。
- 用户级 Agentcut MCP 注册。
- Agentcut Helper 稳定安装，摆脱 npx 哈希缓存路径。
- 生产模式本地 Studio。
- 幂等启动脚本和健康检查。
- GitHub 仓库的轻量化工作流源文件。
- 本地冗余缓存清理。
- 完全独立的新 Codex Thread 跨目录实测。

最终效果：

用户可以在普通 Codex Thread 中直接提出视频制作需求。Codex 能自动加载 AI Video Studio Skill、发现 Agentcut MCP、使用固定 F 盘工作区和独立项目、完成预览与渲染。用户不需要记住 MCP 命令，也不需要每次手动打开 Studio。

## 2. Codex 全局配置

### 2.1 全局路由

安装位置：

```text
F:\CodexHome\AGENTS.md
```

仓库源文件：

```text
F:\AI-Video-Studio\workflows\global-router.md
```

路由规则只负责：

- 实际视频制作、剪辑、镜头分析、字幕、配音、音乐、预览、QA、渲染和交付 → 使用 `$ai-video-studio`。
- 纯视频知识、行业研究、元数据问题、单独代码任务或用户明确退出 → 不强制使用。
- 固定工作区只能是 `F:\AI-Video-Studio`。
- 每个视频一个 `projects/<slug>`。

### 2.2 项目级覆盖

新增：

```text
F:\AI-Video-Studio\AGENTS.override.md
```

它避免直接修改 Agentcut 每次启动都会覆盖的根 `AGENTS.md`，同时规定：

- 实际编辑前读取 Agentcut 生成的 `AGENTS.md` 和 `agentcut` Skill。
- 保留原始素材、工程、未验收渲染和最终输出。
- 不擅自使用付费服务或发布私有媒体。

### 2.3 配置备份

修改用户级配置前已备份：

```text
F:\CodexHome\config.toml.bak-ai-video-studio-20261127-003142
```

## 3. 专属 Skill

### 3.1 源与安装

唯一源：

```text
F:\AI-Video-Studio\skills\ai-video-studio
```

Codex 用户级安装入口：

```text
F:\CodexHome\skills\ai-video-studio
```

安装类型：Windows directory junction。

没有复制第二份正文，源文件修改后安装入口自动看到更新。

### 3.2 触发方式

Skill 描述同时包含中英文制作触发词，并明确排除：

- 纯知识问答与行业研究；
- 元数据问题；
- 只有代码、不产出视频的任务；
- 用户明确说不要使用 AI Video Studio。

自动发现已在独立新 Thread 的 Skill 目录中出现：

```text
- ai-video-studio: Create, edit, analyze, storyboard, caption, score, voice,
  preview, quality-check, render, or deliver an actual video...
  (file: F:/CodexHome/skills/ai-video-studio/SKILL.md)
```

### 3.3 内容覆盖

Skill 入口：

```text
skills/ai-video-studio/SKILL.md
```

按需引用：

- `references/project-lifecycle.md`
- `references/editorial-planning.md`
- `references/source-and-broll.md`
- `references/sound-captions-motion.md`
- `references/qa-delivery.md`

覆盖：

- 意图识别和简单/复杂任务分流。
- 项目创建、素材盘点、时间线规划和编辑。
- Agentcut MCP 使用。
- 预览、抓帧、人工审片和反馈循环。
- 渲染、完整解码和交付 QA。
- 项目持久化、项目隔离、归档和清理边界。

Skill 通过结构校验。

## 4. Agentcut MCP

### 4.1 稳定 Helper

旧 npx helper 位于临时 `_npx\<hash>` 路径，现改为一套固定安装：

```text
F:\AI-Video-Studio\software\agentcut-helper
```

运行版本：

```text
agentcut 0.2.33
```

稳定 CLI：

```text
F:\AI-Video-Studio\software\agentcut-helper\node_modules\agentcut\dist\studio\cli.js
```

稳定 MCP 入口：

```text
F:\AI-Video-Studio\software\agentcut-helper\node_modules\agentcut\dist\index.js
```

npm 安装后已审核并允许 5 个官方依赖安装脚本：

- agent-browser
- esbuild
- onnxruntime-node
- protobufjs
- sharp

### 4.2 用户级注册

注册于：

```text
F:\CodexHome\config.toml
```

服务名：

```text
agentcut
```

配置语义：

```toml
[mcp_servers.agentcut]
enabled = true
required = false
command = 'cmd.exe'
args = ['/d', '/s', '/c', 'call', 'F:\AI-Video-Studio\scripts\agentcut-mcp.cmd']
env = { AGENTCUT_WORKSPACE = 'F:\AI-Video-Studio', AGENTCUT_PORT = '32118' }
cwd = 'F:\AI-Video-Studio'
startup_timeout_sec = 60
tool_timeout_sec = 1800
supports_parallel_tool_calls = false
```

`codex mcp list --json` 已确认 `agentcut` 注册且启用。

普通 Thread 不再依赖 Agentcut 启动时的临时 MCP 注入。

### 4.3 冷启动包装入口

`scripts\agentcut-mcp.cmd` 是 Codex 启动全局 MCP 时实际调用的稳定命令：

1. 先执行 `ensure-agentcut-services.ps1`。
2. Helper、生产 Studio 和受控页面都健康后，再启动 Node MCP。
3. 把标准输入输出直接交给 Node 进程，避免 PowerShell 包装层破坏 MCP 协议。

这解决了“Codex 先启动、Helper 尚未运行”时，一个不完整 MCP 进程先占用 32118 的风险。

独立 MCP 客户端冷启动测试结果：

- 61 个 Agentcut 工具成功列出；
- `agentcut_status` 调用成功；
- workspace 为 `F:\AI-Video-Studio`；
- Studio 页面已连接；
- 项目 `workflow-cross-thread-test` 状态有效。

## 5. Helper 与 Studio 运行机制

启动/健康检查入口：

```text
F:\AI-Video-Studio\scripts\ensure-agentcut-services.ps1
```

职责：

1. 检查并启动稳定 Helper。
2. 检查并启动生产模式 Studio。
3. 使用独立 Chrome profile 打开受控 Studio 页面。
4. 验证 Helper、Studio 和浏览器端口。
5. 写入 `logs\agentcut\service-state.json`。

当前服务：

- Helper：`http://127.0.0.1:32118`
- Studio：`http://localhost:3000/studio`
- 受控浏览器 CDP：`127.0.0.1:9223`
- Studio 模式：`standalone production build`
- Studio 页面状态：`Connected`

后台页面使用：

```text
F:\AI-Video-Studio\cache\browser\agentcut-ui
```

独立 profile，不读取用户正常 Chrome 的 Cookie、密码或历史。

用户需要亲自审片时仍可打开：

```text
http://localhost:3000/studio
```

Studio 不再是每次开始工作的强制入口。

## 6. 独立新 Thread 验收

### 6.1 Thread 身份

- Thread：`AI Video Studio 跨线程验收`
- ID：`01a218b8-345e-7752-b40a-389163fdba6d`
- 启动目录：`E:\Codex\Workspaces\2026-11-27\ai-video-cross-thread-acceptance`
- 当前实施 Thread 的历史没有传给该 Thread。

### 6.2 用户请求

```text
帮我制作一个视频。做一个 8 秒的浅灰背景测试短片，中央白色文字先显示
“AI VIDEO STUDIO”，约 4 秒后切换为 “WORKFLOW READY”；16:9、720p、
无音频，只使用内置图形。项目名使用 workflow-cross-thread-test。
请直接按当前配置执行：创建独立项目、完成编辑并做预览核验，再尝试一次
本地 720p 渲染和基础 QA。不要使用付费服务，不要修改或覆盖已有项目。
```

### 6.3 自动发现结果

| 项目 | 结果 |
|---|---|
| 新 Thread 在 F 外启动 | PASS |
| 发现 `ai-video-studio` Skill | PASS |
| 加载全局路由 | PASS |
| 发现 `agentcut` MCP | PASS |
| 自动定位 `F:\AI-Video-Studio` | PASS |
| 创建独立项目 | PASS |
| MCP 修改项目 | PASS |
| 预览/抓帧/联系表 | PASS |
| 本地 720p 渲染 | PASS |
| 项目重启恢复 | PASS |

新 Thread 实际调用过的 Agentcut MCP 工具：

- `agentcut_capabilities`
- `agentcut_guide`
- `agentcut_status`
- `agentcut_create_project`
- `agentcut_read_files`
- `agentcut_write_file`
- `agentcut_components`
- `agentcut_capture_frames`
- `agentcut_preview_check`
- `agentcut_contact_sheet`

### 6.4 项目与渲染

项目：

```text
F:\AI-Video-Studio\projects\workflow-cross-thread-test
```

成片：

```text
F:\AI-Video-Studio\projects\workflow-cross-thread-test\renders\
workflow-cross-thread-test-wide-20261126-164140-720p-local.mp4
```

实测：

- 时长：8.000 秒
- 帧数：240
- 帧率：30 fps
- 分辨率：1280×720
- 视频：H.264 High，yuv420p
- 音轨：无，符合要求
- 文件大小：73,501 字节
- SHA-256：`9E849A56F97ED68F8D1651DBAA7C5B768D8259A4A5C2F26A6336F284824071E5`
- 全部 240 帧成功用 FFmpeg 解码为图片
- 4.00 秒处的文字切换通过抓帧和联系表检查
- 预览检查报告 0 dropped frames、0 stalls

### 6.5 重启持久化

独立 Thread 完成后，Helper、Studio 和受控浏览器均已停止并以稳定脚本重新启动。重新打开 Studio 后：

- 仍加载 `Workflow Cross Thread Test`
- 仍显示 `AI VIDEO STUDIO`
- 仍显示 8 秒时长
- 项目文件和渲染文件保持

### 6.6 限制

独立 Thread 尝试使用浏览器界面执行单次本地渲染时，本地页面 URL 受到当前应用安全检查限制，因此没有继续自动化界面。它改为调用 Agentcut 自带的 helper `runLocalRender` 入口，仍使用相同项目、相同 Remotion 运行时和相同项目输出目录，并完成实际渲染和全帧解码。

本机受控 Chrome 页面仍可显示该项目，用户可正常查看和继续编辑。

### 6.7 负向路由测试

在另一个独立 CLI Thread 中执行：

```text
请只用一句话解释视频剪辑是什么，不要创建、修改或渲染任何视频，
也不要进入 AI Video Studio 工作流。
```

结果：

- 返回一句话解释视频剪辑；
- 没有调用 `agentcut_create_project`；
- 没有修改项目或渲染；
- 没有调用任何 Agentcut 编辑工具。

这验证了全局路由没有把所有提到“视频”的问题强制送入制作流程。

### 6.8 最终 MCP 冷启动验证

在关闭 Helper、Studio 和受控浏览器后，创建另一个全新的 Codex Thread：

- Thread：`AI Video Studio MCP 冷启动验证`
- ID：`01a218ce-7021-7e01-ae2a-05b3f5de77f7`
- 启动目录：`E:\Codex\Workspaces\2026-11-27\ai-video-mcp-cold-start`

用户只要求调用 `agentcut_status`，没有提供任何配置背景。

结果：

- 新 Thread 自动发现用户级 Agentcut MCP；
- 包装入口自行启动完整 Helper、生产 Studio 和受控浏览器；
- `agentcut_status` 成功完成；
- MCP 版本 0.2.33；
- workspace 为 `F:\AI-Video-Studio`；
- Studio 页面已连接；
- 当前项目能以 wide 预览打开，且没有构建或校验错误。

该测试确认最终 MCP 配置不依赖预先运行的手工终端或易变 npx 路径。

## 7. 仓库与文件变更

远端仓库：

```text
https://github.com/videostudiooo/customizedworkflow
```

本次新增/修改的仓库内容：

```text
.gitignore
AGENTS.override.md
CHANGELOG.md
LICENSE
README.md
config/
  agentcut-launch.ps1
  agentcut-local-studio.ps1
  codex-mcp.agentcut.example.toml
  npmrc
  paths.md
docs/
  ARCHITECTURE.md
  LICENSING.md
  USAGE.md
reports/
  AGENTCUT-POST-DEPLOYMENT-ACCEPTANCE.md
  AI-VIDEO-STUDIO-WORKFLOW-INTEGRATION-AUDIT.md
  AI-VIDEO-STUDIO-WORKFLOW-IMPLEMENTATION-REPORT.md
scripts/
  build-agentcut-studio.ps1
  cleanup-cache.ps1
  ensure-agentcut-services.ps1
  install-codex-integration.ps1
  agentcut-mcp.cmd
  publish-github.ps1
  verify-workflow.ps1
skills/
  ai-video-studio/
    SKILL.md
    agents/openai.yaml
    references/*.md
templates/
  project-brief.md
  qa-report.md
  shot-plan.md
workflows/
  README.md
  global-router.md
```

运行时生成的 Agentcut 文件、Node 依赖、媒体、缓存、代理、渲染、模型和浏览器数据均被 `.gitignore` 排除。

## 8. 本地清理

清理阶段起点：

- F 盘可用：69.26 GB

最终：

- F 盘可用：71.34 GB
- 净回收：约 2.08 GB
- C 盘最终可用：34.10 GB

最终 C 盘可用空间相对实施前快照下降了约 5.5 GB。复核显示：

- Agentcut 默认用户目录和默认 npm cache 没有大型写入；
- 最新页文件只增加约 1.2 GB；
- 已知用户缓存中没有发现本轮新增的单文件 20 MB 以上对象；
- WinSxS、Installer 和 Windows Temp 没有对应的大型增长；

该下降不能归因于 Agentcut 项目或视频缓存，较可能来自并行的系统/用户应用活动。建议后续观察，而不是未经核实删除系统文件。

已清理类别：

- 旧 npx helper 缓存：约 584 MB
- npm `_cacache`：已通过 `npm cache clean --force` 清理
- Next.js 构建缓存：约 532 MB
- Remotion webpack 缓存：约 283 MB + 270 MB，渲染时会再生
- 旧测试 Chrome profile：约 203 MB
- 已解压的 Node 安装 ZIP：约 38 MB
- 已解压的 Agentcut Studio 源码归档：约 41 MB
- 新 Thread 临时逐帧解码帧：约 56 MB
- 旧测试截图、空日志和重复报告：小量

统计：

- 具名清理项：18
- 具名文件：8,149 个
- 另有 npm cache 内容
- 净可用空间增长：约 2.08 GB

未清理：

- `software\node`
- `software\agentcut-helper`
- 生产 Studio runtime
- 项目预览与本地渲染依赖
- 当前测试工程和实际成片
- 当前受控浏览器 profile
- 原始项目、输出和必要日志

## 9. GitHub 提交与远端验证

主实现已提交并推送。

- 初始远端提交：`ec9c86260d8754ded41dca3ef20f28343a6aa8e3`
- 主实现提交：`c2adc851f882c6cdcc3b73091bb9ae274c219e12`
- 提交 URL：
  [c2adc851](https://github.com/videostudiooo/customizedworkflow/commit/c2adc851f882c6cdcc3b73091bb9ae274c219e12)
- 远端 tree：`0cb553d8fd519ed7346d0733395f36225c75a5ed`
- 本地 Git tree：`0cb553d8fd519ed7346d0733395f36225c75a5ed`
- 提交文件数：34
- 本地 tree 与远端 tree 完全一致。
- 文档复核提交：`7b0f28d747455f61099a58c06340681002084ec5`
- 负向路由复核提交：`923fbc6c8ec50ce00e23292ca9d5896b5731c016`
- 最终验收报告提交：`68465326d9b48afcdd3fb09964adf4598c0002db`
- 本地镜像提交：`9f9ffd0371d54fcd03b98c5393fbe1e5cdac7fde`
- MCP 冷启动修复提交：`554a1faa62ad78d1da430f1124ec8ae9a3a536f3`
- 服务状态修复提交：`83c1b2c4e3e915c633866c6fd2f849691ff06868`
- 验证脚本修复提交：`107b5542005850af8695264e2e1d5adfbdc6792a`
- 复核前本地与远端 tree：`ac29ddf3bb7c92408810d62e79cb9623f5309878`

远端已重新读取并验证：

- `skills/ai-video-studio/SKILL.md` 内容存在且可读。
- `scripts/ensure-agentcut-services.ps1` 内容存在且可读。
- 本实施报告存在且可读。
- GitHub 提交历史中主实现提交位于初始提交之后。

Git 的直连 fetch/push 在当前网络下仍受 Git TLS 握手限制，因此远端提交通过已授权的 GitHub API 写入；落盘前已检查暂存 diff、空白错误、树哈希和敏感信息。该传输限制不影响本地仓库、远端内容或提交记录。

## 10. 当前限制与风险

1. 全局 `agentcut` MCP 会出现在建议的 MCP 列表中，但只在实际视频任务中使用。短全局路由和 Skill 描述负责限制误触发。
2. Helper 必须处于运行状态。缺失时 Skill 会调用幂等服务脚本；未经重启的极旧 Thread 可能需要新 Thread 才能加载新增工具。
3. Studio 的视觉能力需要连接页面。当前用后台受控 Chrome 维持连接，项目预览和抓帧已验证。
4. 本地页面 URL 安全校验可能阻止部分浏览器自动化操作；MCP 抓帧、预览检查和 helper 本地渲染仍已通过。
5. Agentcut 的 headless shell 在本机第一次渲染可能崩溃，随后会自动使用完整 Chrome。增加了首渲染时间和约 440 MB 浏览器依赖。
6. 一项独立 Thread 正向验收和一项独立 CLI 负向路由测试已通过。更复杂的多语言、含视频上下文但实际只要求代码的边界仍应通过日常使用逐步积累测试。
7. Remotion 的商业许可独立于 Agentcut 的 MIT 许可证，正式商业使用仍需核对组织资格。
8. Codex 启动时有一个 Agentcut 工具定义出现非阻塞 schema 警告；本次验收涉及的创建、读写、抓帧、预览和 QA 工具均可正常使用。

## 11. 日常使用方法

直接告诉 Codex：

```text
把 F:\AI-Video-Studio\assets\inbox 里的素材剪成一条 30 秒产品短片，
9:16，节奏利落，字少一点，偏电影感。先给我预览，确认后再导出 1080p。
```

需要明确退出时：

```text
这次不要用 AI Video Studio，只帮我分析视频处理方案。
```

一般不需要手动运行命令或打开 Studio。

如果服务已停止，可运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AI-Video-Studio\scripts\ensure-agentcut-services.ps1"
```

## 12. 最终状态

**PASS WITH LIMITATIONS**

核心目标是真实可行的：一个在 F 盘之外启动、没有前序背景的新 Codex Thread，能够仅凭自然语言需求，自动进入 AI Video Studio 工作流、调用 Agentcut MCP、创建独立工程、完成预览与渲染，并在重启后恢复项目。

剩余限制集中在本地页面自动化安全校验、首渲染浏览器回退和更复杂边界情况下的路由稳定性，不影响当前主流程运行。
