using Dates

function slugify(value)
  slug = lowercase(strip(String(value)))
  slug = replace(slug, r"[^a-z0-9]+" => "-")
  slug = replace(slug, r"(^-+|-+$)" => "")
  return isempty(slug) ? "note" : slug
end

function frontmatter_date(date::Date)
  return "Date($(year(date)), $(month(date)), $(day(date)))"
end

function normalize_relpath(path)
  cleaned = replace(strip(String(path)), "\\" => "/")
  cleaned = replace(cleaned, r"^/+" => "")
  cleaned = replace(cleaned, r"/+" => "/")
  return cleaned
end

function note_template(title; date = today())
  return """
+++
title = "$(title)"
tags = []
summary = ""
date = $(frontmatter_date(date))
+++

# $(title)

"""
end

function resolve_new_note_path(base_dir, title, rel_dir = "")
  rel_dir = normalize_relpath(rel_dir)
  slug = slugify(title) * ".md"
  return isempty(rel_dir) ? joinpath(base_dir, slug) : joinpath(base_dir, rel_dir, slug)
end

function create_note(base_dir, title, rel_dir = "")
  path = resolve_new_note_path(base_dir, title, rel_dir)
  isfile(path) && error("File already exists: $(path)")
  mkpath(dirname(path))
  write(path, note_template(title))
  return path
end

function resolve_draft_path(drafts_dir, ref)
  ref = normalize_relpath(ref)
  candidate = endswith(ref, ".md") ? ref : ref * ".md"

  direct = joinpath(drafts_dir, candidate)
  isfile(direct) && return direct

  basename_candidate = basename(candidate)
  matches = String[]
  for (dir, _, files) in walkdir(drafts_dir)
    for file in files
      file == basename_candidate || continue
      push!(matches, joinpath(dir, file))
    end
  end

  isempty(matches) && error("Draft not found: $(ref)")
  length(matches) == 1 || error("Multiple drafts matched $(ref): " * join(matches, ", "))
  return only(matches)
end

function publish_note(drafts_dir, notebooks_dir, ref, rel_dir = "")
  source = resolve_draft_path(drafts_dir, ref)
  filename = basename(source)
  rel_dir = normalize_relpath(rel_dir)
  destination = isempty(rel_dir) ? joinpath(notebooks_dir, filename) : joinpath(notebooks_dir, rel_dir, filename)
  isfile(destination) && error("Destination already exists: $(destination)")
  mkpath(dirname(destination))
  mv(source, destination)
  return source, destination
end
