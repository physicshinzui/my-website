using Dates

function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

function _note_paths()
  root = joinpath(@__DIR__, "notebooks")
  paths = String[]
  for (dir, _, files) in walkdir(root)
    for file in files
      endswith(file, ".md") || continue
      push!(paths, joinpath(dir, file))
    end
  end
  sort!(paths)
  return paths
end

function _note_route(path)
  rel = relpath(path, @__DIR__)
  return replace(rel, r"\.md$" => "")
end

function _note_title(path, route)
  title = pagevar(route, "title")
  if title isa AbstractString && !isempty(strip(title))
    return strip(title)
  end

  for line in eachline(path)
    startswith(line, "# ") || continue
    return strip(line[3:end])
  end
  return basename(route)
end

function _note_summary(route)
  summary = pagevar(route, "summary")
  if summary isa AbstractString
    summary = strip(summary)
    isempty(summary) || return summary
  end
  return nothing
end

function _note_genre(route)
  genre = pagevar(route, "genre")
  if genre isa AbstractString
    genre = strip(genre)
    isempty(genre) || return genre
  end
  return "Other"
end

function _note_tags(route)
  tags = pagevar(route, "tags")
  if tags isa AbstractVector
    return [string(tag) for tag in tags if !isempty(strip(string(tag)))]
  elseif tags isa AbstractString
    cleaned = strip(tags)
    return isempty(cleaned) ? String[] : [cleaned]
  end
  return String[]
end

function _note_date(route, path)
  date = pagevar(route, "date")
  if date isa Date
    return year(date) == 1 ? Date(unix2datetime(mtime(path))) : date
  elseif date isa DateTime
    parsed = Date(date)
    return year(parsed) == 1 ? Date(unix2datetime(mtime(path))) : parsed
  elseif date isa AbstractString
    try
      parsed = Date(date)
      return year(parsed) == 1 ? Date(unix2datetime(mtime(path))) : parsed
    catch
    end
  end
  return Date(unix2datetime(mtime(path)))
end

function _collect_notes()
  notes = NamedTuple[]
  for path in _note_paths()
    route = _note_route(path)
    push!(notes, (
      title = _note_title(path, route),
      route = route,
      genre = _note_genre(route),
      summary = _note_summary(route),
      tags = _note_tags(route),
      date = _note_date(route, path),
    ))
  end
  return sort(notes; by = note -> (-Dates.value(note.date), lowercase(note.title)))
end

function _slugify(value)
  slug = lowercase(strip(String(value)))
  slug = replace(slug, r"[^a-z0-9]+" => "-")
  slug = replace(slug, r"(^-+|-+$)" => "")
  return isempty(slug) ? "item" : slug
end

function _format_note_date(note)
  return Dates.format(note.date, dateformat"yyyy-mm-dd")
end

function _render_tag_pills(tags; base_url = nothing)
  isempty(tags) && return ""
  pills = String[]
  for tag in sort(tags)
    label = "<span class=\"note-tag\">$(tag)</span>"
    if base_url === nothing
      push!(pills, label)
    else
      push!(pills, "<a class=\"note-tag-link\" href=\"$(base_url)#$(_slugify(tag))\">$(label)</a>")
    end
  end
  return "<div class=\"note-tags\">" * join(pills, "") * "</div>"
end

function _render_note_item(note)
  meta = "<div class=\"note-meta\">$(_format_note_date(note)) <span class=\"note-meta-sep\">|</span> $(note.genre)</div>"
  summary = note.summary === nothing ? "" : "<p class=\"note-summary\">$(note.summary)</p>"
  tags = _render_tag_pills(note.tags)
  return """
  <article class="note-item">
    <h3 class="note-title"><a href="/$(note.route)">$(note.title)</a></h3>
    $(meta)
    $(summary)
    $(tags)
  </article>
  """
end

function _notes_by_genre(notes)
  grouped = Dict{String, Vector{typeof(notes[1])}}()
  for note in notes
    push!(get!(grouped, note.genre, typeof(notes[1])[]), note)
  end
  return grouped
end

function _note_tag_counts(notes)
  counts = Dict{String, Int}()
  for note in notes
    for tag in note.tags
      counts[tag] = get(counts, tag, 0) + 1
    end
  end
  return counts
end

function hfun_notes_recent()
  notes = _collect_notes()
  isempty(notes) && return "<p>No notes yet.</p>"
  items = [_render_note_item(note) for note in Iterators.take(notes, 6)]
  return "<div class=\"notes-stack\">" * join(items, "\n") * "</div>"
end

function hfun_notes_genres_overview()
  notes = _collect_notes()
  isempty(notes) && return "<p>No genres yet.</p>"
  grouped = _notes_by_genre(notes)
  parts = String[]
  push!(parts, "<div class=\"notes-grid\">")
  for genre in sort(collect(keys(grouped)))
    genre_notes = grouped[genre]
    preview = ["<li><a href=\"/$(note.route)\">$(note.title)</a></li>" for note in Iterators.take(genre_notes, 3)]
    push!(parts, """
    <section class="note-panel">
      <h3 id="$(_slugify(genre))" class="note-panel-title"><a href="/notes/genres/#$(_slugify(genre))">$(genre)</a></h3>
      <p class="note-panel-meta">$(length(genre_notes)) notes</p>
      <ul class="note-mini-list">$(join(preview, ""))</ul>
    </section>
    """)
  end
  push!(parts, "</div>")
  return join(parts, "\n")
end

function hfun_notes_tags_overview()
  notes = _collect_notes()
  counts = _note_tag_counts(notes)
  isempty(counts) && return "<p>No tags yet.</p>"
  ordered = sort(collect(keys(counts)); by = tag -> (-counts[tag], lowercase(tag)))
  parts = String[]
  push!(parts, "<div class=\"notes-tag-cloud\">")
  for tag in ordered
    push!(parts, """
    <a class="note-tag-link" href="/notes/tags/#$(_slugify(tag))">
      <span class="note-tag">$(tag)</span>
      <span class="note-tag-count">$(counts[tag])</span>
    </a>
    """)
  end
  push!(parts, "</div>")
  return join(parts, "\n")
end

function hfun_notes_genres_page()
  notes = _collect_notes()
  isempty(notes) && return "<p>No genres yet.</p>"
  grouped = _notes_by_genre(notes)
  parts = String[]
  for genre in sort(collect(keys(grouped)))
    genre_notes = grouped[genre]
    push!(parts, """
    <section class="notes-section-block">
      <h2 id="$(_slugify(genre))">$(genre)</h2>
      <p class="note-panel-meta">$(length(genre_notes)) notes</p>
      <div class="notes-stack">$(join([_render_note_item(note) for note in genre_notes], "\n"))</div>
    </section>
    """)
  end
  return join(parts, "\n")
end

function hfun_notes_tags_page()
  notes = _collect_notes()
  counts = _note_tag_counts(notes)
  isempty(counts) && return "<p>No tags yet.</p>"
  parts = String[]
  ordered = sort(collect(keys(counts)); by = tag -> (-counts[tag], lowercase(tag)))
  for tag in ordered
    tagged_notes = [note for note in notes if tag in note.tags]
    push!(parts, """
    <section class="notes-section-block">
      <h2 id="$(_slugify(tag))">$(tag)</h2>
      <p class="note-panel-meta">$(counts[tag]) notes</p>
      <div class="notes-stack">$(join([_render_note_item(note) for note in tagged_notes], "\n"))</div>
    </section>
    """)
  end
  return join(parts, "\n")
end
