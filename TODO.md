# TODO

## Pinned Notes Spec

### Goal
- Keep `Recent Notes` as-is and additionally show manually pinned notes on `/notes/`.
- Make pinned notes easy to maintain from each note's front matter.

### UX / Layout
- Add a new section `Pinned Notes` above `Recent Notes` in `notes.md`.
- Show up to 3 pinned notes.
- If no pinned note exists, hide the `Pinned Notes` section.
- `Recent Notes` should remain visible even when pinned notes exist.
- Avoid duplication in the top area: `Recent Notes` excludes already-shown pinned notes.

### Data / Front Matter
- Add `pinned = true` to note front matter to pin a note.
- Optional: `pin_rank = Int` for manual ordering inside pinned notes (smaller value first).
- Backward compatibility: if `featured = true` exists, treat it as pinned.

### Sorting Rules
- `Pinned Notes`: sort by `pin_rank` (ascending), then `date` (descending), then `title` (ascending).
- `Recent Notes`: sort by `date` (descending), then `title` (ascending), after excluding pinned notes.

### Rendering Rules
- `Pinned Notes` card rendering should reuse the current note item renderer.
- `Pinned Notes` keeps date visible and can hide tags (same style as recent list).
- Current `Tags` and `Archive` sections remain unchanged.

### Implementation Scope
- `notes.md`
  Add `{{notes_pinned}}` panel above `{{notes_recent}}`.
- `utils.jl`
  Add pin metadata extraction and `hfun_notes_pinned()`.
  Update `hfun_notes_recent()` to exclude pinned notes.
- `_css/adjust.css`
  Reuse existing list styles or add minimal class styling for pinned list if needed.

### Acceptance Criteria
- A note with `pinned = true` appears in `Pinned Notes`.
- A note with `featured = true` also appears in `Pinned Notes`.
- Maximum 3 pinned notes are shown.
- `Pinned Notes` section is hidden when there is no pinned note.
- `Recent Notes` still shows up to 3 entries and does not duplicate pinned entries.

## Future Option
- Replace manual pinning with analytics-based ranking in a separate build/data step.
- Do not fetch remote analytics data in normal local note rendering.
