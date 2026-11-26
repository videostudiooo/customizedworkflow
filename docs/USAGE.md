# Usage

## Daily use

1. Open Codex.
2. State the video goal, source location, desired feel and delivery target.
3. Let the AI Video Studio workflow inspect, plan, build and preview.
4. Review the preview and provide concrete changes.
5. Ask for export when the creative result is accepted.
6. Review the final QA receipt and file.

Example:

```text
把 F:\AI-Video-Studio\assets\inbox 里的素材剪成一条 45 秒产品介绍，
9:16，稳、克制、有科技感。先给我 720p 预览，不要用付费声音服务。
```

## Explicit opt-out

```text
这次不要用 AI Video Studio，只帮我分析视频处理方案。
```

## Service check

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AI-Video-Studio\scripts\ensure-agentcut-services.ps1"
```

Add `-VisibleBrowser` when you want the controlled Studio page to use a visible
browser window.

## Manual Studio

```text
http://localhost:3000/studio
```

The Studio is for preview, timeline inspection, manual adjustment and review.
It is not the launch surface for every Codex thread.

## Project convention

- New idea: create a new project slug.
- Alternative version: use Agentcut Canvas or `agentcut_create_cut` in the same project.
- Accepted file: copy to `output/<slug>/`.
- Raw originals: keep outside disposable cache paths.
