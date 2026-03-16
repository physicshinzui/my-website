using TOML
using Dates

function slugify(value)
  slug = lowercase(strip(String(value)))
  slug = replace(slug, r"[^a-z0-9]+" => "-")
  slug = replace(slug, r"(^-+|-+$)" => "")
  return isempty(slug) ? "item" : slug
end

function read_frontmatter(path)
  lines = readlines(path)
  if length(lines) >= 3 && strip(lines[1]) == "+++"
    closing = nothing
    for i in 2:length(lines)
      if strip(lines[i]) == "+++"
        closing = i
        break
      end
    end
    if closing !== nothing
      frontmatter_lines = String[]
      for line in lines[2:closing-1]
        match_result = match(
          r"^\s*date\s*=\s*Date\(\s*(\d{4})\s*,\s*(\d{1,2})\s*,\s*(\d{1,2})\s*\)\s*$",
          line,
        )
        if match_result === nothing
          push!(frontmatter_lines, line)
        else
          year = match_result.captures[1]
          month = match_result.captures[2]
          day = match_result.captures[3]
          push!(frontmatter_lines, "date = \"$(year)-$(month)-$(day)\"")
        end
      end
      content = join(frontmatter_lines, "\n")
      return TOML.parse(content)
    end
  end
  return Dict{String, Any}()
end

function parse_frontmatter_date(value)
  value isa Date && return value
  value isa DateTime && return Date(value)
  raw = strip(String(value))
  match_result = match(r"^(\d{4})-(\d{1,2})-(\d{1,2})$", raw)
  match_result === nothing && return nothing
  year = parse(Int, match_result.captures[1])
  month = parse(Int, match_result.captures[2])
  day = parse(Int, match_result.captures[3])
  return Date(year, month, day)
end

function collect_tags(root)
  tags = Set{String}()
  months = Set{String}()
  for (dir, _, files) in walkdir(root)
    for file in files
      endswith(file, ".md") || continue
      path = joinpath(dir, file)
      frontmatter = read_frontmatter(path)
      month = Dates.format(Date(unix2datetime(mtime(path))), dateformat"yyyy-mm")
      if haskey(frontmatter, "date")
        parsed = try
          parse_frontmatter_date(frontmatter["date"])
        catch
          nothing
        end
        if parsed !== nothing && year(parsed) != 1
          month = Dates.format(parsed, dateformat"yyyy-mm")
        end
      end
      push!(months, month)
      values = get(frontmatter, "tags", Any[])
      if values isa AbstractVector
        for value in values
          tag = strip(String(value))
          isempty(tag) || push!(tags, tag)
        end
      elseif values isa AbstractString
        tag = strip(values)
        isempty(tag) || push!(tags, tag)
      end
    end
  end
  return sort(collect(tags)), sort(collect(months))
end

function write_tag_pages(tags, outdir)
  mkpath(outdir)
  for name in readdir(outdir)
    endswith(name, ".md") || continue
    rm(joinpath(outdir, name); force = true)
  end

  for tag in tags
    slug = slugify(tag)
    path = joinpath(outdir, "$slug.md")
    write(path, """
    +++
    title = "Tag: $tag"
    +++

    # Tag: $tag

    @@notes-back-links
    [Back to Tags](/notes/tags/)
    [Back to Notes](/notes/)
    @@

    {{notes_tag_detail $slug}}
    """)
  end
end

function write_archive_pages(months, outdir)
  mkpath(outdir)
  for name in readdir(outdir)
    endswith(name, ".md") || continue
    rm(joinpath(outdir, name); force = true)
  end

  write(joinpath(dirname(outdir), "archive.md"), """
  # Archive

  {{notes_archive_page}}
  """)

  for month in months
    path = joinpath(outdir, "$month.md")
    write(path, """
    +++
    title = "Archive: $month"
    +++

    # Archive: $month

    @@notes-back-links
    [Back to Archive](/notes/archive/)
    [Back to Notes](/notes/)
    @@

    {{notes_archive_detail $month}}
    """)
  end
end

root = @__DIR__
project_root = normpath(joinpath(root, ".."))
tags, months = collect_tags(joinpath(project_root, "notebooks"))
write_tag_pages(tags, joinpath(project_root, "notes", "tags"))
write_archive_pages(months, joinpath(project_root, "notes", "archive"))
