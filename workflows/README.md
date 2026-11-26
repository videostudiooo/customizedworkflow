# Workflows

The production workflow is split by responsibility:

- `global-router.md`: global task recognition and exclusions.
- `skills/ai-video-studio/SKILL.md`: the operational method Codex loads when a video task matches.
- `templates/`: project brief, shot plan and final QA receipts.
- `docs/ARCHITECTURE.md`: system boundaries and startup dependencies.

The normal flow is:

1. Recognize actual production work.
2. Verify Agentcut MCP, Helper and Studio availability.
3. Open an existing project or create a unique project.
4. Inspect source assets and establish measured facts.
5. Plan only as much as the complexity requires.
6. Build and review one meaningful beat at a time.
7. Export when requested and verify the resulting file.
8. Copy only the accepted deliverable to `output/<slug>`.

The workflow must preserve editable project state. Do not replace an editable
Agentcut project with a one-off FFmpeg command.
