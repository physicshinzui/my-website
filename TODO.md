# TODO

## Popular Notes
- Add a `Popular Notes` section to `/notes/`.
- Place it above `Recent Notes`.
- Start with a manual flag in note front matter, for example `featured = true`.
- Show up to 3 featured notes.
- If no featured notes exist, hide the section.
- Keep the implementation local to the current Franklin-based note aggregation flow in `utils.jl`.

## Future Option
- Consider replacing the manual `featured = true` flag with analytics-based ranking later.
- If Google Analytics data is used, define a separate build step or data sync step instead of mixing remote fetching into normal local note rendering.
