include("scripts/generate_note_tag_pages.jl")

using Franklin
using Logging

function _notebooks_signature(root = joinpath(@__DIR__, "notebooks"))
  entries = String[]
  for (dir, _, files) in walkdir(root)
    for file in files
      endswith(file, ".md") || continue
      path = joinpath(dir, file)
      st = stat(path)
      push!(entries, string(relpath(path, root), "|", st.size, "|", st.mtime))
    end
  end
  sort!(entries)
  return hash(join(entries, "\n"))
end

function _start_note_tag_sync(; interval_sec = 0.8)
  last_sig = Ref{UInt}(0)

  function sync_once(; force = false)
    sig = _notebooks_signature()
    if force || sig != last_sig[]
      generate_note_tag_pages(@__DIR__)
      last_sig[] = sig
    end
  end

  sync_once(force = true)

  @async begin
    while true
      try
        sync_once()
      catch err
        @warn "Failed to regenerate note tag pages" exception = (err, catch_backtrace())
      end
      sleep(interval_sec)
    end
  end
end

_start_note_tag_sync()
serve()
