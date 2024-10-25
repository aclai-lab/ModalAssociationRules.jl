using ModalAssociationRules
using Documenter

DocMeta.setdocmeta!(ModalAssociationRules, :DocTestSetup, :(using ModalAssociationRules); recursive = true)

makedocs(;
    modules = [ModalAssociationRules],
    authors = "Mauro Milella, Giovanni Pagliarini, Edoardo Ponsanesi",
    repo=Documenter.Remotes.GitHub("aclai-lab", "ModalAssociationRules.jl"),
    sitename = "ModalAssociationRules.jl",
    format = Documenter.HTML(;
        size_threshold = 4000000,
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://aclai-lab.github.io/ModalAssociationRules.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Getting started" => "getting-started.md",
        "Mining with modal logic" => "modal-generalization.md",
        "Available algorithms" => "algorithms.md",
        "Built-in data structures" => "data-structures.md",
        "Utilities" => "utilities.md",
        "Hands on" => "hands-on.md",
    ],
    # NOTE: warning
    warnonly = :true,
)

@info "`makedocs` has finished running. "

deploydocs(;
    repo = "github.com/aclai-lab/ModalAssociationRules.jl",
    devbranch = "dev",
    target = "build",
    branch = "gh-pages",
    versions = ["main" => "main", "stable" => "v^", "v#.#", "dev" => "dev"],
)
