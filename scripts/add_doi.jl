using Downloads

function usage()
  println("Usage: julia --project=. scripts/add_doi.jl <doi>")
end

length(ARGS) == 1 || (usage(); exit(1))

doi = strip(ARGS[1])
isempty(doi) && (usage(); exit(1))

bib_path = joinpath(@__DIR__, "..", "references.local.bib")
existing = isfile(bib_path) ? read(bib_path, String) : ""

if occursin("doi = {" * doi * "}", existing) || occursin("doi={" * doi * "}", existing)
  println("DOI already exists in references.local.bib: " * doi)
  exit(0)
end

url = "https://doi.org/" * doi
response = Downloads.request(
  url;
  headers = [
    "Accept" => "application/x-bibtex; charset=utf-8",
    "User-Agent" => "Franklin bibliography helper",
  ],
)

response.status == 200 || error("Failed to fetch BibTeX for DOI $(doi) (status $(response.status))")

bibtex = strip(String(response.body))
isempty(bibtex) && error("Received empty BibTeX payload for DOI $(doi)")

open(bib_path, "a") do io
  if !isempty(existing) && !endswith(existing, "\n")
    write(io, "\n")
  end
  write(io, "\n")
  write(io, bibtex)
  write(io, "\n")
end

println("Added BibTeX entry for DOI: " * doi)
