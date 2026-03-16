using Dates

function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function hfun_page_last_modified()
  value = locvar("fd_mtime")
  if !(value isa AbstractString)
    return ""
  end
  value = strip(value)
  if isempty(value) || value == "0001-01-01"
    return ""
  end
  return "Last modified: " * value
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

function _format_note_month(note)
  return Dates.format(note.date, dateformat"yyyy-mm")
end

function _archive_path(month)
  return "/notes/archive/$(month)/"
end

function _tag_path(tag)
  return "/notes/tags/$(_slugify(tag))/"
end

function _render_tag_pills(tags; link_tags = true)
  isempty(tags) && return ""
  pills = String[]
  for tag in sort(tags)
    label = "<span class=\"note-tag\">$(tag)</span>"
    if link_tags
      push!(pills, "<a class=\"note-tag-link\" href=\"$(_tag_path(tag))\">$(label)</a>")
    else
      push!(pills, label)
    end
  end
  return "<div class=\"note-tags\">" * join(pills, "") * "</div>"
end

function _archive_counts(notes)
  counts = Dict{String, Int}()
  for note in notes
    month = _format_note_month(note)
    counts[month] = get(counts, month, 0) + 1
  end
  return counts
end

function _notes_by_month(notes)
  note_type = eltype(notes)
  grouped = Dict{String, Vector{note_type}}()
  for note in notes
    month = _format_note_month(note)
    push!(get!(grouped, month, note_type[]), note)
  end
  return grouped
end

function _render_note_item(note)
  meta = "<div class=\"note-meta\">$(_format_note_date(note))</div>"
  summary = note.summary === nothing ? "" : "<p class=\"note-summary\">$(note.summary)</p>"
  tags = _render_tag_pills(note.tags)
  return """
  <article class="note-item">
    <div class="note-item-head">
      <h3 class="note-title"><a href="/$(note.route)">$(note.title)</a></h3>
    </div>
    $(meta)
    $(summary)
    $(tags)
  </article>
  """
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

function _tagged_notes(tag)
  notes = _collect_notes()
  return [note for note in notes if tag in note.tags]
end

function hfun_notes_recent()
  notes = _collect_notes()
  isempty(notes) && return "<p>No notes yet.</p>"
  items = [_render_note_item(note) for note in Iterators.take(notes, 3)]
  return "<div class=\"notes-stack\">" * join(items, "\n") * "</div>"
end


function hfun_notes_tags_overview()
  notes = _collect_notes()
  counts = _note_tag_counts(notes)
  isempty(counts) && return "<p>No tags yet.</p>"
  ordered = sort(collect(keys(counts)); by = tag -> (-counts[tag], lowercase(tag)))
  parts = String[]
  push!(parts, "<div class=\"notes-tag-inline-list\">")
  for tag in ordered
    push!(parts, """
    <a class="notes-inline-tag" href="$(_tag_path(tag))">
      <span class="notes-inline-tag-name">$(tag)</span>
      <span class="notes-inline-tag-count">$(counts[tag])</span>
    </a>
    """)
  end
  push!(parts, "</div>")
  return join(parts, "\n")
end

function hfun_notes_tags_page()
  notes = _collect_notes()
  counts = _note_tag_counts(notes)
  isempty(counts) && return "<p>No tags yet.</p>"
  parts = String[]
  ordered = sort(collect(keys(counts)); by = tag -> (-counts[tag], lowercase(tag)))
  push!(parts, "<div class=\"notes-simple-list\">")
  for tag in ordered
    push!(parts, """
    <div class="notes-simple-item" id="$(_slugify(tag))">
      <a class="notes-simple-link" href="$(_tag_path(tag))">$(tag)</a>
      <span class="notes-simple-count">$(counts[tag])</span>
    </div>
    """)
  end
  push!(parts, "</div>")
  return join(parts, "\n")
end

function hfun_notes_archive_overview()
  notes = _collect_notes()
  counts = _archive_counts(notes)
  isempty(counts) && return "<p>No archive yet.</p>"
  months_by_year = Dict{String, Vector{String}}()
  for month in keys(counts)
    year = first(split(month, "-"))
    push!(get!(months_by_year, year, String[]), month)
  end
  parts = String[]
  for year in sort(collect(keys(months_by_year)); rev = true)
    push!(parts, "<div class=\"archive-year-block\">")
    push!(parts, "<div class=\"archive-year\">$(year)</div>")
    push!(parts, "<div class=\"archive-month-list\">")
    for month in sort(months_by_year[year]; rev = true)
      mm = split(month, "-")[2]
      push!(parts, """
      <div class="archive-month-item">
        <a class="archive-month-link" href="$(_archive_path(month))">
          <span class="archive-month-name">$(mm)</span>
          <span class="archive-month-count">($(counts[month]))</span>
        </a>
      </div>
      """)
    end
    push!(parts, "</div></div>")
  end
  return join(parts, "\n")
end

function hfun_notes_archive_page()
  return hfun_notes_archive_overview()
end

function hfun_notes_archive_detail(vname)
  length(vname) == 1 || return "<p>Archive month is required.</p>"
  month = strip(String(vname[1]))
  notes = _collect_notes()
  grouped = _notes_by_month(notes)
  haskey(grouped, month) || return "<p>No notes found for this month.</p>"
  month_notes = grouped[month]
  return "<div class=\"notes-stack\">" * join([_render_note_item(note) for note in month_notes], "\n") * "</div>"
end

function hfun_notes_tag_detail(vname)
  length(vname) == 1 || return "<p>Tag slug is required.</p>"
  slug = strip(String(vname[1]))
  counts = _note_tag_counts(_collect_notes())
  tag_map = Dict(_slugify(tag) => tag for tag in keys(counts))
  haskey(tag_map, slug) || return "<p>No notes found for this tag.</p>"
  tag = tag_map[slug]
  tagged_notes = _tagged_notes(tag)
  isempty(tagged_notes) && return "<p>No notes found for this tag.</p>"
  return "<div class=\"notes-stack\">" * join([_render_note_item(note) for note in tagged_notes], "\n") * "</div>"
end
