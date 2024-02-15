using SoleRules
using Documenter

DocMeta.setdocmeta!(SoleRules, :DocTestSetup, :(using SoleRules); recursive = true)

makedocs(;
    modules = [SoleRules],
    authors = ["Mauro Milella", "Giovanni Pagliarini", "Edoardo Ponsanesi"]
    repo=Documenter.Remotes.GitHub("aclai-lab", "SoleRules.jl"),
    sitename = "SoleRules.jl",
    format = Documenter.HTML(;
        size_threshold = 4000000,
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://aclai-lab.github.io/SoleRules.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Getting started" => "getting-started.md",
    ],
    # NOTE: warning
    warnonly = :true,
)

@info "`makedocs` has finished running. "

deploydocs(;
    repo = "github.com/aclai-lab/SoleRules.jl",
    target = "build",
    branch = "gh-pages",
    versions = ["main" => "main", "stable" => "v^", "v#.#", "dev" => "dev"],
)
