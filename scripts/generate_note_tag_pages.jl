using TOML

function slugify(value)
  slug = lowercase(strip(String(value)))
  slug = replace(slug, r"[^a-z0-9]+" => "-")
  slug = replace(slug, r"(^-+|-+$)" => "")
  return isempty(slug) ? "item" : slug
end

function read_frontmatter(path)
  lines = readlines(path)
  if length(lines) >= 3 && strip(lines[1]) == "+++"
    closing = findfirst(i -> strip(lines[i]) == "+++", 2:length(lines))
    if closing !== nothing
      return TOML.parse(join(lines[2:closing-1], "\n"))
    end
  end
  return Dict{String, Any}()
end

function collect_tags(root)
  tags = Set{String}()
  for (dir, _, files) in walkdir(root)
    for file in files
      endswith(file, ".md") || continue
      frontmatter = read_frontmatter(joinpath(dir, file))
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
  return sort(collect(tags))
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

    [Back to Tags](/notes/tags/)

    [Back to Notes](/notes/)

    {{notes_tag_detail $slug}}
    """)
  end
end

root = @__DIR__
project_root = normpath(joinpath(root, ".."))
tags = collect_tags(joinpath(project_root, "notebooks"))
write_tag_pages(tags, joinpath(project_root, "notes", "tags"))
