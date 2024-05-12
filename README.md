# ModalAssociationRules.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/dev)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl)
[![codecov](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl/branch/main/graph/badge.svg?token=LT9IYIYNFI)](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl)

Association rules in Julia!

## Compilation

This package is currently dependent on unregistered Julia packages. To compile the project, it is necessary to use the `dev` command of Pkg.jl, Julia's official package manager, targetting specific branch of [Sole](https://github.com/aclai-lab/Sole.jl) ecosystem.

The following instructions assume `~/.julia/dev/` as the only working directory.

    git clone https://github.com/aclai-lab/SoleBase.jl.git
    git clone https://github.com/aclai-lab/MultiData.jl.git
    git clone https://github.com/aclai-lab/SoleLogics.jl.git
    git clone https://github.com/aclai-lab/SoleData.jl.git
    git clone https://github.com/aclai-lab/SoleModels.jl.git
    git clone https://github.com/aclai-lab/ModalAssociationRules.jl.git

And checkout everything on `dev` branch.
For each package, open the Julia REPL and install the dependencies by executing the following.

    SoleBase.jl ->              ]instantiate
    MultiData.jl ->             ]dev SoleBase.jl
    SoleLogics.jl ->            ]dev SoleBase.jl
    SoleData.jl ->              ]dev SoleBase.jl SoleLogics.jl
    SoleModels.jl ->            ]dev SoleBase.jl MultiData.jl SoleLogics.jl SoleData.jl
    ModalAssociationRules.jl -> ]dev SoleBase.jl MultiData.jl SoleLogics.jl SoleData.jl SoleModels.jl

When not specified (every time but in SoleBase.jl), also execute ```]instantiate```.