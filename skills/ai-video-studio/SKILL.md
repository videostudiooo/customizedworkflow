---
name: ai-video-studio
description: Create, edit, analyze, storyboard, caption, score, voice, preview, quality-check, render, or deliver an actual video through AI Video Studio and Agentcut. Use for 视频制作、混剪、剪辑、镜头分析、镜头编排、字幕、配音、配乐、转场、渲染和成片 QA. Do not use for video-industry research, software discussion, metadata-only questions, or code-only work unless the requested outcome is a produced or modified video.
---

# AI Video Studio

Use the fixed local studio:

```text
F:\AI-Video-Studio
```

The user owns creative direction and final acceptance. You own the production work needed to turn a brief, footage, or a requested change into an editable Agentcut project, a reviewed preview, and a verified deliverable.

## Route the request

Use this workflow when the user asks to create, edit, rearrange, caption, score, voice, preview, quality-check, render, or deliver video. Also use it when the user asks for creative shot analysis that will feed an edit.

Do not enter this workflow for:

- general video knowledge or industry research;
- evaluating video software without producing media;
- writing a standalone video-processing script when the requested result is code rather than a video;
- any task where the user explicitly says not to use AI Video Studio.

If it is unclear whether the user wants production or only advice, answer the question or ask one focused question before mutating a project.

## Start the session

1. Call `agentcut_capabilities`.
2. Call `agentcut_guide` for `SKILL.md`; load only the Agentcut guide relevant to the job.
3. Call `agentcut_status`.

If the Agentcut tools are absent after this skill was discovered, do not imitate Agentcut by rewriting media with unrelated scripts. Report that the global MCP did not load and that Codex must be restarted or a new thread used.

If the tools exist but Helper or the Studio page is unavailable, run the idempotent service check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AI-Video-Studio\scripts\ensure-agentcut-services.ps1"
```

Retry status once. If it still cannot connect, report the concrete port or page error.

## Choose the project

Use one project for one video thread.

- When the user names an existing project, open and inspect it before changing anything.
- For a new production, call `agentcut_create_project` with a semantic lowercase slug.
- Keep the project assigned by `agentcut_create_project`; pass its `project` explicitly to later tools.
- Never place a new video in an existing unrelated project merely because Studio has it open.
- Use `agentcut_create_cut` for an independent source-based clip or alternate version inside the same canvas.
- Do not create a second video-studio root.

Read [references/project-lifecycle.md](references/project-lifecycle.md) for project state, persistence, delivery, and cleanup rules.

## Size the production correctly

Classify the request before building:

- **Direct edit**: one small, reversible change such as text replacement, trim, one added asset, or a small timing adjustment. Inspect only what is affected, make the edit, and verify the result.
- **Guided production**: a new narrative, multiple sources, shot selection, captions/voice/music synchronization, visual design, or a video longer than roughly 30 seconds. Form a concise brief and shot/beat plan before creating every scene.
- **Analysis only**: inspect and explain footage without editing unless the user explicitly asks to apply the findings.

Assume reversible defaults when details are missing, state them briefly, and continue. Ask only questions whose answers materially alter the output.

For guided production, read:

- [references/editorial-planning.md](references/editorial-planning.md)
- [references/source-and-broll.md](references/source-and-broll.md)
- [references/sound-captions-motion.md](references/sound-captions-motion.md)

For a direct edit, load only the relevant reference.

## Work with evidence

- Treat source media as read-only.
- Measure duration, dimensions, frame rate, rotation, audio and stream facts before timing clips.
- Use `agentcut_media_info`, transcription, audio analysis and contact sheets instead of guessing.
- Preserve source provenance and rights notes for imported or downloaded media.
- Keep editable meaning on the timeline: text, captions, music, voice, SFX, images and scene clips belong in `layers.json`.
- Read `project.json` and `layers.json` immediately before a manual-format edit; preserve user changes.
- Use Agentcut components before writing a custom effect when an existing component fits.

## Build and review

Build one meaningful beat at a time. After each major picture change:

1. call `agentcut_status`;
2. capture representative frames for wide and mobile;
3. inspect the actual images;
4. fix clipping, unreadable type, timing, contrast and layout defects;
5. continue only when the beat is usable.

For complex work, produce a low-resolution draft or a small set of review frames before the master. Treat a successful command or render as technical evidence, not creative approval.

When the user asks for changes, edit the same project unless they explicitly want a new version. Re-review only the changed shots plus any shared timing/element dependencies.

## Export and QA

Export only when the user asks for a render, export or file. First read [references/qa-delivery.md](references/qa-delivery.md).

- Use Agentcut's preview, contact sheet, frame capture and audio checks for in-editor review.
- Use `agentcut_export` for browser export or the Studio's local-render path when browser export cannot draw the project.
- Verify the produced file, not only the process exit code.
- Check technical properties, full playback, picture-text mistakes, black/frozen/silent intervals, audio sync, captions and rights notes.
- Report the exact output path, duration, dimensions, frame rate, codecs, file size and checksum when available.
- Keep project renders until the user accepts. Copy an approved final into `F:\AI-Video-Studio\output\<slug>\`; do not move or delete the project copy.

## Safety and spending

- Never upload, publish or transmit private media without explicit direction.
- Do not enable paid providers or buy services. Use free/local Agentcut capabilities by default.
- Do not put API keys in prompts, project files, logs or Git.
- Do not delete originals, projects, approvals, final outputs or unknown files.
- Only regenerable caches may be removed under the cleanup rules in [references/project-lifecycle.md](references/project-lifecycle.md).

## Final handoff

Give a concise receipt:

- what was made or changed;
- project slug and editable project path;
- preview/review evidence;
- render path and checksum if exported;
- known limitations or unverified creative risks;
- what is easy for the user to adjust next.
