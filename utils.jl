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
    return date
  elseif date isa DateTime
    return Date(date)
  elseif date isa AbstractString
    try
      return Date(date)
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

function hfun_notes_index()
  notes = _collect_notes()
  isempty(notes) && return "<p>No notes yet.</p>"

  by_genre = Dict{String, Vector{typeof(notes[1])}}()
  for note in notes
    push!(get!(by_genre, note.genre, typeof(notes[1])[]), note)
  end

  parts = String[]
  for genre in sort(collect(keys(by_genre)))
    push!(parts, "<h2>$(genre)</h2>")
    push!(parts, "<ul>")
    for note in by_genre[genre]
      push!(parts, "<li><a href=\"/$(note.route)\">$(note.title)</a>")
      details = String[]
      if note.summary !== nothing
        push!(details, note.summary)
      end
      if !isempty(note.tags)
        push!(details, "Tags: " * join(note.tags, ", "))
      end
      if !isempty(details)
        push!(parts, "<br><small>" * join(details, " | ") * "</small>")
      end
      push!(parts, "</li>")
    end
    push!(parts, "</ul>")
  end
  return join(parts, "\n")
end
