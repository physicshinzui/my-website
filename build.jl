include("scripts/generate_note_tag_pages.jl")

using Franklin

generate_note_tag_pages(@__DIR__)
optimize()

if isfile("CNAME")
  cp("CNAME", joinpath("__site", "CNAME"); force = true)
end
