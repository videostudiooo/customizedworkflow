# AI Video Studio

AI Video Studio is a Codex-first video production workflow built around Agentcut.
The user supplies the creative intent, reference material and acceptance criteria.
Codex plans the edit, calls the local Agentcut MCP tools, reviews the actual frames,
and delivers an editable project plus a verified render.

## Runtime

- Workspace: `F:\AI-Video-Studio`
- Agentcut: `0.2.33`
- Node.js: `24.22.3`
- Codex CLI: `0.147.0` or compatible
- Helper: `http://127.0.0.1:32118`
- Studio: `http://localhost:3000/studio`

## Use

Start or verify the local services once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AI-Video-Studio\scripts\ensure-agentcut-services.ps1"
```

Then ask Codex normally:

```text
把这个目录里的素材剪成一条 30 秒节奏明快的产品短片，
16:9，电影感一点，先给我预览，我确认后再导出。
```

The global AI Video Studio Skill recognizes production work and uses the fixed
Agentcut workspace. Research questions and standalone code tasks do not enter
the video workflow automatically.

## Architecture

```text
global router
  -> ai-video-studio Skill
     -> Agentcut MCP + local Helper
        -> Studio page for preview and visual QA
           -> projects/<slug>
              -> verified output/<slug>
```

The router is deliberately small. Production method lives in the Skill,
project state lives in each Agentcut project, and executable capabilities come
from MCP rather than copied instructions.

## Repository layout

```text
skills/ai-video-studio/   Codex Skill and task-specific references
workflows/                Durable workflow and router source
templates/                Brief, shot-plan and QA templates
scripts/                  Install, service and verification helpers
config/                   Stable launch and MCP templates
docs/                     Architecture and usage notes
reports/                  Sanitized implementation and QA reports
projects/                 Local video projects; media and state are not committed
assets/                   Local source media; never committed
library/                  Local shared media; never committed
output/                   Approved deliverables; never committed
```

Agentcut-generated `.agentcut/`, `.agents/`, `.claude/`, `AGENTS.md`,
`CLAUDE.md`, package manifests and `node_modules/` are runtime state and are
not repository sources.

## Safety

- Never commit original media, proxies, renders, models or credentials.
- Never delete approved outputs or unknown project state during cache cleanup.
- Keep every video in its own `projects/<slug>`.
- Do not enable paid providers or upload private media without explicit consent.

## Install or refresh Codex integration

The installer preserves backups of modified Codex user configuration:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AI-Video-Studio\scripts\install-codex-integration.ps1"
```

Restart Codex or start a new thread after changing MCP configuration.

## Verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AI-Video-Studio\scripts\verify-workflow.ps1"
```

See [docs/USAGE.md](docs/USAGE.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
