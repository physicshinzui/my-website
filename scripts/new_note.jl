include("note_tools.jl")

function usage()
  println("Usage: julia --project=. scripts/new_note.jl \"Title\" [subdir]")
end

length(ARGS) >= 1 || (usage(); exit(1))

title = strip(ARGS[1])
isempty(title) && (usage(); exit(1))
subdir = length(ARGS) >= 2 ? ARGS[2] : ""

project_root = normpath(joinpath(@__DIR__, ".."))
path = create_note(joinpath(project_root, "notebooks"), title, subdir)

println("Created note: " * relpath(path, project_root))
