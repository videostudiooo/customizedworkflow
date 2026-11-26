# Project lifecycle

## Fixed environment

- Workspace: `F:\AI-Video-Studio`
- Editable projects: `projects\<slug>\`
- Approved deliverables: `output\<slug>\`
- Shared reusable assets: `library\`
- Source intake: `assets\`
- Regenerable cache: `cache\`
- Agentcut proxy cache: `.agentcut\proxies\`
- Agentcut transient render area: `.agentcut\render\`

Do not create a second video-studio root.

## Project creation

Use `agentcut_create_project`. Give each new video a distinct semantic slug.

Agentcut creates:

```text
projects\<slug>\
├─ project.json
├─ layers.json
├─ scenes\
├─ assets\
├─ renders\
├─ notes.md
└─ .studio\
```

Keep the returned slug bound to this thread. Pass `project` explicitly to later MCP calls.

## Asset ownership

- Media needed by the edit belongs in the project's `assets\`.
- `assets\` at the workspace root is the intake/original library, not an automatic Agentcut search path.
- Do not put the only copy of original media inside `cache`, proxies, scratch or renders.
- Prefer a project working copy over unsafe directory junctions into the project.
- Keep a source/provenance note for external media.

## Persistence

- `project.json`, `layers.json`, `scenes\`, project `assets\`, `notes.md` and `.studio\` are required to reopen the edit.
- Do not delete `.studio\` as a cache. It contains chat, attachments, canvas and organization state.
- Only `.studio\scratch\` is disposable; Agentcut manages it with age and size limits.

## Delivery

1. Export or locally render into `projects\<slug>\renders\`.
2. Verify the file.
3. Show the user the result and wait for acceptance when the request calls for approval.
4. Copy the accepted file to `output\<slug>\`.
5. Do not move or delete the project render.

## Cleanup boundary

Disposable after confirming no process is using it:

- npm/npx cache
- test browser profiles
- abandoned temporary downloads
- project `.studio\scratch`
- `.agentcut\render`
- proxy cache after checking the original still exists

Never bulk-delete:

- `assets\` originals or unknowns
- `projects\` source, scenes, notes or `.studio` state
- `projects\*\assets`
- unaccepted `projects\*\renders`
- `output\`
- `config\`
- `library\`
- `docs\`
- `reports\`
