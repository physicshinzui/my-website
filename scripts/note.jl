include("note_tools.jl")

using Downloads
using Sockets

const DEFAULT_PORT = 8000
const DEFAULT_PREVIEW_PATH = "/notes/"

function usage()
  println(
    """
Usage:
  julia --project=. scripts/note.jl "Title" [--subdir DIR] [--draft] [--editor NAME]
  julia --project=. scripts/note.jl --publish DRAFT_PATH_OR_NAME [--subdir DIR]
  julia --project=. scripts/note.jl --help

Options:
  --draft          Create a draft in drafts/ instead of notebooks/
  --publish REF    Publish draft REF from drafts/ into notebooks/
  --subdir DIR     Optional subdirectory under drafts/ or notebooks/
  --editor NAME    Force editor (cursor|code|typora|textedit|nano|vim|nvim|auto)
  --port N         Preview port (default: 8000)
  --no-open        Do not open browser
  --no-editor      Do not open editor
"""
  )
end

function parse_args(args)
  isempty(args) && return (help = true,)
  "--help" in args && return (help = true,)
  "-h" in args && return (help = true,)

  title = nothing
  publish_ref = nothing
  subdir = ""
  draft_mode = false
  editor_name = "auto"
  open_browser = true
  open_editor = true
  port = DEFAULT_PORT

  i = 1
  while i <= length(args)
    arg = args[i]
    if arg == "--draft"
      draft_mode = true
      i += 1
    elseif arg == "--publish"
      i + 1 <= length(args) || error("Missing value for --publish")
      publish_ref = strip(args[i + 1])
      i += 2
    elseif arg == "--subdir"
      i + 1 <= length(args) || error("Missing value for --subdir")
      subdir = args[i + 1]
      i += 2
    elseif arg == "--editor"
      i + 1 <= length(args) || error("Missing value for --editor")
      editor_name = lowercase(strip(args[i + 1]))
      i += 2
    elseif arg == "--port"
      i + 1 <= length(args) || error("Missing value for --port")
      port = parse(Int, args[i + 1])
      i += 2
    elseif arg == "--no-open"
      open_browser = false
      i += 1
    elseif arg == "--no-editor"
      open_editor = false
      i += 1
    elseif startswith(arg, "--")
      error("Unknown option: $(arg)")
    else
      isnothing(title) || error("Only one title is allowed")
      title = strip(arg)
      i += 1
    end
  end

  if !isnothing(publish_ref)
    isempty(strip(String(publish_ref))) && error("--publish requires a non-empty value")
    isnothing(title) || error("Do not pass a title with --publish")
  else
    isnothing(title) && error("Title is required unless --publish is used")
    isempty(strip(String(title))) && error("Title cannot be empty")
  end

  return (
    help = false,
    title = title,
    publish_ref = publish_ref,
    subdir = subdir,
    draft_mode = draft_mode,
    editor_name = editor_name,
    open_browser = open_browser,
    open_editor = open_editor,
    port = port,
  )
end

function can_connect(host::AbstractString, port::Integer; timeout_sec = 0.3)
  try
    sock = connect(host, port)
    close(sock)
    return true
  catch
    return false
  end
end

function pick_open_command()
  Sys.isapple() && return `open`
  Sys.islinux() && return `xdg-open`
  Sys.iswindows() && return `cmd /c start`
  return nothing
end

function open_in_browser(url)
  opener = pick_open_command()
  isnothing(opener) && return false
  try
    run(`$opener $url`; wait = false)
    return true
  catch
    return false
  end
end

function editor_cmd_from_name(name, path)
  if name == "cursor"
    return `cursor $path`
  elseif name == "code"
    return `code $path`
  elseif name == "typora"
    return `typora $path`
  elseif name == "textedit"
    return Sys.isapple() ? `open -a TextEdit $path` : `gedit $path`
  elseif name == "nano"
    return `nano $path`
  elseif name == "vim"
    return `vim $path`
  elseif name == "nvim"
    return `nvim $path`
  elseif name == "auto"
    return nothing
  else
    error("Unsupported editor: $(name)")
  end
end

function open_in_editor(path, editor_name)
  forced = editor_cmd_from_name(editor_name, path)
  if !isnothing(forced)
    run(forced; wait = false)
    return editor_name
  end

  note_editor = get(ENV, "NOTE_EDITOR", "")
  if !isempty(note_editor)
    run(`$note_editor $path`; wait = false)
    return "NOTE_EDITOR=" * note_editor
  end

  editor = get(ENV, "EDITOR", "")
  if !isempty(editor)
    run(`$editor $path`; wait = false)
    return "EDITOR=" * editor
  end

  if Sys.isapple()
    run(`open -a TextEdit $path`; wait = false)
    return "TextEdit"
  end
  if Sys.islinux()
    run(`xdg-open $path`; wait = false)
    return "xdg-open"
  end
  if Sys.iswindows()
    run(`cmd /c start "" $path`; wait = false)
    return "start"
  end
  error("No editor found. Set NOTE_EDITOR or EDITOR, or pass --editor.")
end

function ensure_dev_server(project_root, port::Int)
  log_path = joinpath(project_root, "devserver.log")
  if can_connect("127.0.0.1", port)
    return (started = false, running = true, log_path = log_path)
  end

  try
    log_io = open(log_path, "a")
    cmd = Cmd(`julia --project=. dev.jl`; dir = project_root)
    run(pipeline(cmd; stdout = log_io, stderr = log_io); wait = false)
    close(log_io)
  catch
    return (started = true, running = false, log_path = log_path)
  end

  # Wait briefly for the server to become reachable.
  for _ in 1:40
    sleep(0.25)
    can_connect("127.0.0.1", port) && return (started = true, running = true, log_path = log_path)
  end
  return (started = true, running = false, log_path = log_path)
end

function rel_or_abs(path, project_root)
  try
    return relpath(path, project_root)
  catch
    return path
  end
end

function note_url_for(path, project_root, port)
  rel = replace(relpath(path, project_root), "\\" => "/")
  stem = replace(rel, r"\.md$" => "")
  return "http://localhost:$(port)/" * stem * "/"
end

function url_available(url::AbstractString)
  tmp, io = mktemp()
  close(io)
  try
    Downloads.download(url, tmp)
    return true
  catch
    return false
  finally
    rm(tmp; force = true)
  end
end

function resolve_preview_url(candidate_url::AbstractString, fallback_url::AbstractString)
  for _ in 1:20
    url_available(candidate_url) && return candidate_url
    sleep(0.25)
  end
  for _ in 1:20
    url_available(fallback_url) && return fallback_url
    sleep(0.25)
  end
  return fallback_url
end

function tail_lines(path::AbstractString, n::Int = 30)
  isfile(path) || return String[]
  lines = readlines(path)
  start_idx = max(1, length(lines) - n + 1)
  return lines[start_idx:end]
end

function main()
  opts = parse_args(ARGS)
  get(opts, :help, false) && return usage()

  project_root = normpath(joinpath(@__DIR__, ".."))
  drafts_dir = joinpath(project_root, "drafts")
  notebooks_dir = joinpath(project_root, "notebooks")

  created_or_published_path = ""
  action = ""

  if !isnothing(opts.publish_ref)
    source, destination = publish_note(drafts_dir, notebooks_dir, opts.publish_ref, opts.subdir)
    action = "published"
    created_or_published_path = destination
    println("Published note:")
    println("  from: " * rel_or_abs(source, project_root))
    println("    to: " * rel_or_abs(destination, project_root))
  else
    base_dir = opts.draft_mode ? drafts_dir : notebooks_dir
    path = resolve_new_note_path(base_dir, opts.title, opts.subdir)
    if isfile(path)
      action = "opened-existing"
      created_or_published_path = path
      println("Note already exists: " * rel_or_abs(path, project_root))
    else
      path = create_note(base_dir, opts.title, opts.subdir)
      action = opts.draft_mode ? "created-draft" : "created-note"
      created_or_published_path = path
      println("Created: " * rel_or_abs(path, project_root))
    end
  end

  if opts.open_editor
    try
      used_editor = open_in_editor(created_or_published_path, opts.editor_name)
      println("Editor: " * used_editor)
    catch err
      println("Editor open failed: " * sprint(showerror, err))
    end
  end

  notes_url = "http://localhost:$(opts.port)$(DEFAULT_PREVIEW_PATH)"
  preview_candidate =
    startswith(relpath(created_or_published_path, project_root), "notebooks") ?
    note_url_for(created_or_published_path, project_root, opts.port) :
    notes_url

  server = ensure_dev_server(project_root, opts.port)
  if !server.running
    println(server.started ? "Dev server: failed to start" : "Dev server: not running")
    println("See log: " * rel_or_abs(server.log_path, project_root))
    for line in tail_lines(server.log_path, 25)
      println("  " * line)
    end
    return action
  end

  preview_url = resolve_preview_url(preview_candidate, notes_url)
  println(server.started ? "Dev server: started" : "Dev server: already running")
  println("Preview: " * preview_url)

  if opts.open_browser
    opened = open_in_browser(preview_url)
    println(opened ? "Browser: opened" : "Browser: open failed")
  end

  return action
end

try
  main()
catch err
  println("Error: " * sprint(showerror, err))
  usage()
  exit(1)
end
