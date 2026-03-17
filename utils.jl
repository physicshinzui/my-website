using Dates

const _BIB_CACHE = Ref{Any}(nothing)
const _FIGURE_CACHE = Dict{String, NamedTuple{(:mtime, :numbers), Tuple{Float64, Dict{String, Int}}}}()
const _TABLE_CACHE = Dict{String, NamedTuple{(:mtime, :numbers), Tuple{Float64, Dict{String, Int}}}}()

function _string_var(value)
  value isa AbstractString || return nothing
  cleaned = strip(String(value))
  return isempty(cleaned) ? nothing : cleaned
end

function _html_escape(value)
  escaped = replace(String(value), "&" => "&amp;")
  escaped = replace(escaped, "\"" => "&quot;")
  escaped = replace(escaped, "<" => "&lt;")
  escaped = replace(escaped, ">" => "&gt;")
  return escaped
end

function _normalize_ws(value)
  return strip(replace(String(value), r"\s+" => " "))
end

function _figure_slug(value)
  slug = strip(String(value))
  slug = replace(slug, r"\s+" => "-")
  slug = replace(slug, r"[^A-Za-z0-9_-]" => "-")
  slug = replace(slug, r"-{2,}" => "-")
  slug = strip(slug, '-')
  return isempty(slug) ? "figure" : slug
end

function _figure_anchor_id(value)
  slug = _figure_slug(value)
  return startswith(slug, "fig-") ? slug : "fig-" * slug
end

function _table_anchor_id(value)
  slug = _figure_slug(value)
  return startswith(slug, "tab-") ? slug : "tab-" * slug
end

function _figure_size_class(value)
  size = lowercase(strip(String(value)))
  size == "small" && return ("md-figure-small", "md-figure-caption-small")
  size == "wide" && return ("md-figure-wide", "md-figure-caption-wide")
  return ("md-figure-medium", "md-figure-caption-medium")
end

function _parse_named_params(params::AbstractVector{<:AbstractString})
  options = Dict{String, String}()
  positional = String[]
  idx = 1
  while idx <= length(params)
    param = params[idx]
    parsed = Base.match(r"^([A-Za-z][A-Za-z0-9_-]*)=(.*)$"s, param)
    if parsed === nothing
      push!(positional, param)
      idx += 1
      continue
    end
    key = lowercase(parsed.captures[1])
    value = strip(parsed.captures[2])
    if isempty(value) && idx < length(params)
      idx += 1
      value = strip(params[idx])
    end
    options[key] = value
    idx += 1
  end
  return positional, options
end

function _figure_id_from_params(params::AbstractVector{<:AbstractString})
  positional, options = _parse_named_params(params)
  if haskey(options, "id")
    return options["id"]
  end
  return isempty(positional) ? "" : positional[1]
end

function _table_id_from_params(params::AbstractVector{<:AbstractString})
  positional, options = _parse_named_params(params)
  if haskey(options, "id")
    return options["id"]
  end
  return isempty(positional) ? "" : positional[1]
end

function _page_figure_numbers(route)
  route === nothing && return Dict{String, Int}()
  path = _route_source_path(route)
  path === nothing && return Dict{String, Int}()
  stamp = mtime(path)
  cached = get(_FIGURE_CACHE, route, nothing)
  if cached !== nothing && cached.mtime == stamp
    return cached.numbers
  end

  text = read(path, String)
  numbers = Dict{String, Int}()
  for capture in eachmatch(r"\{\{\s*figure\s+((?:.|\n)*?)\s*\}\}"s, text)
    params = Franklin.split_hfun_parameters(capture.captures[1])
    isempty(params) && continue
    figure_id = _figure_id_from_params(params)
    isempty(strip(figure_id)) && continue
    anchor = _figure_anchor_id(figure_id)
    haskey(numbers, anchor) && continue
    numbers[anchor] = length(numbers) + 1
  end

  _FIGURE_CACHE[route] = (mtime = stamp, numbers = numbers)
  return numbers
end

function _figure_number(route, value)
  numbers = _page_figure_numbers(route)
  return get(numbers, _figure_anchor_id(value), 0)
end

function _page_table_numbers(route)
  route === nothing && return Dict{String, Int}()
  path = _route_source_path(route)
  path === nothing && return Dict{String, Int}()
  stamp = mtime(path)
  cached = get(_TABLE_CACHE, route, nothing)
  if cached !== nothing && cached.mtime == stamp
    return cached.numbers
  end

  text = read(path, String)
  numbers = Dict{String, Int}()
  for capture in eachmatch(r"\{\{\s*table\s+((?:.|\n)*?)\s*\}\}"s, text)
    params = Franklin.split_hfun_parameters(capture.captures[1])
    isempty(params) && continue
    table_id = _table_id_from_params(params)
    isempty(strip(table_id)) && continue
    anchor = _table_anchor_id(table_id)
    haskey(numbers, anchor) && continue
    numbers[anchor] = length(numbers) + 1
  end

  for capture in eachmatch(r"\\begin\{table\}\{((?:.|\n)*?)\}"s, text)
    params = Franklin.split_hfun_parameters(capture.captures[1])
    isempty(params) && continue
    table_id = _table_id_from_params(params)
    isempty(strip(table_id)) && continue
    anchor = _table_anchor_id(table_id)
    haskey(numbers, anchor) && continue
    numbers[anchor] = length(numbers) + 1
  end

  _TABLE_CACHE[route] = (mtime = stamp, numbers = numbers)
  return numbers
end

function _table_number(route, value)
  numbers = _page_table_numbers(route)
  return get(numbers, _table_anchor_id(value), 0)
end

function _resolve_project_path(value)
  raw = strip(String(value))
  isempty(raw) && return nothing
  cleaned = startswith(raw, "/") ? raw[2:end] : raw
  path = normpath(joinpath(@__DIR__, cleaned))
  startswith(path, normpath(@__DIR__)) || return nothing
  return isfile(path) ? path : nothing
end

function _table_html_from_file(value)
  path = _resolve_project_path(value)
  path === nothing && return nothing
  body = strip(read(path, String))
  isempty(body) && return nothing
  occursin("<table", lowercase(body)) && return body
  return "<table>\n" * body * "\n</table>"
end

function _render_table_html(id, caption, size, table_html)
  route = _current_route()
  number = _table_number(route, id)
  label = number > 0 ? "Table $(number)." : "Table."
  anchor = _table_anchor_id(id)
  _, caption_class = _figure_size_class(size)

  return """
  <figure id="$(_html_escape(anchor))" class="md-table-block">
    $(table_html)
    <figcaption class="md-table-caption $(_html_escape(caption_class))">$(_html_escape(label)) $(_html_escape(caption))</figcaption>
  </figure>
  """
end

function _page_title()
  tag = _string_var(locvar(:fd_tag))
  tag !== nothing && return "Tag: " * tag
  title = _string_var(locvar(:title))
  title !== nothing && return title
  route = _current_route()
  route === nothing && return nothing
  leaf = split(route, "/") |> last
  leaf = replace(leaf, "-" => " ", "_" => " ")
  return titlecase(leaf)
end

function _page_description()
  tag = _string_var(locvar(:fd_tag))
  tag !== nothing && return "Notes and pages tagged " * tag * "."
  for candidate in (
    _string_var(locvar(:description)),
    _string_var(locvar(:summary)),
  )
    candidate !== nothing && return _normalize_ws(candidate)
  end

  route = _current_route()
  route !== nothing || return nothing
  summary = _note_summary(route)
  summary === nothing && return nothing
  return _normalize_ws(summary)
end

function _page_image()
  image = _string_var(locvar(:image))
  image !== nothing && return image
  return _string_var(globvar("website_image"))
end

function _absolute_url(path)
  base = rstrip(String(globvar("website_url")), '/')
  if path isa Nothing
    return base * "/"
  end
  cleaned = strip(String(path))
  startswith(cleaned, "http://") && return cleaned
  startswith(cleaned, "https://") && return cleaned
  cleaned = replace(cleaned, r"/index\.html$" => "/")
  cleaned = replace(cleaned, r"/index/$" => "/")
  cleaned == "index.html" && return base * "/"
  cleaned == "index/" && return base * "/"
  cleaned = "/" * lstrip(cleaned, '/')
  return base * cleaned
end

function _is_homepage()
  fd_url = _string_var(locvar(:fd_url))
  if fd_url !== nothing
    normalized = _absolute_url(fd_url)
    return normalized == rstrip(String(globvar("website_url")), '/') * "/"
  end
  route = _current_route()
  return route === nothing || route == "index" || route == "index.html"
end

function hfun_meta_title()
  site_title = something(_string_var(globvar("website_title")), "Website")
  page_title = _page_title()
  if page_title === nothing || _is_homepage() || page_title == site_title
    return _html_escape(site_title)
  end
  return _html_escape(page_title * " | " * site_title)
end

function hfun_meta_description()
  description = something(
    _page_description(),
    _string_var(globvar("website_descr")),
    "Research notes, publications, and profile of Shinji Iida, a computational biophysicist.",
  )
  return _html_escape(description)
end

function hfun_meta_url()
  fd_url = _string_var(locvar(:fd_url))
  return _html_escape(_absolute_url(fd_url))
end

function hfun_meta_image()
  image = _page_image()
  image === nothing && return ""
  return _html_escape(_absolute_url(image))
end

function hfun_meta_type()
  route = _current_route()
  return route !== nothing && startswith(route, "notebooks/") ? "article" : "website"
end

function hfun_meta_tags()
  title = hfun_meta_title()
  description = hfun_meta_description()
  url = hfun_meta_url()
  image = hfun_meta_image()
  site_name = _html_escape(something(_string_var(globvar("website_title")), "Website"))
  twitter_handle = _string_var(globvar("twitter_handle"))
  lines = [
    "<title>$(title)</title>",
    "<meta name=\"description\" content=\"$(description)\">",
    "<link rel=\"canonical\" href=\"$(url)\">",
    "<meta property=\"og:locale\" content=\"en_US\">",
    "<meta property=\"og:site_name\" content=\"$(site_name)\">",
    "<meta property=\"og:type\" content=\"$(hfun_meta_type())\">",
    "<meta property=\"og:title\" content=\"$(title)\">",
    "<meta property=\"og:description\" content=\"$(description)\">",
    "<meta property=\"og:url\" content=\"$(url)\">",
    "<meta name=\"twitter:card\" content=\"summary_large_image\">",
    "<meta name=\"twitter:title\" content=\"$(title)\">",
    "<meta name=\"twitter:description\" content=\"$(description)\">",
  ]
  if !isempty(image)
    push!(lines, "<meta property=\"og:image\" content=\"$(image)\">")
    push!(lines, "<meta name=\"twitter:image\" content=\"$(image)\">")
  end
  if twitter_handle !== nothing
    escaped_handle = _html_escape(twitter_handle)
    push!(lines, "<meta name=\"twitter:site\" content=\"$(escaped_handle)\">")
  end
  return join(lines, "\n  ")
end

function hfun_google_analytics()
  measurement_id = _string_var(globvar("ga_measurement_id"))
  measurement_id === nothing && return ""
  startswith(measurement_id, "G-") || return ""
  escaped = _html_escape(measurement_id)
  return """
  <script async src="https://www.googletagmanager.com/gtag/js?id=$(escaped)"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '$(escaped)');
  </script>
  """
end

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

function hfun_figure(params::Vector{String})
  positional, options = _parse_named_params(params)

  id = get(options, "id", length(positional) >= 1 ? positional[1] : "")
  src = get(options, "src", length(positional) >= 2 ? positional[2] : "")
  caption = get(options, "caption", length(positional) >= 3 ? positional[3] : "")
  size = get(options, "size", length(positional) >= 4 ? positional[4] : "medium")
  alt = get(options, "alt", length(positional) >= 5 ? positional[5] : caption)

  isempty(strip(id)) && return ""
  isempty(strip(src)) && return ""
  isempty(strip(caption)) && return ""

  route = _current_route()
  number = _figure_number(route, id)
  label = number > 0 ? "Figure $(number)." : "Figure."
  anchor = _figure_anchor_id(id)
  image_class, caption_class = _figure_size_class(size)

  return """
  <figure id="$(_html_escape(anchor))" class="md-figure-block">
    <img class="$(_html_escape(image_class))" src="$(_html_escape(src))" alt="$(_html_escape(alt))">
    <figcaption class="md-figure-caption $(_html_escape(caption_class))">$(_html_escape(label)) $(_html_escape(caption))</figcaption>
  </figure>
  """
end

function hfun_figref(params::Vector{String})
  isempty(params) && return "Figure ?"
  positional, options = _parse_named_params(params)
  id = get(options, "id", isempty(positional) ? "" : positional[1])
  isempty(strip(id)) && return "Figure ?"
  route = _current_route()
  number = _figure_number(route, id)
  anchor = _figure_anchor_id(id)
  label = number > 0 ? "Figure $(number)" : "Figure ?"
  return "<a href=\"#$(_html_escape(anchor))\">$(_html_escape(label))</a>"
end

function hfun_table(params::Vector{String})
  positional, options = _parse_named_params(params)

  id = get(options, "id", length(positional) >= 1 ? positional[1] : "")
  file = get(options, "file", length(positional) >= 2 ? positional[2] : "")
  caption = get(options, "caption", length(positional) >= 3 ? positional[3] : "")
  size = get(options, "size", length(positional) >= 4 ? positional[4] : "medium")

  isempty(strip(id)) && return ""
  isempty(strip(file)) && return ""
  isempty(strip(caption)) && return ""

  table_html = _table_html_from_file(file)
  table_html === nothing && return ""
  return _render_table_html(id, caption, size, table_html)
end

function hfun_tabref(params::Vector{String})
  isempty(params) && return "Table ?"
  positional, options = _parse_named_params(params)
  id = get(options, "id", isempty(positional) ? "" : positional[1])
  isempty(strip(id)) && return "Table ?"
  route = _current_route()
  number = _table_number(route, id)
  anchor = _table_anchor_id(id)
  label = number > 0 ? "Table $(number)" : "Table ?"
  return "<a href=\"#$(_html_escape(anchor))\">$(_html_escape(label))</a>"
end

function env_table(com, _)
  positional, options = _parse_named_params(Franklin.split_hfun_parameters(Franklin.content(com.braces[1])))
  id = get(options, "id", length(positional) >= 1 ? positional[1] : "")
  caption = get(options, "caption", length(positional) >= 2 ? positional[2] : "")
  size = get(options, "size", length(positional) >= 3 ? positional[3] : "medium")

  isempty(strip(id)) && return ""
  isempty(strip(caption)) && return ""

  body = strip(Franklin.content(com))
  isempty(body) && return ""
  table_html = fd2html(body, internal=true)
  return "~~~\n" * _render_table_html(id, caption, size, table_html) * "\n~~~"
end

function _current_route()
  value = locvar("fd_rpath")
  value isa AbstractString || return nothing
  route = strip(value)
  isempty(route) && return nothing
  route = replace(route, "\\" => "/")
  route = replace(route, r"^/+" => "")
  route = replace(route, r"\.md$" => "")
  return isempty(route) ? nothing : route
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

function _bibliography_paths()
  return (
    joinpath(@__DIR__, "references.paperpile.bib"),
    joinpath(@__DIR__, "references.local.bib"),
  )
end

function _route_source_path(route)
  route === nothing && return nothing
  for candidate in (
    joinpath(@__DIR__, route * ".md"),
    joinpath(@__DIR__, route, "index.md"),
  )
    isfile(candidate) && return candidate
  end
  return nothing
end

function _strip_outer_braces(value)
  text = strip(String(value))
  while startswith(text, "{") && endswith(text, "}") && length(text) >= 2
    depth = 0
    balanced = true
    for (idx, ch) in enumerate(text)
      if ch == '{'
        depth += 1
      elseif ch == '}'
        depth -= 1
        if depth == 0 && idx != lastindex(text)
          balanced = false
          break
        elseif depth < 0
          balanced = false
          break
        end
      end
    end
    balanced || break
    text = strip(text[2:end-1])
  end
  return text
end

function _strip_bibtex_tex(value)
  text = _strip_outer_braces(value)
  text = replace(text, r"\\&" => "&")
  text = replace(text, r"\\_" => "_")
  text = replace(text, r"\\%" => "%")
  text = replace(text, r"\\textit\{([^}]*)\}" => s"\1")
  text = replace(text, r"\\textbf\{([^}]*)\}" => s"\1")
  text = replace(text, r"[{}]" => "")
  text = replace(text, r"\s+" => " ")
  return strip(text)
end

function _read_bib_value(text, start_idx)
  idx = start_idx
  while idx <= lastindex(text) && isspace(text[idx])
    idx = nextind(text, idx)
  end
  idx > lastindex(text) && return "", idx

  ch = text[idx]
  if ch == '{'
    depth = 1
    value_start = nextind(text, idx)
    idx = value_start
    while idx <= lastindex(text)
      current = text[idx]
      if current == '{'
        depth += 1
      elseif current == '}'
        depth -= 1
        if depth == 0
          return text[value_start:prevind(text, idx)], nextind(text, idx)
        end
      end
      idx = nextind(text, idx)
    end
    return text[value_start:end], lastindex(text) + 1
  elseif ch == '"'
    value_start = nextind(text, idx)
    idx = value_start
    escaped = false
    while idx <= lastindex(text)
      current = text[idx]
      if current == '"' && !escaped
        return text[value_start:prevind(text, idx)], nextind(text, idx)
      end
      escaped = current == '\\' && !escaped
      current == '\\' || (escaped = false)
      idx = nextind(text, idx)
    end
    return text[value_start:end], lastindex(text) + 1
  else
    value_start = idx
    while idx <= lastindex(text) && !(text[idx] in (',', '\n', '\r'))
      idx = nextind(text, idx)
    end
    return strip(text[value_start:prevind(text, idx)]), idx
  end
end

function _parse_bibtex_entry(body)
  start_match = match(r"^@([A-Za-z]+)\s*[{(]\s*([^,]+)\s*,([\s\S]*)[})]\s*$", strip(body))
  start_match === nothing && return nothing

  entry_type = lowercase(strip(start_match.captures[1]))
  entry_key = strip(start_match.captures[2])
  fields_text = start_match.captures[3]

  fields = Dict{String,String}()
  idx = firstindex(fields_text)
  while idx <= lastindex(fields_text)
    while idx <= lastindex(fields_text) && (isspace(fields_text[idx]) || fields_text[idx] == ',')
      idx = nextind(fields_text, idx)
    end
    idx > lastindex(fields_text) && break

    eq_pos = findnext(==('='), fields_text, idx)
    eq_pos === nothing && break
    name = lowercase(strip(fields_text[idx:prevind(fields_text, eq_pos)]))
    value, next_idx = _read_bib_value(fields_text, nextind(fields_text, eq_pos))
    fields[name] = _strip_bibtex_tex(value)
    idx = next_idx
  end

  return (
    key = entry_key,
    entry_type = entry_type,
    fields = fields,
  )
end

function _parse_bibtex_file(path)
  isfile(path) || return Dict{String,NamedTuple}()
  text = read(path, String)
  entries = Dict{String,NamedTuple}()
  idx = firstindex(text)

  while true
    start_pos = findnext(==('@'), text, idx)
    start_pos === nothing && break
    open_pos = findnext(ch -> ch == '{' || ch == '(', text, start_pos)
    open_pos === nothing && break
    open_ch = text[open_pos]
    close_ch = open_ch == '{' ? '}' : ')'
    depth = 1
    pos = nextind(text, open_pos)
    while pos <= lastindex(text)
      current = text[pos]
      if current == open_ch
        depth += 1
      elseif current == close_ch
        depth -= 1
        if depth == 0
          entry_text = text[start_pos:pos]
          parsed = _parse_bibtex_entry(entry_text)
          if parsed !== nothing
            entries[parsed.key] = parsed
          end
          idx = nextind(text, pos)
          break
        end
      end
      pos = nextind(text, pos)
    end
    pos > lastindex(text) && break
  end

  return entries
end

function _bib_entries()
  paths = _bibliography_paths()
  stamps = Tuple(isfile(path) ? mtime(path) : -1.0 for path in paths)
  cached = _BIB_CACHE[]
  if cached !== nothing && cached.paths == paths && cached.stamps == stamps
    return cached.entries
  end
  entries = Dict{String,NamedTuple}()
  for path in paths
    merge!(entries, _parse_bibtex_file(path))
  end
  _BIB_CACHE[] = (paths = paths, stamps = stamps, entries = entries)
  return entries
end

function _split_citation_keys(value)
  parts = split(String(value), ',')
  return [strip(part) for part in parts if !isempty(strip(part))]
end

function _page_citation_order(route)
  source = _route_source_path(route)
  source === nothing && return String[]
  text = read(source, String)
  ordered = String[]
  seen = Set{String}()
  for match in eachmatch(r"\\cite\{([^}]*)\}", text)
    for key in _split_citation_keys(match.captures[1])
      key in seen && continue
      push!(ordered, key)
      push!(seen, key)
    end
  end
  for match in eachmatch(r"\{\{cite\s+([^}]*)\}\}", text)
    for key in split(strip(match.captures[1]))
      cleaned = strip(key, [',', ' '])
      isempty(cleaned) && continue
      cleaned in seen && continue
      push!(ordered, cleaned)
      push!(seen, cleaned)
    end
  end
  return ordered
end

function _citation_number_map(route)
  ordered = _page_citation_order(route)
  return Dict(key => idx for (idx, key) in enumerate(ordered))
end

function _authors_text(entry)
  authors = get(entry.fields, "author", "")
  isempty(authors) && return ""
  names = [_normalize_ws(part) for part in split(authors, " and ") if !isempty(strip(part))]
  return join(names, ", ")
end

function _journal_text(entry)
  for field in ("journal", "booktitle", "publisher")
    value = get(entry.fields, field, "")
    isempty(value) || return value
  end
  return ""
end

function _entry_year(entry)
  year = tryparse(Int, get(entry.fields, "year", ""))
  return something(year, 0)
end

function _entry_title(entry)
  return get(entry.fields, "title", entry.key)
end

function _entry_href(entry)
  doi = get(entry.fields, "doi", "")
  isempty(doi) || return "https://doi.org/" * doi
  return get(entry.fields, "url", "")
end

function _render_reference_html(entry; index = nothing, anchor_prefix = "ref")
  parts = String[]

  authors = _authors_text(entry)
  isempty(authors) || push!(parts, _html_escape(authors) * ".")

  title = _entry_title(entry)
  href = _entry_href(entry)
  if isempty(href)
    push!(parts, "\"" * _html_escape(title) * ".\"")
  else
    push!(parts, "<a href=\"" * _html_escape(href) * "\">\"" * _html_escape(title) * ".\"</a>")
  end

  journal = _journal_text(entry)
  isempty(journal) || push!(parts, "<em>" * _html_escape(journal) * "</em>")

  year = get(entry.fields, "year", "")
  volume = get(entry.fields, "volume", "")
  number = get(entry.fields, "number", "")
  pages = get(entry.fields, "pages", "")
  detail_parts = String[]
  isempty(year) || push!(detail_parts, _html_escape(year))
  isempty(volume) || push!(detail_parts, "<strong>" * _html_escape(volume) * "</strong>")
  isempty(number) || push!(detail_parts, "(" * _html_escape(number) * ")")
  isempty(pages) || push!(detail_parts, _html_escape(pages))
  isempty(detail_parts) || push!(parts, join(detail_parts, ", "))

  doi = get(entry.fields, "doi", "")
  isempty(doi) || push!(parts, "DOI: <a href=\"" * _html_escape("https://doi.org/" * doi) * "\">" * _html_escape(doi) * "</a>")

  body = join(parts, " ")
  if index === nothing
    return "<li id=\"" * anchor_prefix * "-" * _html_escape(entry.key) * "\">" * body * "</li>"
  end
  return "<li id=\"" * anchor_prefix * "-" * _html_escape(entry.key) * "\">" * body * "</li>"
end

function _render_citation_html(keys)
  keys = [String(strip(key)) for key in keys if !isempty(strip(String(key)))]
  isempty(keys) && return "[?]"

  route = _current_route()
  number_map = _citation_number_map(route)
  entries = _bib_entries()
  ordered = _page_citation_order(route)

  for key in keys
    if !haskey(number_map, key)
      push!(ordered, key)
      number_map[key] = length(ordered)
    end
  end

  rendered = String[]
  for key in keys
    number = get(number_map, key, 0)
    label = number > 0 ? string(number) : "?"
    title = haskey(entries, key) ? _entry_title(entries[key]) : "Missing reference: " * key
    push!(rendered, "<a href=\"#ref-" * _html_escape(key) * "\" title=\"" * _html_escape(title) * "\">" * label * "</a>")
  end

  return "<span class=\"bibref\">[" * join(rendered, ", ") * "]</span>"
end

function lx_cite(com, _)
  isempty(com.braces) && return "[?]"
  keys = _split_citation_keys(Franklin.content(com.braces[1]))
  return _render_citation_html(keys)
end

function lx_rcite(com, _)
  isempty(com.braces) && return "[?]"
  keys = _split_citation_keys(Franklin.content(com.braces[1]))
  return _render_citation_html(keys)
end

function hfun_cite(params::Vector{String})
  isempty(params) && return "[?]"
  keys = [strip(param) for param in params if !isempty(strip(param))]
  return _render_citation_html(keys)
end

function hfun_references()
  route = _current_route()
  ordered_keys = _page_citation_order(route)
  entries = _bib_entries()
  items = String[]

  for key in ordered_keys
    haskey(entries, key) || continue
    push!(items, _render_reference_html(entries[key]))
  end

  isempty(items) && return ""
  return "<ol class=\"references-list\">\n" * join(items, "\n") * "\n</ol>"
end

function hfun_publications_bibliography()
  entries = collect(values(_bib_entries()))
  sort!(entries; by = entry -> (-_entry_year(entry), lowercase(_authors_text(entry)), lowercase(_entry_title(entry))))
  items = [_render_reference_html(entry) for entry in entries]
  isempty(items) && return ""
  return "<ol class=\"references-list\">\n" * join(items, "\n") * "\n</ol>"
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

function hfun_note_page_date_meta()
  route = _current_route()
  route === nothing && return ""
  startswith(route, "notebooks/") || return ""
  path = joinpath(@__DIR__, route * ".md")
  isfile(path) || return ""
  date = _note_date(route, path)
  tags = _note_tags(route)
  tags_json = "[" * join(["\"" * replace(tag, "\"" => "\\\"") * "\"" for tag in tags], ",") * "]"
  return """
  <meta name="note-page-date" content="$(Dates.format(date, dateformat"yyyy-mm-dd"))">
  <script id="note-page-tags" type="application/json">$(tags_json)</script>
  """
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

function _render_note_item(note; show_tags = true, show_date = false)
  meta = show_date ? "<div class=\"note-meta\">$(_format_note_date(note))</div>" : ""
  summary = note.summary === nothing ? "" : "<p class=\"note-summary\">$(note.summary)</p>"
  tags = show_tags ? _render_tag_pills(note.tags) : ""
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
  items = [_render_note_item(note; show_tags = false, show_date = true) for note in Iterators.take(notes, 3)]
  return "<div class=\"notes-stack notes-recent-list\">" * join(items, "\n") * "</div>"
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
