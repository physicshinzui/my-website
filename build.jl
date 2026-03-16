include("scripts/generate_note_tag_pages.jl")

using Franklin

optimize()

if isfile("CNAME")
  cp("CNAME", joinpath("__site", "CNAME"); force = true)
end
