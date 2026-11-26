# QA and delivery

## Before export

- Use `agentcut_status` and fix validation/build errors.
- Review representative frames for every changed shot in wide and mobile.
- Check the full contact sheet for rhythm, accidental gaps, missing assets and black frames.
- Use `agentcut_preview_check` for heavy scenes.
- Run the appropriate Agentcut audio analysis and mix critique.
- Proofread all on-screen names, numbers, prices and instructions.

## After render

Verify the actual file:

- container opens and full decode is clean;
- duration matches the plan;
- resolution and aspect ratio match the requested delivery;
- frame rate is as intended;
- expected video/audio streams exist;
- codecs and pixel format are broadly compatible;
- no unintended long black, frozen or silent passages;
- captions and essential text remain readable;
- loudness and peaks meet the target;
- file size fits platform limits;
- SHA-256 is recorded for final acceptance.

If system FFmpeg is unavailable, check Agentcut's managed tools before installing anything:

```text
F:\AI-Video-Studio\tools\agentcut\ffmpeg\<version>\ffmpeg.exe
```

Use the managed tool when present. Installing a duplicate system FFmpeg is not the default.

## Visual verification

A successful render is not visual approval. Inspect:

- start, hook and first readable frame;
- every title/caption card;
- every cut/transition strip that matters;
- product UI or factual evidence;
- final frame and call to action;
- wide and mobile variants.

## Delivery

Report:

- final path;
- duration;
- resolution and frame rate;
- codecs;
- file size;
- checksum;
- loudness/caption results where applicable;
- what remains subjective or unverified.

Copy the accepted deliverable into `output\<slug>\`. Keep the project render and editable project intact.
