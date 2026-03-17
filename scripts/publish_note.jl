include("note_tools.jl")

function usage()
  println("Usage: julia --project=. scripts/publish_note.jl draft_path_or_name [subdir]")
end

length(ARGS) >= 1 || (usage(); exit(1))

ref = strip(ARGS[1])
isempty(ref) && (usage(); exit(1))
subdir = length(ARGS) >= 2 ? ARGS[2] : ""

project_root = normpath(joinpath(@__DIR__, ".."))
source, destination = publish_note(
  joinpath(project_root, "drafts"),
  joinpath(project_root, "notebooks"),
  ref,
  subdir,
)

println("Published note:")
println("  from: " * relpath(source, project_root))
println("    to: " * relpath(destination, project_root))
