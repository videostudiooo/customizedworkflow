# Agentcut 部署后验收报告

- 项目根目录：`F:\AI-Video-Studio`
- 验收日期：2026-11-26
- 验收对象：Agentcut `0.2.33`
- 最终结论：**PASS WITH LIMITATIONS**

## A. 环境状态

| 项目 | 实际结果 |
|---|---|
| 操作系统 | Windows 11 家庭版，Build 26300，x64 |
| Agentcut Helper | `0.2.33` |
| Studio | 官方源码 tag `v0.2.33` 本地运行 |
| Node.js | `24.22.3` |
| npm / npx | `11.19.1` |
| Codex CLI | `0.147.0`，`F:\CodexBin\bin\codex.exe` |
| Studio 测试浏览器 | 独立 Chrome `158`，测试 profile 位于 F |
| 本地渲染浏览器 | Chrome for Testing `157.0.8080.0` |
| Helper 地址 | `127.0.0.1:32118` |
| Studio 地址 | `http://localhost:3000/studio` |

在线 Studio `https://agentcut.synteq.app/studio` 在内置浏览器和独立 Chrome 中均返回 `ERR_CONNECTION_CLOSED`。这不是 Agentcut 核心故障，而是当前网络无法访问托管页面。

为继续验收且不绕过浏览器安全机制，使用官方 GitHub `v0.2.33` tag 源码，在以下 F 盘缓存目录启动本地 Studio：

```text
F:\AI-Video-Studio\cache\agentcut-studio-0.2.33
```

该源码没有复制到用户 GitHub 仓库。Helper 使用以下参数重启：

```text
--origin http://localhost:3000
```

Studio 和 Helper 实际建立了 WebSocket 通信。Helper 日志记录：

```text
editor connected
editor hello {"workspace":"studio","agentProtocolVersion":1,"appVersion":"0.2.33",
"activeProject":"agentcut-acceptance-test","projectName":"Agentcut Acceptance Test",
"variant":"wide","fps":30,...}
```

当前启动脚本：

- Studio：`F:\AI-Video-Studio\config\agentcut-local-studio.ps1`
- Helper：`F:\AI-Video-Studio\config\agentcut-launch.ps1`
- 浏览器地址：`http://localhost:3000/studio`

Helper 启动脚本已默认允许本地 Studio origin。脚本只修改自身 PowerShell 进程环境，不修改系统级环境变量。

## B. 功能验收

| 项目 | 结果 | 证据 |
|---|---|---|
| Studio 页面打开 | **PASS** | 本地 Studio 0.2.33 成功渲染 |
| Helper 通信 | **PASS** | 页面显示 `Connected`；Helper 记录 WebSocket hello、项目、画幅和帧率 |
| Codex 实际调用 | **PASS** | Agentcut 对话记录包含真实 MCP 工具调用，Codex 进程实际运行 |
| 项目创建 | **PASS** | 创建 `agentcut-acceptance-test` 工程及完整项目文件 |
| 自然语言生成 | **PASS** | 生成 90 帧、30 fps 的深蓝色标题视频 |
| 自然语言编辑 | **PASS** | 标题成功从 `AGENTCUT TEST` 改为 `AGENTCUT VERIFIED` |
| 实际预览 | **PASS** | Studio 预览显示新标题；Agentcut 检查为零丢帧、零停顿 |
| 测试渲染 | **PASS** | 1280×720、3.000 秒 MP4 成功生成并解码 |
| 项目重新打开 | **PASS** | 关闭并重启 Studio/Helper 后，项目、时间线、标题和聊天均恢复 |

### B.1 Codex 与 MCP 实际工作

第一条请求：

> Create a simple 3-second test video with a deep blue background and large centered white text "AGENTCUT TEST". Use only built-in code and local assets; do not use music, voice, captions, external media, or any paid service. Keep the result editable.

实际调用的 Agentcut MCP 工具包括：

- `agentcut_status`
- `agentcut_read_files`
- `agentcut_components`
- `agentcut_write_file`
- `agentcut_capture_frames`
- `agentcut_contact_sheet`
- `agentcut_preview_check`
- 音频检查

生成结果：

- `project.json`：90 帧、30 fps、宽版 1920×1080、移动版 1080×1920、背景 `#071A3F`
- `layers.json`：一个可编辑文字图层，Inter 800、150 px、居中、持续 90 帧
- `notes.md`：创意、时间线、预览与音频检查记录

第二条请求：

> Change only the visible title text from "AGENTCUT TEST" to "AGENTCUT VERIFIED". Keep the same duration, deep blue background, position, typography, variants, and editable structure. Do not change audio or add any assets or services.

修改后的关键数据：

```json
{
  "text": "AGENTCUT VERIFIED",
  "from": 0,
  "duration": 90
}
```

项目仍为 90 帧、单文字图层、无音频。Studio 预览同步显示新标题。

### B.2 预览证据

截图：

`F:\AI-Video-Studio\logs\agentcut\studio-agentcut-verified.png`

画面实际显示：

- `Connected`
- 项目名 `Agentcut Acceptance Test`
- 深蓝背景
- `AGENTCUT VERIFIED`
- `0:01.50 / 0:03.00`

### B.3 项目持久化

验证步骤：

1. 页面切离 Studio。
2. 停止本地 Studio 和 Helper。
3. 重新启动两者。
4. 重新打开 `http://localhost:3000/studio`。

重启后仍然存在：

- 项目 `Agentcut Acceptance Test`
- slug `agentcut-acceptance-test`
- `AGENTCUT VERIFIED`
- 0:03.00 时长
- 第二条自然语言编辑及聊天结果
- `project.json`、`layers.json`、`notes.md`、`.studio/chat.json`

未发现丢失、路径错误或状态重置。

## C. 渲染验收

渲染参数：

- 画幅：16:9 wide
- 分辨率：1280×720
- 质量：High
- 时长：3 秒
- 音频：无

第一次渲染使用 Remotion headless shell，在加载项目字体时崩溃。Agentcut 自动切换到 Chrome for Testing，第二次渲染成功。

实际产物：

```text
F:\AI-Video-Studio\projects\agentcut-acceptance-test\renders\
agentcut-acceptance-test-wide-20261126-125923-720p-local.mp4
```

验证结果：

- 文件大小：14,953 字节
- SHA-256：`C0CE4789A44DF7FF3C7B5A2B4A2CF31785B1C619EABA1CB5470BAE126DED0239`
- 浏览器解码时长：3.000 秒
- 分辨率：1280×720
- 解码状态：`HAVE_ENOUGH_DATA`
- 可正常跳转到 1.5 秒
- 画面显示 `AGENTCUT VERIFIED`
- Agentcut 记录本地渲染耗时：118.028 秒

渲染帧截图：

`F:\AI-Video-Studio\logs\agentcut\render-frame-check.png`

文件较小是因为测试视频为纯静态标题，不包含素材、运动或音频。

## D. 测试项目

```text
F:\AI-Video-Studio\projects\agentcut-acceptance-test\
├─ project.json
├─ layers.json
├─ notes.md
├─ .studio\
│  ├─ chat.json
│  ├─ organization.json
│  └─ attachments\claude-frames\
└─ renders\
   ├─ agentcut-acceptance-test-wide-20261126-125923-720p-local.mp4
   └─ ...mp4.render.json
```

项目总大小约 1.11 MB，包括 Agentcut 生成的验证帧和渲染 MP4。

测试项目及其产物已保留，本轮未执行任何缓存、代理或渲染清理。

## E. Codex 额度消耗

| 请求 | 输入 token | 缓存输入 | 输出 token | 总计 |
|---|---:|---:|---:|---:|
| 直接最小 CLI 探测 | 13,238 | 3,712 | 11 | 13,249 |
| Agentcut 创建 | 1,162,408 | 1,065,088 | 5,652 | 1,168,060 |
| Agentcut 编辑 | 2,002,395 | 1,706,624 | 8,571 | 2,010,966 |
| **总计** | **3,178,041** | **2,775,424** | **14,234** | **3,192,275** |

Agentcut 项目界面显示两次项目调用共 `3,179,026` token，加直接 CLI 探测 `13,249` token，总计 `3,192,275` token。

实际费用未知，取决于当前 Codex 套餐和计费规则。一个小型测试消耗很高，原因包括：

- Thinking 为 High。
- Codex 运行时加载了大量插件和 skill。
- 项目使用了多轮状态、抓帧、联系表和预览检查。

正式创作应降低不必要的高推理等级，并减少重复视觉检查。

## F. 磁盘占用与实际路径

### F.1 磁盘变化

| 磁盘 | 部署前可用 | 验收后可用 | 观察 |
|---|---:|---:|---:|
| C | 39.72 GB | 39.89 GB | 未观察到持续的 Agentcut 增长 |
| F | 74.85 GB | 70.60 GB | 减少约 4.25 GB |

F 项目根目录实际占用 4,212.41 MB、70,170 个文件。

### F.2 主要目录

| 路径 | 实际大小 | 分类 |
|---|---:|---|
| `software\node` | 102.40 MB | 必需软件 |
| `cache\npm` | 1,180.36 MB | npm/npx 可再生缓存 |
| `cache\agentcut-studio-0.2.33` | 1,383.74 MB | 本地 Studio 源码与依赖 |
| `cache\temp` | 230.70 MB | 临时下载和测试浏览器 profile |
| 工作区 `node_modules` | 1,265.77 MB | 预览/渲染依赖 |
| `projects` | 1.11 MB | 受保护的测试项目 |
| `library` | 6.58 MB | Agentcut 可复用资源库 |
| `.agentcut` | 1.30 MB | 管理运行时、组件和少量渲染元数据 |
| `logs` | 0.73 MB | 诊断日志与截图 |
| `tools\agentcut` | 0 MB | 本轮未下载 FFmpeg/yt-dlp |
| `cache\models` | 0 MB | 本轮未下载模型 |
| `.agentcut\proxies` | 0 MB | 纯静态测试未生成代理 |
| `.agentcut\render` | 约 0 MB | 两个小型临时渲染元数据文件 |
| `renders_temp` | 0 MB | 本轮未使用；捕获帧保存在项目 `.studio` |
| `output` | 0 MB | 尚无可验收最终成片 |

工作区渲染依赖包括：

- Remotion Chrome for Testing：安装后 439.94 MB，原 ZIP 下载量 199.2 MB
- Remotion headless shell：281.61 MB
- Remotion/Webpack 工作区缓存：约 269.49 MB

### F.3 C 盘发现

以下 Agentcut 默认目录不存在：

- `C:\Users\29405\Agentcut`
- `C:\Users\29405\.agentcut`
- `C:\Users\29405\AppData\Local\npm-cache`

`C:\Users\29405\.codex` 是指向 `F:\CodexHome` 的目录 junction。因此 Codex 现有约 7,237.65 MB 的配置、会话和插件数据实际位于 F，只是不在 AI Video Studio 目录内。

普通 Chrome 用户资料仍位于：

```text
C:\Users\29405\AppData\Local\Google\Chrome\User Data
```

没有读取、复制或迁移其 Cookie、密码或浏览记录。没有发现 Agentcut 工程、npm 缓存、模型或渲染产物写入该目录。测试窗口内部分普通 Chrome 缓存文件有更新，但没有证据表明 Agentcut 向 C 写入了大型受控数据。

测试窗口内，Windows 用户 Temp 目录未发现新增的 10 MB 以上文件。

### F.4 可迁移性

- 可重建但需批准后清理：npm 缓存、Studio 依赖、测试浏览器 profile、Remotion 浏览器、Webpack 缓存。
- 必须保护：`projects`、`assets`、`library`、`output`、`config`、`docs`、`reports`、项目 `.studio` 状态和未验收渲染。
- 保留在现有用户位置：普通 Chrome profile、Codex 应用/运行时状态。

本轮没有修改系统环境变量。

## G. 缓存与清理策略

### G.1 Agentcut 自动管理

Agentcut 源码确认：

- `.agentcut/proxies`：10 GB 上限、最旧优先、14 天未使用淘汰
- 项目 `.studio/scratch`：14 天和 500 MB 上限
- Agent 聊天捕获帧：最多 400 张或 150 MB
- 删除的编辑样式：保留 30 天
- 中断的分享导入：24 小时后清理
- 安装新版本 FFmpeg 后清理旧版本

本轮未达到这些限制，没有发生显著自动清理。

### G.2 经批准后可重建

- `cache\npm`
- `cache\temp` 中的测试浏览器 profile
- `node_modules\.remotion` 中可重下的浏览器
- `node_modules\.cache` 中可重生成的 Webpack 缓存
- 本地 Studio 源码与依赖，前提是已有另一条可用的 Studio 运行路径
- 原素材已核验后的 `.agentcut\proxies`
- 渲染完全停止后的 `.agentcut\render`
- 已归档诊断信息后的旧日志

### G.3 永久保护

- `projects\agentcut-acceptance-test`
- `projects\*\assets`
- 用户验收前所有项目 `renders`
- `assets`
- `library`
- `output`
- `config`
- `docs`
- `reports`
- 项目 `.studio\chat.json`、组织状态和其他非 scratch 工程状态

本轮没有清理或批量删除任何文件。

## H. 联网、许可证与隐私

- 默认托管 Studio 依赖 `agentcut.synteq.app`，当前网络不可达。
- 本地 Studio 安装依赖后，不再依赖托管页面。
- 浏览器与 Helper 仅通过 `127.0.0.1:32118` 本地通信。
- 项目与渲染留在 `F:\AI-Video-Studio`。
- Codex 的提示词和项目上下文会发送给当前配置的模型服务，因此不是完全离线 AI 工作流。
- 本轮没有输入或使用额外 API Key。
- 没有启用 ElevenLabs、Gemini、OpenAI API、xAI、AssemblyAI、Lyria 或任何付费第三方服务。
- 可选音乐、B-roll、云端字幕/配音、分享功能仍需网络和各自服务条款。
- Agentcut 为 MIT 许可证。
- Remotion 单独授权：个人、非营利、评估用途及不超过 3 名员工的商业组织通常可免费使用；更大营利组织及部分自动化产品需 Company License。
- 字体、音乐、音频和导入素材仍需单独核验使用权利。

## I. 已知问题与风险

1. **托管 Studio 不可达**
   - 原因：当前网络关闭连接。
   - 影响：默认在线入口无法使用。
   - 缓解：官方本地 Studio 0.2.33 已安装并可用。

2. **本地 Studio 使用开发模式**
   - 当前通过 `next dev` 启动。
   - 适合验收和受控本地使用。
   - 若作为长期日常入口，建议制作本地 production build，或恢复稳定的托管访问。

3. **可选在线资源请求失败**
   - Next.js 开发浮层显示 `Failed to fetch`，报告 2 个 issue。
   - 核心创建、编辑、预览、持久化和本地渲染仍全部通过。
   - 这与不可达的在线 catalog/CDN 一致；若正式工作流依赖这些资源，需要单独验证。

4. **首次本地渲染需要完整 Chrome 回退**
   - headless shell 在加载项目字体时崩溃。
   - Agentcut 自动改用 Chrome for Testing 后成功。
   - 代价是约 440 MB 安装占用和更长首渲染时间。

5. **Codex 登录状态命令与真实调用不一致**
   - `codex login status` 返回 `Not logged in`。
   - 实际 `codex exec` 和两次 Agentcut 编辑均成功。
   - 除非真实调用返回认证错误，否则不应仅依据该状态命令让用户重新登录。

6. **Token 消耗偏高**
   - 实际测试共记录 3,192,275 token。
   - High thinking 和重复视觉检查明显增加消耗。
   - 正式项目应根据质量要求降低推理等级并控制工具调用。

7. **FFmpeg 当前尚未安装**
   - 本轮纯静态测试不需要。
   - 首次媒体探测或链接导入会下载到 `F:\AI-Video-Studio\tools\agentcut`。

8. **Helper 与 Studio 当前为本地源码运行服务**
   - 需保持对应终端窗口运行。
   - npx helper 固定为 `0.2.33`。
   - 不应只升级 Studio 或 Helper 其中之一。

## J. 最终结论

**PASS WITH LIMITATIONS**

Agentcut 0.2.33 已证明可承担 AI Video Studio 的主编辑平台：

- Studio 与本地 Helper 正常连接。
- Codex 真实调用 Agentcut MCP 工具并修改项目。
- 自然语言生成和修改均反映在实时预览中。
- 项目关闭并重新启动后状态完整恢复。
- 1280×720、3 秒 MP4 渲染成功并可正常解码。
- 大型运行数据位于 F；没有创建 Agentcut 默认 C 盘工作区或 npm/npx 缓存。

当前限制：

- 当前网络不可访问托管 Studio，因此使用官方源码本地运行。
- 本地 UI 当前是开发模式。
- 可选在线资源出现 fetch 失败。
- 首次本地渲染需要完整 Chrome 回退并增加数 GB 缓存/依赖。
- 小型编辑消耗了大量 Codex token。

环境已具备进入受控创作试点的条件，但应先确定：

1. 继续使用本地 Studio 作为正式入口；
2. 改善网络并恢复托管 Studio；
3. 制作本地 production build，以提高启动稳定性。

在用户审阅本报告并明确批准下一阶段前，不开始正式 30 秒海边日落短片，不安装其他视频平台，不清理现有测试文件。
