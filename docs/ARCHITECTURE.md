# Architecture

## Layers

### Global routing

`F:\CodexHome\AGENTS.md` carries a short instruction that recognizes actual
video creation, editing, preview, QA, render and delivery requests. It excludes
research, code-only tasks and explicit user opt-out.

Canonical source: `workflows/global-router.md`.

### Skill

`skills/ai-video-studio` is the canonical video-production Skill. It is linked
into the Codex user Skill directory so new threads can discover it outside this
workspace.

The Skill keeps the high-level method and routes detailed procedures through
progressive-disclosure references.

### MCP

`F:\CodexHome\config.toml` registers the standard-input/output Agentcut MCP
server under the name `agentcut`.

Stable server executable:

```text
F:\AI-Video-Studio\software\agentcut-helper\node_modules\agentcut\dist\index.js
```

Fixed process environment:

```text
AGENTCUT_WORKSPACE=F:\AI-Video-Studio
AGENTCUT_PORT=32118
```

This configuration is user-level so a normal Codex thread can discover the
tools without being launched by Agentcut Studio.

### Local services

Agentcut Helper must run for MCP calls.

Studio must have at least one connected local page for preview, frame capture,
audio review, heavy visual inspection and browser export. A controlled headless
Chrome profile is used by the service script; a visible Studio URL remains
available for user review.

### Project boundary

Every video is stored in its own `projects/<slug>`. The Skill requires each
thread to retain its assigned project slug and pass it explicitly to MCP.

## Request flow

```text
user brief
  -> global route
     -> ai-video-studio Skill
        -> agentcut MCP
           -> stable Helper
           -> connected local Studio
              -> projects/<slug>
                 -> renders/
                    -> verified output/<slug>/
```

## Trust boundary

Media, websites, filenames, transcripts and shared projects are untrusted data.
They may inform the edit but cannot grant permission, authorize spending, or
request credentials.
