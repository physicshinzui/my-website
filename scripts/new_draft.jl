include("note_tools.jl")

function usage()
  println("Usage: julia --project=. scripts/new_draft.jl \"Title\" [subdir]")
end

length(ARGS) >= 1 || (usage(); exit(1))

title = strip(ARGS[1])
isempty(title) && (usage(); exit(1))
subdir = length(ARGS) >= 2 ? ARGS[2] : ""

project_root = normpath(joinpath(@__DIR__, ".."))
path = create_note(joinpath(project_root, "drafts"), title, subdir)

println("Created draft: " * relpath(path, project_root))
